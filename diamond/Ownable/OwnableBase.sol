// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {OwnableStorage} from "./IOwnable.sol";

abstract contract OwnableBase {
  bytes32 internal constant _OWNABLE_STORAGE_SLOT =
    bytes32(uint256(keccak256("ownable.storage")) - 1);

  /// @notice Event emitted when the ownership is transferred
  /// @param previousOwner The previous owner address
  /// @param newOwner The new owner address
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Checks if the message sender is the owner
  modifier onlyOwner() {
    require(msg.sender == _owner(), "OwnableBase: Not owner");
    _;
  }

  /// @notice Transfers ownership to new owner
  /// @param newOwner The address of the new owner
  function _transferOwnership(address newOwner) internal virtual {
    OwnableStorage storage s = _os();
    address oldOwner = s.owner;

    s.owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  /// @notice Returns the current owner
  /// @return The current owner
  function _owner() internal view returns (address) {
    return _os().owner;
  }

  /// @notice Returns the Ownable storage pointer
  /// @return s The Ownable storage pointer
  function _os() internal pure returns (OwnableStorage storage s) {
    bytes32 slot = _OWNABLE_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
