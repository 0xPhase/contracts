// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LiquidationInfo, UserInfo, IVaultLiquidation} from "../IVault.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {ILiquidator} from "../ILiquidator.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultLiquidationFacet is VaultBase, IVaultLiquidation {
  using SafeERC20 for IERC20;

  function liquidateUser(uint256 user)
    external
    // override
    freezeCheck
    updateDebt
  {
    LiquidationInfo memory info = liquidationInfo(user);

    require(!info.solvent, "VaultLiquidationFacet: User is solvent");

    _withdrawEverythingYield(user);

    if (info.rebate > 0) {
      _s.treasury.spend(
        VaultConstants.REBATE_CAUSE,
        address(_s.cash),
        info.rebate,
        msg.sender
      );
    }

    uint256 debtShares = ShareLib.calculateShares(
      info.borrowChange,
      _s.totalDebtShares,
      _s.collectiveDebt
    );

    _s.userInfo[user].deposit -= info.assetReward;
    _s.userInfo[user].debtShares -= debtShares;

    _s.totalDebtShares -= debtShares;
    _s.collectiveDebt -= info.borrowChange;

    _s.asset.safeTransfer(address(_s.treasury), info.protocolFee);
    _s.treasury.increaseUnsafe(
      VaultConstants.PROTOCOL_CAUSE,
      address(_s.asset),
      info.protocolFee
    );

    _s.asset.safeTransfer(msg.sender, info.assetReward - info.protocolFee);
    _checkLiquidator(msg.sender, user, info);
    _s.cash.burnManager(msg.sender, info.borrowChange);

    emit UserLiquidated(
      user,
      msg.sender,
      info.borrowChange,
      info.assetReward,
      info.protocolFee,
      info.rebate
    );
  }

  function liquidationInfo(uint256 user)
    public
    view
    returns (LiquidationInfo memory)
  // override
  {
    if (_isSolvent(user)) {
      return LiquidationInfo(true, 0, 0, 0, 0);
    }

    (uint256 borrowChange, uint256 collateralChange) = _liquidationAmount(user);

    if (borrowChange == 0 || collateralChange == 0) {
      return LiquidationInfo(true, 0, 0, 0, 0);
    }

    uint256 tPrice = _price();
    uint256 userDeposit = _deposit(user);
    uint256 collateralValue = _scaleFromAsset(userDeposit * tPrice) / 1 ether;
    uint256 cappedChange = MathLib.min(collateralValue, collateralChange);
    uint256 pureChange = _withoutFee(cappedChange);
    uint256 totalFee = cappedChange - pureChange;
    uint256 protocolFee = _scaleToAsset(
      (totalFee * _treasuryLiquidationFee()) / 1 ether
    );

    // Non important safeguard!
    uint256 realTokens = MathLib.min(
      userDeposit,
      _scaleToAsset((cappedChange * 1 ether) / (tPrice))
    );

    uint256 rebate = 0;

    if (pureChange > collateralValue) {
      rebate = MathLib.min(
        _s.treasury.tokenBalance(VaultConstants.REBATE_CAUSE, address(_s.cash)),
        pureChange - collateralValue
      );
    }

    return
      LiquidationInfo(false, borrowChange, realTokens, protocolFee, rebate);
  }

  function _checkLiquidator(
    address liquidator,
    uint256 to,
    LiquidationInfo memory info
  ) internal {
    bool result = true;

    try ILiquidator(liquidator).receiveLiquidation(to, info) returns (
      bytes4 retval
    ) {
      result = retval == ILiquidator.receiveLiquidation.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert("VaultLiquidationFacet: Not an ILiquidator contract :: ZL");
      } else {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }

    require(
      result,
      "VaultLiquidationFacet: Not an ILiquidator contract :: Result"
    );
  }

  function _liquidationAmount(uint256 user)
    internal
    view
    returns (uint256 debtChange, uint256 collateralChange)
  {
    UserInfo storage info = _s.userInfo[user];
    uint256 collateral = _scaleFromAsset(_deposit(user) * _price()) / 1 ether;
    uint256 debt = _debtValueUser(user);

    if (collateral == 0 || debt == 0) return (0, 0);

    uint256 feefullDebt = _withFee(debt);

    if (debt < _stepMinDeposit() || feefullDebt >= collateral) {
      return (debt, feefullDebt);
    }

    uint256 targetHealth = info.healthTarget;

    debtChange = ((1 ether *
      (debt *
        1 ether**uint256(2) -
        (collateral * targetHealth * _s.maxCollateralRatio))) /
      (1 ether**uint256(3) -
        (targetHealth * _s.maxCollateralRatio * 1 ether) -
        (_s.liquidationFee * targetHealth * _s.maxCollateralRatio)));

    collateralChange = _withFee(debtChange);

    // ((y*(debt_*y^(2)-collat_*health_*mcr_))/(y^(3)-health_*mcr_*y-fee_*health_*mcr_))
  }

  function _withFee(uint256 amount) internal view returns (uint256) {
    return amount + ((amount * _s.liquidationFee) / (1 ether));

    // w_=x_+((x_*fee_)/(y))
  }

  function _withoutFee(uint256 amount) internal view returns (uint256) {
    return ((amount * 1 ether) / (1 ether + _s.liquidationFee));

    // x_=((w_*y)/(y+fee_))
  }

  function _treasuryLiquidationFee() internal view returns (uint256) {
    return
      MathLib.min(
        _s.varStorage.readUint256(VaultConstants.LIQUIDATION_FEE),
        0.5 ether
      );
  }
}
