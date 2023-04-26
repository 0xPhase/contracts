// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IYield} from "../../yield/IYield.sol";
import {Offset} from "../IBalancer.sol";

interface IBalancerCalculations {
  /// @notice Returns the average apr for the asset
  /// @param asset The asset
  /// @return The average apr
  function assetAPR(IERC20 asset) external view returns (uint256);

  /// @notice Gets the time weighted average APR for the yield
  /// @param yieldSrc The yield source
  /// @return The time weighted average APR
  function twaa(IYield yieldSrc) external view returns (uint256);

  /// @notice Gets the offsets in yield balances
  /// @param asset The asset
  /// @return arr The offset array
  /// @return totalNegative The total negative offsets
  /// @return totalPositive The total positive offsets
  function offsets(
    IERC20 asset
  )
    external
    view
    returns (Offset[] memory arr, uint256 totalNegative, uint256 totalPositive);
}
