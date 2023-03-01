// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../../account/ICreditAccount.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {IBalancer} from "../../yield/IBalancer.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {ICash} from "../../core/ICash.sol";
import {IInterest} from "../IInterest.sol";
import {IBond} from "../../bond/IBond.sol";
import {VaultBase} from "./VaultBase.sol";
import {IDB} from "../../db/IDB.sol";

contract VaultInitializer is VaultBase, ProxyInitializable {
  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the Vault contract on version v1
  /// @param db_ The db contract
  /// @param varStorage_ The var Ssorage contract
  /// @param asset_ The asset token contract
  /// @param priceOracle_ The price oracle contract
  /// @param interest_ The interest contract
  /// @param initialMaxMint_ The initial max mint
  /// @param initialMaxCollateralRatio_ The initial max collateral ratio
  /// @param initialBorrowFee_ The initial borrow fee
  /// @param initialLiquidationFee_ The initial liquidation fee
  /// @param initialHealthTargetMinimum_ The initial health target minimum
  /// @param initialHealthTargetMaximum_ The initial health target maximum
  /// @param adapter_ The optional adapter address
  /// @param adapterData_ The optional adapter data
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
    _initializeElement(db_);

    address managerAddress = db_.getAddress("MANAGER");

    _s.varStorage = varStorage_;
    _s.asset = asset_;
    _s.priceOracle = priceOracle_;
    _s.interest = interest_;

    _s.systemClock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));
    _s.manager = Manager(managerAddress);
    _s.creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT"));
    _s.cash = ICash(db_.getAddress("CASH"));
    _s.treasury = ITreasury(db_.getAddress("TREASURY"));
    _s.bond = IBond(db_.getAddress("BOND"));
    _s.balancer = IBalancer(db_.getAddress("BALANCER"));

    _s.maxMint = initialMaxMint_;
    _s.maxCollateralRatio = initialMaxCollateralRatio_;
    _s.borrowFee = initialBorrowFee_;
    _s.liquidationFee = initialLiquidationFee_;
    _s.healthTargetMinimum = initialHealthTargetMinimum_;
    _s.healthTargetMaximum = initialHealthTargetMaximum_;

    _s.adapter = adapter_;
    _s.adapterData = adapterData_;

    _s.lastDebtUpdate = _s.systemClock.time();

    _grantRoleKey(VaultConstants.MANAGER_ROLE, keccak256("MANAGER"));
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

  /// @notice Initializes the target diamond to allow for cutting
  /// @param owner The diamond owner
  function initializeVaultOwner(address owner) public initialize("owner") {
    _transferOwnership(owner);
    _disableInitialization();
  }
}
