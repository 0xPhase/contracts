// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
  /// @notice Event emitted when tokens are deposited
  /// @param amount The amount of tokens deposited
  event Deposit(uint256 amount);

  /// @notice Event emitted when tokens are withdrawn
  /// @param amount The amount of tokens withdrawn
  event Withdraw(uint256 amount);

  /// @notice Receive deposit
  /// @param amount The amount of tokens deposited
  function deposit(uint256 amount) external;

  /// @notice Receive withdraw
  /// @param amount The amount of tokens withdrawn
  /// @return The real amount of tokens withdrawn
  function withdraw(uint256 amount) external returns (uint256);

  /// @notice Receive full withdraw
  /// @return The amount of tokens withdrawn
  function fullWithdraw() external returns (uint256);

  /// @notice Returns the asset token
  /// @return The asset token
  function asset() external view returns (IERC20);

  /// @notice Returns the total token balance of the Yield instance
  /// @return The total token balance
  function totalBalance() external view returns (uint256);
}
