// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IChainOracle, Chain} from "./IChainOracle.sol";
import {AccessControl} from "../../../core/AccessControl.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract ChainOracleV1Storage is
  ProxyInitializable,
  AccessControl,
  Multicall,
  IChainOracle
{
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(address => Chain) internal _chains;
  EnumerableSet.AddressSet internal _feeds;

  /// @notice The constructor for the ChainOracleV1Storage contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the Chain Oracle on version 1
  /// @param db_ The DB contract
  function initializeChainOracleV1(IDB db_) external initialize("v1") {
    _initializeElement(db_);

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));
  }
}
