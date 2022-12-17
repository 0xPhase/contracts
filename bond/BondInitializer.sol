// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {Manager} from "../core/Manager.sol";
import {BondBase} from "./BondBase.sol";
import {ICash} from "../core/ICash.sol";
import {IDB} from "../db/IDB.sol";

contract BondInitializer is BondBase, ProxyInitializable {
  function initializeBondV1(IDB db_, uint256 bondDuration_)
    external
    initialize("V1")
  {
    _initializeERC20("Phase Cash Bond", "zCASH");

    _setDB(db_);

    address managerAddress = db_.getAddress("MANAGER");

    _s.manager = Manager(managerAddress);
    _s.creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT"));
    _s.cash = ICash(db_.getAddress("CASH"));
    _s.bondDuration = bondDuration_;

    _grantRoleKey(_MANAGER_ROLE, keccak256("MANAGER"));
    _transferOwnership(managerAddress);

    emit BondDurationSet(bondDuration_);
  }
}
