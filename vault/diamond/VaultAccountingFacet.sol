// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ShareLib} from "../../lib/ShareLib.sol";
import {IVaultAccounting} from "../IVault.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultAccountingFacet is VaultBase, IVaultAccounting {
  using SafeERC20 for IERC20;

  function addCollateral(uint256 user, uint256 amount)
    external
    override
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(amount > 0, "VaultAccountingFacet: Cannot add 0 collateral");

    _s.asset.safeTransferFrom(msg.sender, address(this), amount);
    _s.userInfo[user].deposit += amount;

    emit CollateralAdded(user, amount);
  }

  function removeCollateral(uint256 user, uint256 amount)
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(
      _s.userInfo[user].deposit >= amount,
      "VaultAccountingFacet: Removing too much collateral"
    );

    _s.userInfo[user].deposit -= amount;
    _s.asset.safeTransfer(msg.sender, amount);

    require(_isSolvent(user), "VaultAccountingFacet: User no longer solvent");

    emit CollateralRemoved(user, amount);
  }

  function mintUSD(uint256 user, uint256 amount)
    public
    // override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    _s.contextLocked = false;
    mintUSD(user, amount, false);
  }

  function mintUSD(
    uint256 user,
    uint256 amount,
    bool useMax
  )
    public
    // override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(amount > 0, "VaultAccountingFacet: Cannot mint 0 CASH");

    uint256 value = _depositValueUser(user);
    uint256 debt = _debtValueUser(user);
    uint256 fee = (amount * _s.borrowFee) / 1 ether;
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
          ((value - debt) * 1 ether) / (1 ether + _s.borrowFee),
          false
        );
      } else {
        revert("VaultAccountingFacet: Minting too much");
      }
    }

    _mintFees(fee);

    uint256 shares = _s.totalDebtShares == 0
      ? borrow
      : ShareLib.calculateShares(borrow, _s.totalDebtShares, _s.collectiveDebt);

    _s.collectiveDebt += borrow;
    _s.userInfo[user].debtShares += shares;
    _s.totalDebtShares += shares;

    _s.cash.mintManager(msg.sender, amount);

    emit USDMinted(user, amount, fee);
  }

  function repayUSD(uint256 user, uint256 shares)
    public
    // override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    _s.contextLocked = false;
    repayUSD(user, shares, false);
  }

  function repayUSD(
    uint256 user,
    uint256 shares,
    bool useMax
  )
    public
    // override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(shares > 0, "VaultAccountingFacet: Cannot repay 0 shares");

    uint256 userShares = _s.userInfo[user].debtShares;

    require(
      userShares >= shares,
      "VaultAccountingFacet: Repaying too many shares"
    );

    uint256 toRepay = _debtValue(shares);
    uint256 userBalance = IERC20(address(_s.cash)).balanceOf(msg.sender);

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
    _s.userInfo[user].debtShares -= shares;
    _s.totalDebtShares -= shares;

    _s.cash.burnManager(msg.sender, toRepay);

    emit USDRepaid(user, shares, toRepay);
  }
}
