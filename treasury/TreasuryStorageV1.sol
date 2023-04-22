// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {ITreasury, Cause} from "./ITreasury.sol";
import {IDB} from "../db/IDB.sol";

abstract contract TreasuryStorageV1 is
  AccessControl,
  ProxyInitializable,
  ITreasury
{
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(bytes32 => Cause) internal _cause;
  Cause internal _globalCause;

  // The constructor for the TreasuryStorageV1 contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the treasury contract on version 1
  /// @param db_ The protocol DB
  function initializeTreasuryV1(IDB db_) public initialize("v1") {
    _initializeElement(db_);

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("VAULT"));
  }
}
