// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ElementStorage} from "./IElement.sol";
import {IDB} from "../../db/IDB.sol";

abstract contract ElementBase {
  bytes32 internal constant _ELEMENT_STORAGE_SLOT =
    bytes32(uint256(keccak256("element.base.storage")) - 1);

  /// @notice Initializes the element base contract
  /// @param db_ The protocol DB
  function _initializeElement(IDB db_) internal {
    _es().db = db_;
  }

  /// @notice Gets the DB contract
  /// @return The DB contract
  function _db() internal view returns (IDB) {
    return _es().db;
  }

  /// @notice Returns the pointer to the element storage
  /// @return s Element storage pointer
  function _es() internal pure returns (ElementStorage storage s) {
    bytes32 slot = _ELEMENT_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
