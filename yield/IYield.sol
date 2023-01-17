// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
  /// @notice Event emitted when tokens are deposited for the user
  /// @param user The user id
  /// @param amount The amount of tokens deposited
  /// @param shares The amount of shares given in returns
  event Deposit(uint256 indexed user, uint256 amount, uint256 shares);

  /// @notice Event emitted when tokens are withdrawn by the user
  /// @param user The user id
  /// @param amount The amount of tokens withdrawn
  /// @param shares The amount of shares removed
  event Withdraw(uint256 indexed user, uint256 amount, uint256 shares);

  /// @notice Receive deposit for the user
  /// @param user The user id
  /// @param amount The amount of tokens deposited
  function receiveDeposit(uint256 user, uint256 amount) external;

  /// @notice Receive withdraw from the user
  /// @param user The user id
  /// @param amount The amount of tokens withdrawn
  /// @return The real amount of tokens withdrawn
  function receiveWithdraw(
    uint256 user,
    uint256 amount
  ) external returns (uint256);

  /// @notice Receive full withdraw from the user
  /// @param user The user id
  /// @return The amount of tokens withdrawn
  function receiveFullWithdraw(uint256 user) external returns (uint256);

  /// @notice Returns the asset token address
  /// @return The asset token address
  function asset() external view returns (IERC20);

  /// @notice Returns the total token balance of the Yield instance
  /// @return The total token balance
  function totalBalance() external view returns (uint256);

  /// @notice Returns the total token balance of the user
  /// @param user The user id
  /// @return The total token balance
  function balance(uint256 user) external view returns (uint256);

  /// @notice Returns the amount of shares for the user
  /// @param user The user id
  /// @return The amount of shares
  function shares(uint256 user) external view returns (uint256);
}
