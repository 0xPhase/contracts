// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultAccounting, UserInfo, VaultStorage} from "../IVault.sol";
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
    bytes calldata extraData
  ) public payable {
    addCollateral(msg.sender, amount, extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    address user,
    uint256 amount,
    bytes calldata extraData
  ) public payable {
    addCollateral(_s().creditAccount.getAccount(user), amount, extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes calldata extraData
  ) public payable override updateUser(user) freezeCheck(true) updateDebt {
    require(user > 0, "VaultAccountingFacet: Non existent user");
    require(amount > 0, "VaultAccountingFacet: Cannot add 0 collateral");

    VaultStorage storage s = _s();

    if (s.adapter != address(0)) {
      CallLib.delegateCallFunc(
        s.adapter,
        abi.encodeWithSelector(
          IAdapter.deposit.selector,
          user,
          amount,
          extraData
        )
      );
    } else {
      require(msg.value == 0, "VaultAccountingFacet: Message value not 0");

      s.asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    s.userInfo[user].deposit += amount;

    emit CollateralAdded(user, amount);

    _rebalanceYield(user);
  }

  /// @inheritdoc	IVaultAccounting
  function removeCollateral(
    uint256 amount,
    bytes calldata extraData
  ) public override updateMessageUser freezeCheck(true) updateDebt {
    VaultStorage storage s = _s();
    uint256 user = s.creditAccount.getAccount(msg.sender);

    UserInfo storage info = s.userInfo[user];
    uint256 total = _deposit(user);

    require(
      total >= amount,
      "VaultAccountingFacet: Removing too much collateral"
    );

    if (info.deposit >= amount) {
      unchecked {
        info.deposit -= amount;
      }
    } else {
      unchecked {
        amount =
          info.deposit +
          s.balancer.withdraw(s.asset, user, amount - info.deposit);
      }

      info.deposit = 0;
    }

    require(_isSolvent(user), "VaultAccountingFacet: User no longer solvent");

    emit CollateralRemoved(user, amount);

    _rebalanceYield(user);

    if (s.adapter != address(0)) {
      CallLib.delegateCallFunc(
        s.adapter,
        abi.encodeWithSelector(
          IAdapter.withdraw.selector,
          user,
          amount,
          extraData
        )
      );
    } else {
      s.asset.safeTransfer(msg.sender, amount);
    }
  }

  /// @inheritdoc	IVaultAccounting
  function removeAllCollateral(bytes calldata extraData) public override {
    uint256 user = _s().creditAccount.getAccount(msg.sender);

    removeCollateral(_deposit(user), extraData);
  }

  /// @inheritdoc	IVaultAccounting
  function mintUSD(
    uint256 amount
  ) public override updateMessageUser freezeCheck(false) updateDebt {
    VaultStorage storage s = _s();
    uint256 user = s.creditAccount.getAccount(msg.sender);

    require(amount > 0, "VaultAccountingFacet: Cannot mint 0 CASH");

    uint256 value = _depositValueUser(user);
    uint256 debt = _debtValueUser(user);
    uint256 fee = (amount * s.borrowFee) / 1 ether;
    uint256 borrow = amount - fee;

    require(
      debt + amount >= _stepMinDeposit(),
      "VaultAccountingFacet: Has to borrow more than minimum"
    );

    require(
      s.maxMint >= s.collectiveDebt + amount,
      "VaultAccountingFacet: Minting over maximum mint"
    );

    require(
      value >= debt + amount,
      "VaultAccountingFacet: Not enough collateral to mint"
    );

    _mintFees(fee);

    uint256 shares = ShareLib.calculateShares(
      amount,
      s.totalDebtShares,
      s.collectiveDebt
    );

    s.collectiveDebt += amount;
    s.debtShares[user] += shares;
    s.totalDebtShares += shares;

    s.cash.mintManager(msg.sender, borrow);

    emit USDMinted(user, amount, fee);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(uint256 amount) public override {
    repayUSD(msg.sender, amount);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(address user, uint256 amount) public override {
    repayUSD(_s().creditAccount.getAccount(user), amount);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(
    uint256 user,
    uint256 amount
  ) public override updateUser(user) freezeCheck(true) updateDebt {
    require(amount > 0, "VaultAccountingFacet: Cannot repay 0 amount");

    VaultStorage storage s = _s();
    uint256 userShares = s.debtShares[user];

    uint256 shares = MathLib.min(
      userShares,
      ShareLib.calculateShares(amount, s.totalDebtShares, s.collectiveDebt)
    );

    require(shares > 0, "VaultAccountingFacet: Cannot repay 0 shares");

    // solhint-disable-next-line reason-string
    require(
      _debtValue(userShares - shares) >= _stepMinDeposit() ||
        (userShares - shares) == 0,
      "VaultAccountingFacet: Has to repay to zero or have more debt than minimum"
    );

    uint256 toRepay = _debtValue(shares);

    s.cash.burnManager(msg.sender, toRepay);

    s.collectiveDebt -= toRepay;
    s.debtShares[user] -= shares;
    s.totalDebtShares -= shares;

    emit USDRepaid(user, shares, toRepay);
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD() public override {
    repayAllUSD(msg.sender);
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD(address user) public override {
    repayAllUSD(_s().creditAccount.getAccount(user));
  }

  /// @inheritdoc	IVaultAccounting
  function repayAllUSD(uint256 user) public override {
    repayUSD(user, _debtValueUser(user) * 2);
  }
}
