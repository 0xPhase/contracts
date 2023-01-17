// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OwnableStorage {
  address owner;
}

interface IOwnable {
  /// @notice Renounces the ownership but setting owner as address(0)
  function renounceOwnership() external;

  /// @notice Transfers ownership to new owner
  /// @param newOwner The address of the new owner
  function transferOwnership(address newOwner) external;

  /// @notice Returns the current owner
  /// @return The current owner
  function owner() external view returns (address);
}
