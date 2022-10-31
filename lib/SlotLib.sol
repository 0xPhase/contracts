// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library SlotLib {
  function slot(bytes32 id) internal pure returns (bytes32) {
    return bytes32(uint256(id) - 1);
  }

  function slot(string memory id) internal pure returns (bytes32) {
    return slot(keccak256(bytes(id)));
  }
}
