// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWETH {
  /// @notice Deposits ETH ang gives WETH in return
  function deposit() external payable;

  /// @notice Burns WETH for ETH in return
  /// @param wad The amount of WETH to burn
  function withdraw(uint256 wad) external;
}
