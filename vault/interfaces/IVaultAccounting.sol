// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IVaultAccounting {
  /// @notice Adds collateral for the user
  /// @param amount The amount to add
  /// @param extraData The extra adapter data
  function addCollateral(
    uint256 amount,
    bytes calldata extraData
  ) external payable;

  /// @notice Adds collateral for the user
  /// @param user The user address
  /// @param amount The amount to add
  /// @param extraData The extra adapter data
  function addCollateral(
    address user,
    uint256 amount,
    bytes calldata extraData
  ) external payable;

  /// @notice Gives collateral for the user
  /// @param user The user id
  /// @param amount The amount to add
  /// @param extraData The extra adapter data
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes calldata extraData
  ) external payable;

  /// @notice Removes collateral from the user
  /// @param amount The amount to remove
  /// @param extraData The extra adapter data
  function removeCollateral(uint256 amount, bytes calldata extraData) external;

  /// @notice Removes all collateral from the user
  /// @param extraData The extra adapter data
  function removeAllCollateral(bytes calldata extraData) external;

  /// @notice Mints for the user
  /// @param amount The amount to mint
  function mintUSD(uint256 amount) external;

  /// @notice Repays for the user
  /// @param amount The amount to repay
  function repayUSD(uint256 amount) external;

  /// @notice Repays for the user
  /// @param user The user address
  /// @param amount The amount to repay
  function repayUSD(address user, uint256 amount) external;

  /// @notice Repays for the user
  /// @param user The user id
  /// @param amount The amount to repay
  function repayUSD(uint256 user, uint256 amount) external;

  /// @notice Repays all for the user
  function repayAllUSD() external;

  /// @notice Repays all for the user
  /// @param user The user address
  function repayAllUSD(address user) external;

  /// @notice Repays all for the user
  /// @param user The user id
  function repayAllUSD(uint256 user) external;
}
