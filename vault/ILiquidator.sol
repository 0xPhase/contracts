// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IVault} from "./IVault.sol";

interface ILiquidator {
  function receiveLiquidation(
    uint256 toLiquidate,
    IVault.LiquidationInfo memory liquidationInfo
  ) external returns (bytes4);
}
