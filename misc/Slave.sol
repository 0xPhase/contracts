// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {CallLib} from "../lib/CallLib.sol";

contract Slave is Ownable {
  // Constructor for the Slave contract
  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  /// @notice Does an external call
  /// @param target The target address
  /// @param data The calldata
  function doCall(
    address target,
    bytes memory data
  ) external payable onlyOwner {
    CallLib.callFunc(target, data, msg.value);
  }

  /// @notice Does an external call
  /// @param target The target address
  /// @param data The calldata
  /// @param value The call value
  function doCall(
    address target,
    bytes memory data,
    uint256 value
  ) external payable onlyOwner {
    CallLib.callFunc(target, data, value);
  }
}
