// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SlotLib {
  /// @notice Returns the slot associated with an id
  /// @param id The bytes32 id
  /// @return The storage slot
  function slot(bytes32 id) internal pure returns (bytes32) {
    return bytes32(uint256(id) - 1);
  }

  /// @notice Returns the slot associated with an id
  /// @param id The string id
  /// @return The storage slot
  function slot(string memory id) internal pure returns (bytes32) {
    return slot(keccak256(bytes(id)));
  }
}
