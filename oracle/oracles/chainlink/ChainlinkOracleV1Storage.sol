// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IChainlinkOracle, PriceFeed} from "./IChainlinkOracle.sol";
import {AccessControl} from "../../../core/AccessControl.sol";
import {ISystemClock} from "../../../clock/ISystemClock.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract ChainlinkOracleV1Storage is
  ProxyInitializable,
  AccessControl,
  Multicall,
  IChainlinkOracle
{
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(address => PriceFeed) public priceFeeds;
  ISystemClock public systemClock;

  /// @notice The constructor for the ChainlinkOracleV1Storage contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the Chainlink Oracle on version 1
  /// @param db_ The DB contract
  function initializeChainlinkOracleV1(IDB db_) external initialize("v1") {
    _initializeElement(db_);

    systemClock = ISystemClock(address(db_.getAddress("SYSTEM_CLOCK")));

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));
  }
}
