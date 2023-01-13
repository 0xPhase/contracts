// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LiquidationInfo} from "./IVault.sol";

interface ILiquidator {
  /// @notice test
  /// @param toLiquidate param1
  /// @param liquidationInfo param2
  /// @return ret1
  function receiveLiquidation(
    uint256 toLiquidate,
    LiquidationInfo memory liquidationInfo
  ) external returns (bytes4);
}
