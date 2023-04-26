// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerAccounting {
  /// @notice Deposits tokens for user
  /// @param asset The asset
  /// @param user The user id
  /// @param amount The amount of tokens deposited
  function deposit(IERC20 asset, uint256 user, uint256 amount) external;

  /// @notice Withdraws tokens from user
  /// @param asset The asset
  /// @param user The user id
  /// @param amount The amount of tokens withdrawn
  /// @return The real amount of tokens withdrawn
  function withdraw(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) external returns (uint256);

  /// @notice Fully withdraws tokens from user
  /// @param asset The asset
  /// @param user The user id
  /// @return The real amount of tokens withdrawn
  function fullWithdraw(IERC20 asset, uint256 user) external returns (uint256);
}
