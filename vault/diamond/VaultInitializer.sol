// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../../account/ICreditAccount.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {ICash} from "../../core/ICash.sol";
import {IInterest} from "../IInterest.sol";
import {IBond} from "../../bond/IBond.sol";
import {VaultBase} from "./VaultBase.sol";
import {IDB} from "../../db/IDB.sol";

contract VaultInitializer is VaultBase, ProxyInitializable {
  function initializeVaultV1(
    IDB db_,
    Storage varStorage_,
    IERC20 asset_,
    IOracle priceOracle_,
    IInterest interest_,
    uint256 initialMaxMint_,
    uint256 initialMaxCollateralRatio_,
    uint256 initialBorrowFee_,
    uint256 initialLiquidationFee_,
    uint256 initialHealthTargetMinimum_,
    uint256 initialHealthTargetMaximum_,
    address adapter_,
    bytes memory adapterData_
  ) external initialize("v1") {
    _initializeDB(db_);

    address managerAddress = db_.getAddress("MANAGER");

    _s.varStorage = varStorage_;
    _s.asset = asset_;
    _s.priceOracle = priceOracle_;
    _s.interest = interest_;

    _s.manager = Manager(managerAddress);
    _s.creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT"));
    _s.cash = ICash(db_.getAddress("CASH"));
    _s.treasury = ITreasury(db_.getAddress("TREASURY"));
    _s.bond = IBond(db_.getAddress("BOND"));

    _s.maxMint = initialMaxMint_;
    _s.maxCollateralRatio = initialMaxCollateralRatio_;
    _s.borrowFee = initialBorrowFee_;
    _s.liquidationFee = initialLiquidationFee_;
    _s.healthTargetMinimum = initialHealthTargetMinimum_;
    _s.healthTargetMaximum = initialHealthTargetMaximum_;

    _s.adapter = adapter_;
    _s.adapterData = adapterData_;

    _s.lastDebtUpdate = block.timestamp;

    _grantRoleKey(_MANAGER_ROLE, keccak256("MANAGER"));
    _transferOwnership(managerAddress);

    emit PriceOracleSet(priceOracle_);
    emit InterestSet(interest_);
    emit MaxCollateralRatioSet(initialMaxCollateralRatio_);
    emit BorrowFeeSet(initialBorrowFee_);
    emit LiquidationFeeSet(initialLiquidationFee_);
    emit HealthTargetMinimumSet(initialHealthTargetMinimum_);
    emit HealthTargetMaximumSet(initialHealthTargetMaximum_);
    emit AdapterSet(adapter_);
    emit AdapterDataSet(adapterData_);
  }

  function initializeVaultOwner(address owner) public initialize("owner") {
    _transferOwnership(owner);
    _disableInitialization();
  }
}
