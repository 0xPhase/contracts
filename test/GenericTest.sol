// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ValueOnConstructor {
  uint256 public value;

  constructor(uint256 value_) {
    value = value_;
  }
}
