// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {DIAMOND_CUT_ROLE} from "../../diamond/AccessControl/AccessControlCutFacet.sol";
import {ProxyInitializable} from "../../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../../account/ICreditAccount.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {IBalancer} from "../../yield/IBalancer.sol";
import {IPegToken} from "../../peg/IPegToken.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {IInterest} from "../IInterest.sol";
import {IBond} from "../../bond/IBond.sol";
import {VaultStorage} from "../IVault.sol";
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
    require(
      address(db_) != address(0),
      "VaultInitializer: DB cannot be 0 address"
    );

    require(
      address(varStorage_) != address(0),
      "VaultInitializer: Variable Storage cannot be 0 address"
    );

    require(
      address(asset_) != address(0),
      "VaultInitializer: Asset cannot be 0 address"
    );

    require(
      address(priceOracle_) != address(0),
      "VaultInitializer: Price Oracle cannot be 0 address"
    );

    require(
      address(interest_) != address(0),
      "VaultInitializer: Interest cannot be 0 address"
    );

    _initializeElement(db_);

    address managerAddress = db_.getAddress("MANAGER");
    VaultStorage storage s = _s();

    s.varStorage = varStorage_;
    s.asset = asset_;
    s.priceOracle = priceOracle_;
    s.interest = interest_;

    s.systemClock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));
    s.manager = Manager(managerAddress);
    s.creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT"));
    s.cash = IPegToken(db_.getAddress("CASH"));
    s.treasury = ITreasury(db_.getAddress("TREASURY"));
    s.bond = IBond(db_.getAddress("BOND"));
    s.balancer = IBalancer(db_.getAddress("BALANCER"));

    s.maxMint = initialMaxMint_;
    s.maxCollateralRatio = initialMaxCollateralRatio_;
    s.borrowFee = initialBorrowFee_;
    s.liquidationFee = initialLiquidationFee_;
    s.healthTargetMinimum = initialHealthTargetMinimum_;
    s.healthTargetMaximum = initialHealthTargetMaximum_;

    s.adapter = adapter_;
    s.adapterData = adapterData_;

    s.lastDebtUpdate = s.systemClock.time();

    _initializeAccessControlWithKey(keccak256("MANAGER"));

    _grantRoleKey(VaultConstants.MANAGER_ROLE, keccak256("MANAGER"));
    _grantRoleKey(VaultConstants.DEV_ROLE, keccak256("DEV"));

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
  function initializeVaultOwner(address owner) public initialize("v1") {
    require(owner != address(0), "VaultInitializer: Owner cannot be 0 address");

    _grantRoleKey(DIAMOND_CUT_ROLE, keccak256("MANAGER"));
    _disableInitialization();
  }
}
