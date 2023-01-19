// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultAccounting, UserInfo} from "../IVault.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {CallLib} from "../../lib/CallLib.sol";
import {ICash} from "../../core/ICash.sol";
import {VaultBase} from "./VaultBase.sol";
import {IAdapter} from "../IAdapter.sol";

contract VaultAccountingFacet is VaultBase, IVaultAccounting {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IVaultAccounting
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) external payable override updateUser(user) freezeCheck updateDebt {
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
  }

  /// @inheritdoc	IVaultAccounting
  function removeCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    UserInfo storage userInfo = _s.userInfo[user];

    require(
      userInfo.deposit >= amount,
      "VaultAccountingFacet: Removing too much collateral"
    );

    userInfo.deposit -= amount;

    require(_isSolvent(user), "VaultAccountingFacet: User no longer solvent");

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

    emit CollateralRemoved(user, amount);
  }

  /// @inheritdoc	IVaultAccounting
  function mintUSD(
    uint256 user,
    uint256 amount
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    _s.contextLocked = false;
    mintUSD(user, amount, false);
  }

  /// @inheritdoc	IVaultAccounting
  function mintUSD(
    uint256 user,
    uint256 amount,
    bool useMax
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(amount > 0, "VaultAccountingFacet: Cannot mint 0 CASH");

    uint256 value = _depositValueUser(user);
    uint256 debt = _debtValueUser(user);
    uint256 borrowFee = _s.borrowFee;
    uint256 fee = (amount * borrowFee) / 1 ether;
    uint256 borrow = amount + fee;

    require(
      debt + borrow >= _stepMinDeposit(),
      "VaultAccountingFacet: Has to borrow more than minimum"
    );

    if (value < debt + borrow) {
      if (useMax && value > debt) {
        _s.contextLocked = false;

        mintUSD(
          user,
          ((value - debt) * 1 ether) / (1 ether + borrowFee),
          false
        );
      } else {
        revert("VaultAccountingFacet: Minting too much");
      }
    }

    _mintFees(fee);

    uint256 totalDebtShares = _s.totalDebtShares;

    uint256 shares = totalDebtShares == 0
      ? borrow
      : ShareLib.calculateShares(borrow, totalDebtShares, _s.collectiveDebt);

    _s.collectiveDebt += borrow;
    _s.userInfo[user].debtShares += shares;
    _s.totalDebtShares += shares;

    _s.cash.mintManager(msg.sender, amount);

    emit USDMinted(user, amount, fee);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(
    uint256 user,
    uint256 shares
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    _s.contextLocked = false;
    repayUSD(user, shares, false);
  }

  /// @inheritdoc	IVaultAccounting
  function repayUSD(
    uint256 user,
    uint256 shares,
    bool useMax
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(shares > 0, "VaultAccountingFacet: Cannot repay 0 shares");

    UserInfo storage userInfo = _s.userInfo[user];
    uint256 userShares = userInfo.debtShares;

    require(
      userShares >= shares,
      "VaultAccountingFacet: Repaying too many shares"
    );

    ICash cash = _s.cash;
    uint256 toRepay = _debtValue(shares);
    uint256 userBalance = IERC20(address(cash)).balanceOf(msg.sender);

    // solhint-disable-next-line reason-string
    require(
      _debtValue(userShares - shares) >= _stepMinDeposit(),
      "VaultAccountingFacet: Has to repay to zero or have more debt than minimum"
    );

    if (toRepay > userBalance) {
      if (useMax) {
        _s.contextLocked = false;

        repayUSD(
          user,
          ShareLib.calculateShares(
            userBalance,
            _s.totalDebtShares,
            _s.collectiveDebt
          ) - 1,
          false
        );

        return;
      } else {
        revert("VaultAccountingFacet: Not enough balance");
      }
    }

    _s.collectiveDebt -= toRepay;
    userInfo.debtShares -= shares;
    _s.totalDebtShares -= shares;

    cash.burnManager(msg.sender, toRepay);

    emit USDRepaid(user, shares, toRepay);
  }
}
