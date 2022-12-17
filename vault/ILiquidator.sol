// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {LiquidationInfo} from "./IVault.sol";

interface ILiquidator {
  function receiveLiquidation(
    uint256 toLiquidate,
    LiquidationInfo memory liquidationInfo
  ) external returns (bytes4);
}
