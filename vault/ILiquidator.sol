// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {LiquidationInfo} from "./IVault.sol";

interface ILiquidator {
  /// @notice Ran after vault transferred collateral to the liquidator and requires the liquidator to have enough CASH to burn for the debt
  /// @param toLiquidate The user id to liquidate
  /// @param liquidationInfo The liquidation info
  /// @return The selector of the receiveLiquidation function
  function receiveLiquidation(
    uint256 toLiquidate,
    LiquidationInfo memory liquidationInfo
  ) external returns (bytes4);
}
