// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {StringLib} from "../../lib/StringLib.sol";

abstract contract ProxyInitializable {
  using StorageSlot for bytes32;
  using StringLib for string;

  modifier initialize(string memory version) {
    StorageSlot.BooleanSlot storage slot = _slot(version).getBooleanSlot();

    if (!slot.value) {
      _;

      slot.value = true;
    }
  }

  function _slot(string memory version) internal pure returns (bytes32) {
    return
      bytes32(
        uint256(
          keccak256(
            bytes(string("proxy.initializable.initialized.").append(version))
          )
        ) - 1
      );
  }
}
