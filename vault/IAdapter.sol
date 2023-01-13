// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAdapter {
  function deposit(
    uint256 user,
    uint256 amount,
    uint256 value,
    bytes memory data
  ) external;

  function withdraw(
    uint256 user,
    uint256 amount,
    bytes memory data
  ) external;
}
