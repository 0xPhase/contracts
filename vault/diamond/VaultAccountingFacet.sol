// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultAccounting, UserInfo} from "../IVault.sol";
import {IPegToken} from "../../peg/IPegToken.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {CallLib} from "../../lib/CallLib.sol";
import {VaultBase} from "./VaultBase.sol";
import {IAdapter} from "../IAdapter.sol";

contract VaultAccountingFacet is VaultBase, IVaultAccounting {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    uint256 amount,
    bytes memory extraData
  ) public payable {
    addCollateral(msg.sender, amount, extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    address user,
    uint256 amount,
    bytes memory extraData
  ) public payable {
    addCollateral(_s.creditAccount.getAccount(user), amount, extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) public payable override updateUser(user) freezeCheck(true) updateDebt {
    require(user > 0, "VaultAccountingFacet: Non existent user");
    require(amount > 0, "VaultAccountingFacet: Cannot add 0 collateral");

    if (_s.adapter != address(0)) {
      CallLib.delegateCallFunc(
        _s.adapter,
        abi.encodeWithSelector(
          IAdapter.deposit.selector,
          user,
          amount,
          msg.value,
          extraData
        )
      );
    } else {
      require(msg.value == 0, "VaultAccountingFacet: Message value not 0");

      _s.asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    _s.userInfo[user].deposit += amount;

    emit CollateralAdded(user, amount);

    _rebalanceYield(user);
  }

  /// @inheritdoc	IVaultAccounting
  function removeCollateral(
    uint256 amount,
    bytes memory extraData
  ) public override updateMessageUser freezeCheck(false) updateDebt {
    uint256 user = _s.creditAccount.getAccount(msg.sender);

    UserInfo storage info = _s.userInfo[user];
    uint256 total = _deposit(user);

    require(
      total >= amount,
      "VaultAccountingFacet: Removing too much collateral"
    );

    if (info.deposit >= amount) {
      info.deposit -= amount;
    } else {
      _s.balancer.withdraw(_s.asset, user, amount - info.deposit);
      info.deposit = 0;
    }

    require(_isSolvent(user), "VaultAccountingFacet: User no longer solvent");

    emit CollateralRemoved(user, amount);

    _rebalanceYield(user);

    if (_s.adapter != address(0)) {
      CallLib.delegateCallFunc(
        _s.adapter,
        abi.encodeWithSelector(
          IAdapter.withdraw.selector,
          user,
          amount,
          extraData
        )
      );
    } else {
      _s.asset.safeTransfer(msg.sender, amount);
    }
  }

  /// @inheritdoc	IVaultAccounting
  function removeAllCollateral(bytes memory extraData) public override {
    uint256 user = _s.creditAccount.getAccount(msg.sender);

    removeCollateral(_deposit(user), extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function mintUSD(
    uint256 amount
  ) public override updateMessageUser freezeCheck(false) updateDebt {
    uint256 user = _s.creditAccount.getAccount(msg.sender);

    require(amount > 0, "VaultAccountingFacet: Cannot mint 0 CASH");

    uint256 value = _depositValueUser(user);
    uint256 debt = _debtValueUser(user);
    uint256 fee = amount - ((amount * 1 ether) / (1 ether + _s.borrowFee));
    uint256 borrow = amount - fee;

    require(
      debt + amount >= _stepMinDeposit(),
      "VaultAccountingFacet: Has to borrow more than minimum"
    );

    require(
      _s.maxMint >= _s.collectiveDebt + amount,
      "VaultAccountingFacet: Minting over maximum mint"
    );

    require(
      value >= debt + amount,
      "VaultAccountingFacet: Not enough collateral to mint"
    );

    _mintFees(fee);

    uint256 shares = ShareLib.calculateShares(
      amount,
      _s.totalDebtShares,
      _s.collectiveDebt
    );

    _s.collectiveDebt += amount;
    _s.debtShares[user] += shares;
    _s.totalDebtShares += shares;

    _s.cash.mintManager(msg.sender, borrow);

    emit USDMinted(user, amount, fee);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(uint256 amount) public override {
    repayUSD(msg.sender, amount);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(address user, uint256 amount) public override {
    repayUSD(_s.creditAccount.getAccount(user), amount);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(
    uint256 user,
    uint256 amount
  ) public override updateUser(user) freezeCheck(true) updateDebt {
    require(amount > 0, "VaultAccountingFacet: Cannot repay 0 amount");

    uint256 userShares = _s.debtShares[user];

    uint256 shares = MathLib.min(
      userShares,
      ShareLib.calculateShares(amount, _s.totalDebtShares, _s.collectiveDebt)
    );

    require(shares > 0, "VaultAccountingFacet: Cannot repay 0 shares");

    // solhint-disable-next-line reason-string
    require(
      _debtValue(userShares - shares) >= _stepMinDeposit() ||
        (userShares - shares) == 0,
      "VaultAccountingFacet: Has to repay to zero or have more debt than minimum"
    );

    uint256 toRepay = _debtValue(shares);

    _s.cash.burnManager(msg.sender, toRepay);

    _s.collectiveDebt -= toRepay;
    _s.debtShares[user] -= shares;
    _s.totalDebtShares -= shares;

    emit USDRepaid(user, shares, toRepay);
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD() public override {
    repayAllUSD(msg.sender);
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD(address user) public override {
    repayAllUSD(_s.creditAccount.getAccount(user));
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD(uint256 user) public override {
    repayUSD(user, _debtValueUser(user) * 2);
  }
}
