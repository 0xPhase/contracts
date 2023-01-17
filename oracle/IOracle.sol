// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {
  /// @notice Returns the price of the asset in dollars in 18 decimals
  /// @param asset The asset address
  /// @return price The dollar price in 18 decimals
  function getPrice(address asset) external view returns (uint256 price);
}
