// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IMulticall {
  /// @notice Calls multiple functions on the current contract
  /// @param data List of calls
  /// @return results List of results
  function multicall(
    bytes[] calldata data
  ) external returns (bytes[] memory results);
}
