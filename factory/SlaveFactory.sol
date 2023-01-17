// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IFactory} from "./IFactory.sol";
import {Slave} from "../misc/Slave.sol";

contract SlaveFactory is IFactory {
  mapping(address => uint256) public counter;

  /// @inheritdoc	IFactory
  function create(bytes memory) external override returns (address created) {
    created = address(
      new Slave{salt: bytes32(counter[msg.sender])}(msg.sender)
    );

    counter[msg.sender]++;

    emit ContractCreated(msg.sender, created);
  }
}
