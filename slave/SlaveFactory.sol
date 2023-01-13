// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Slave} from "./Slave.sol";

contract SlaveFactory {
  mapping(address => uint256) public counter;

  function create() external returns (address) {
    Slave slave = new Slave{salt: bytes32(counter[msg.sender])}(msg.sender);
    counter[msg.sender]++;
    return address(slave);
  }
}
