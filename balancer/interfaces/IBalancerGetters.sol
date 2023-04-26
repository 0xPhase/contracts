// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {Yield} from "../IBalancer.sol";

interface IBalancerGetters {
  /// @notice Returns the total balance of the asset in the balancer
  /// @param asset The asset
  /// @return The total balance of the asset
  function totalBalance(IERC20 asset) external view returns (uint256);

  /// @notice Returns the balance of the asset for the user
  /// @param asset The asset
  /// @param user The user id
  /// @return The balance of the asset
  function balanceOf(
    IERC20 asset,
    uint256 user
  ) external view returns (uint256);

  /// @notice Returns the yield sources for the asset
  /// @param asset The asset
  /// @return The yield sources
  function yields(IERC20 asset) external view returns (Yield[] memory);

  /// @notice Returns all of the yield sources
  /// @return All of the yield sources
  function allYields() external view returns (address[] memory);

  /// @notice Returns the treasury
  /// @return The treasury
  function treasury() external view returns (ITreasury);

  /// @notice Returns the performance fee
  /// @return The performance fee
  function performanceFee() external view returns (uint256);

  /// @notice Returns the fee target account
  /// @return The fee target account
  function feeAccount() external view returns (uint256);
}
