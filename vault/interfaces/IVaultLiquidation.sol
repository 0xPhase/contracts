// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {LiquidationInfo} from "../IVault.sol";

interface IVaultLiquidation {
  /// @notice Liquidates a user based on liquidationInfo(user)
  /// @param user The user id
  function liquidateUser(uint256 user) external;

  /// @notice Returns liquidation info about the user
  /// @param user The user id
  /// @return The liquidation info
  function liquidationInfo(
    uint256 user
  ) external view returns (LiquidationInfo memory);
}
