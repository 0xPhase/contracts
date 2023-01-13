// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {CallLib} from "../lib/CallLib.sol";

contract Slave is Ownable {
  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  function doCall(address target, bytes memory data)
    external
    payable
    onlyOwner
  {
    CallLib.callFunc(target, data, msg.value);
  }
}
