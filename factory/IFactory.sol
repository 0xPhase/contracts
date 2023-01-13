// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFactory {
  event ContractCreated(address indexed creator, address created);

  function create(bytes memory constructorData)
    external
    returns (address created);
}
