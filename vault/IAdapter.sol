// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IAdapter {
  /// @notice Ran when the user deposits into a vault with the adapter
  /// @param user The user id
  /// @param amount The deposit amount
  /// @param data The extra adapter data
  function deposit(
    uint256 user,
    uint256 amount,
    bytes memory data
  ) external payable;

  /// @notice Ran when the user withdraws from a vault with the adapter
  /// @param user The user id
  /// @param amount The withdraw amount
  /// @param data The extra adapter data
  function withdraw(uint256 user, uint256 amount, bytes memory data) external;
}
