// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

contract ValueOnConstructor {
  uint256 public value;

  constructor(uint256 value_) {
    value = value_;
  }
}
