// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableStorage} from "./IOwnable.sol";

abstract contract OwnableBase {
  bytes32 internal constant _OWNABLE_STORAGE_SLOT =
    bytes32(uint256(keccak256("ownable.storage")) - 1);

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  modifier onlyOwner() {
    require(msg.sender == _owner(), "OwnableBase: Not owner");
    _;
  }

  function _transferOwnership(address newOwner) internal virtual {
    OwnableStorage storage s = _os();
    address oldOwner = s.owner;

    s.owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _owner() internal view returns (address) {
    return _os().owner;
  }

  function _os() internal pure returns (OwnableStorage storage s) {
    bytes32 slot = _OWNABLE_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
