// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {DIAMOND_CUT_ROLE} from "../../diamond/AccessControl/AccessControlCutFacet.sol";
import {ProxyInitializable} from "../../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../../account/ICreditAccount.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {BalancerStorage} from "../IBalancer.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {IDB} from "../../db/IDB.sol";

contract BalancerInitializer is BalancerBase, ProxyInitializable {
  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the Balancer contract on version 1
  /// @param db_ The protocol DB
  /// @param initialPerformanceFee_ The initial performance fee
  function initializeBalancerV1(
    IDB db_,
    uint256 initialPerformanceFee_
  ) external initialize("v1") {
    require(
      address(db_) != address(0),
      "BalancerInitializer: DB cannot be 0 address"
    );

    require(
      initialPerformanceFee_ <= 0.1 ether,
      "BalancerInitializer: Fee cannot be above 10%"
    );

    _initializeElement(db_);
    _initializeClock();

    BalancerStorage storage s = _s();

    s.treasury = ITreasury(db_.getAddress("TREASURY"));
    s.performanceFee = initialPerformanceFee_;

    s.feeAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT")).getAccount(
      db_.getAddress("MANAGER")
    );

    _initializeAccessControlWithKey(keccak256("MANAGER"));

    _grantRoleKey(DIAMOND_CUT_ROLE, keccak256("MANAGER"));
    _grantRoleKey(BalancerConstants.MANAGER_ROLE, keccak256("MANAGER"));
    _grantRoleKey(BalancerConstants.DEV_ROLE, keccak256("DEV"));
    _grantRoleKey(BalancerConstants.VAULT_ROLE, keccak256("VAULT"));

    emit PerformanceFeeSet(initialPerformanceFee_);
  }
}
