// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IYield} from "../../yield/IYield.sol";

interface IBalancerSetters {
  /// @notice Adds a new yield
  /// @param yieldSrc The yield source
  function addYield(IYield yieldSrc) external;

  /// @notice Sets yield state
  /// @param yieldSrc The yield source
  function setYieldState(IYield yieldSrc, bool state) external;

  /// @notice Sets the performance fee
  /// @param newPerformanceFee The new performance fee
  function setPerformanceFee(uint256 newPerformanceFee) external;
}
