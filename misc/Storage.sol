// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SlotLib} from "../lib/SlotLib.sol";

contract Storage is Ownable, Multicall {
  using StorageSlot for bytes32;
  using SlotLib for bytes32;

  // @notice The constructor for the Storage contract
  // @param owner_ The owner address
  constructor(address owner_) {
    transferOwnership(owner_);
  }

  /// @notice Writes an address value into storage
  /// @param id The storage slot
  /// @param value The address value
  /// @custom:protected onlyOwner
  function write(bytes32 id, address value) external onlyOwner {
    id.slot().getAddressSlot().value = value;
  }

  /// @notice Writes a boolean value into storage
  /// @param id The storage slot
  /// @param value The boolean value
  /// @custom:protected onlyOwner
  function write(bytes32 id, bool value) external onlyOwner {
    id.slot().getBooleanSlot().value = value;
  }

  /// @notice Writes a bytes32 value into storage
  /// @param id The storage slot
  /// @param value The bytes32 value
  /// @custom:protected onlyOwner
  function write(bytes32 id, bytes32 value) external onlyOwner {
    id.slot().getBytes32Slot().value = value;
  }

  /// @notice Writes an uint256 value into storage
  /// @param id The storage slot
  /// @param value The uint256 value
  /// @custom:protected onlyOwner
  function write(bytes32 id, uint256 value) external onlyOwner {
    id.slot().getUint256Slot().value = value;
  }

  /// @notice Reads an address value from storage
  /// @param id The storage slot
  /// @return The address value
  function readAddress(bytes32 id) external view returns (address) {
    return id.slot().getAddressSlot().value;
  }

  /// @notice Reads a boolean value from storage
  /// @param id The storage slot
  /// @return The boolean value
  function readBoolean(bytes32 id) external view returns (bool) {
    return id.slot().getBooleanSlot().value;
  }

  /// @notice Reads a bytes32 value from storage
  /// @param id The storage slot
  /// @return The bytes32 value
  function readBytes32(bytes32 id) external view returns (bytes32) {
    return id.slot().getBytes32Slot().value;
  }

  /// @notice Reads an uint256 value from storage
  /// @param id The storage slot
  /// @return The uint256 value
  function readUint256(bytes32 id) external view returns (uint256) {
    return id.slot().getUint256Slot().value;
  }
}
