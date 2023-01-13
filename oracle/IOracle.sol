// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {
  function getPrice(address asset) external view returns (uint256 price);
}
