// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {AccessControl} from "../core/AccessControl.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {IPegToken} from "./IPegToken.sol";
import {IDB} from "../db/IDB.sol";

struct PegItem {
  IPegToken pegToken;
  address trackedAsset;
}

interface IPegRegistry {
  function exists(IPegToken pegToken) external view returns (bool);

  function price(IPegToken pegToken) external view returns (uint256);

  function registry(
    IPegToken keyToken
  ) external view returns (IPegToken pegToken, address trackedAsset);
}

abstract contract PegRegistryV1Storage is
  IPegRegistry,
  IOracle,
  AccessControl,
  ProxyInitializable
{
  bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(IPegToken => PegItem) public registry;
  IOracle public oracle;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the peg registry contract on version 1
  /// @param oracle_ The price oracle
  function initializePegRegistryV1(IOracle oracle_) external initialize("v1") {
    oracle = oracle_;

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));
  }
}
