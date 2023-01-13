// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {StringLib} from "../../lib/StringLib.sol";

abstract contract ProxyInitializable {
  using StorageSlot for bytes32;
  using StringLib for string;

  event VersionInitialized(string indexed version);

  modifier initialize(string memory version) {
    StorageSlot.BooleanSlot storage disabledSlot = _disabledSlot()
      .getBooleanSlot();

    StorageSlot.BooleanSlot storage versionSlot = _versionSlot(version)
      .getBooleanSlot();

    if (!versionSlot.value && !disabledSlot.value) {
      _;

      emit VersionInitialized(version);
      versionSlot.value = true;
    }
  }

  function _disableInitialization() internal {
    StorageSlot.BooleanSlot storage disabledSlot = _disabledSlot()
      .getBooleanSlot();

    disabledSlot.value = true;
  }

  function _disabledSlot() internal pure returns (bytes32) {
    return bytes32(uint256(keccak256("proxy.initializable.disabled")) - 1);
  }

  function _versionSlot(string memory version) internal pure returns (bytes32) {
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
