// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SlotLib} from "../lib/SlotLib.sol";

contract Storage is Ownable, Multicall {
  using StorageSlot for bytes32;
  using SlotLib for bytes32;

  constructor(address owner_) {
    transferOwnership(owner_);
  }

  function write(bytes32 id, address value) external onlyOwner {
    id.slot().getAddressSlot().value = value;
  }

  function write(bytes32 id, bool value) external onlyOwner {
    id.slot().getBooleanSlot().value = value;
  }

  function write(bytes32 id, bytes32 value) external onlyOwner {
    id.slot().getBytes32Slot().value = value;
  }

  function write(bytes32 id, uint256 value) external onlyOwner {
    id.slot().getUint256Slot().value = value;
  }

  function readAddress(bytes32 id) external view returns (address) {
    return id.slot().getAddressSlot().value;
  }

  function readBoolean(bytes32 id) external view returns (bool) {
    return id.slot().getBooleanSlot().value;
  }

  function readBytes32(bytes32 id) external view returns (bytes32) {
    return id.slot().getBytes32Slot().value;
  }

  function readUint256(bytes32 id) external view returns (uint256) {
    return id.slot().getUint256Slot().value;
  }
}
