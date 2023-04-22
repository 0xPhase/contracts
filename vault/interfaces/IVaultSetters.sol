// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IVaultSetters {
  /// @notice Sets the health target for a liquidation for the user
  /// @param healthTarget The health target
  function setHealthTarget(uint256 healthTarget) external;

  /// @notice Sets the yield percent for the user
  /// @param yieldPercent The yield percent
  function setYieldPercent(uint256 yieldPercent) external;
}
