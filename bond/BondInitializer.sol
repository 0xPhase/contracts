// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {Manager} from "../core/Manager.sol";
import {BondBase} from "./BondBase.sol";
import {IDB} from "../db/IDB.sol";

contract BondInitializer is BondBase, ProxyInitializable {
  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the bond contract on version 1
  /// @param db_ The protocol DB
  /// @param bondDuration_ The bond duration
  /// @param protocolExitPortion_ The protocol exit portion
  function initializeBondV1(
    IDB db_,
    uint256 bondDuration_,
    uint256 protocolExitPortion_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeClock();
    _initializeERC20("Phase Cash Bond", "zCASH");

    address managerAddress = db_.getAddress("MANAGER");

    _s.manager = Manager(managerAddress);
    _s.creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT"));
    _s.cash = IPegToken(db_.getAddress("CASH"));
    _s.bondDuration = bondDuration_;
    _s.protocolExitPortion = protocolExitPortion_;

    _grantRoleKey(_MANAGER_ROLE, keccak256("MANAGER"));
    _transferOwnership(managerAddress);

    emit BondDurationSet(bondDuration_);
    emit ProtocolExitPortionSet(protocolExitPortion_);
  }
}
