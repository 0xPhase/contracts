// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct ClockStorage {
  uint256 lastTime;
}

interface IClock {
  /// @notice Gets the time without updating it
  /// @return The current time
  function time() external view returns (uint256);

  /// @notice Gets the last updated time
  /// @return The last updated time
  function lastTime() external view returns (uint256);
}
