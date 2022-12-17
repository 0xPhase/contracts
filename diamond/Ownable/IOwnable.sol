// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct OwnableStorage {
  address owner;
}

interface IOwnable {
  function renounceOwnership() external;

  function transferOwnership(address newOwner) external;

  function owner() external view returns (address);
}
