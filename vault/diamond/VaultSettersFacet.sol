// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {VaultConstants} from "./VaultConstants.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {IVaultSetters} from "../IVault.sol";
import {IInterest} from "../IInterest.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultSettersFacet is VaultBase, IVaultSetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc	IVaultSetters
  function setHealthTarget(
    uint256 user,
    uint256 healthTarget
  )
    external
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(
      healthTarget >= _s.healthTargetMinimum,
      "VaultSettersFacet: Health target too low"
    );

    require(
      healthTarget <= _s.healthTargetMaximum,
      "VaultSettersFacet: Health target too high"
    );

    _s.userInfo[user].healthTarget = healthTarget;

    emit HealthTargetSet(user, healthTarget);
  }

  /// @notice Sets the price oracle contract
  /// @param newPriceOracle The new price oracle contract
  function setPriceOracle(
    IOracle newPriceOracle
  ) external onlyRole(_DEFAULT_ADMIN_ROLE) {
    _s.priceOracle = newPriceOracle;

    emit PriceOracleSet(newPriceOracle);
  }

  /// @notice Sets the interest contract
  /// @param newInterest The new interest contract
  function setInterest(
    IInterest newInterest
  ) external updateDebt onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.interest = newInterest;

    emit InterestSet(newInterest);
  }

  /// @notice Sets the max collateral ratio
  /// @param newMaxCollateralRatio The new max collateral ratio
  function setMaxCollateralRatio(
    uint256 newMaxCollateralRatio
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.maxCollateralRatio = newMaxCollateralRatio;

    emit MaxCollateralRatioSet(newMaxCollateralRatio);
  }

  /// @notice Sets the borrow fee
  /// @param newBorrowFee The new borrow fee
  function setBorrowFee(
    uint256 newBorrowFee
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.borrowFee = newBorrowFee;

    emit BorrowFeeSet(newBorrowFee);
  }

  /// @notice Sets the liquidation fee
  /// @param newLiquidationFee The liquidation fee
  function setLiquidationFee(
    uint256 newLiquidationFee
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.liquidationFee = newLiquidationFee;

    emit LiquidationFeeSet(newLiquidationFee);
  }

  /// @notice Sets the adapter address
  /// @param newAdapter The new adapter address
  function setAdapter(
    address newAdapter
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.adapter = newAdapter;

    emit AdapterSet(newAdapter);
  }

  /// @notice Sets the adapter data
  /// @param newAdapterData The adapter data
  function setAdapterData(
    bytes memory newAdapterData
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.adapterData = newAdapterData;

    emit AdapterDataSet(newAdapterData);
  }

  /// @notice Sets the market state
  /// @param newState The new market state
  function setMarketState(
    bool newState
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.marketsLocked = !newState;

    emit MarketStateSet(newState);
  }

  /// @notice Increases the max amount of CASH that can be minted
  /// @param increase The amount to increase the cap
  function increaseMaxMint(
    uint256 increase
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    _s.maxMint += increase;

    emit MintIncreasedSet(_s.maxMint, increase);
  }

  /// @notice Adds the yield source as an option for users
  /// @param source The yield source to add
  function addYieldSource(
    address source
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    require(
      _s.yieldSources.add(source),
      "VaultSettersFacet: Yield source already added"
    );

    _s.yieldInfo[source].enabled = true;
  }

  /// @notice Sets the yield source enabled state
  /// @param source The yield source
  /// @param state If yield source is enabled
  function setYieldSourceState(
    address source,
    bool state
  ) external onlyRole(VaultConstants.MANAGER_ROLE) {
    require(
      _s.yieldSources.contains(source),
      "VaultSettersFacet: Yield source does not exist"
    );

    _s.yieldInfo[source].enabled = state;
  }
}
