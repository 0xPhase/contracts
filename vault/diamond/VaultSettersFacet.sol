// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IOracle} from "../../oracle/IOracle.sol";
import {IVaultSetters} from "../IVault.sol";
import {IInterest} from "../IInterest.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultSettersFacet is VaultBase, IVaultSetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  function setHealthTarget(uint256 user, uint256 healthTarget)
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

  function setPriceOracle(IOracle newPriceOracle)
    external
    onlyRole(_DEFAULT_ADMIN_ROLE)
  {
    _s.priceOracle = newPriceOracle;

    emit PriceOracleSet(newPriceOracle);
  }

  function setInterest(IInterest newInterest)
    external
    updateDebt
    onlyRole(_MANAGER_ROLE)
  {
    _s.interest = newInterest;

    emit InterestSet(newInterest);
  }

  function setMaxCollateralRatio(uint256 newMaxCollateralRatio)
    external
    onlyRole(_MANAGER_ROLE)
  {
    _s.maxCollateralRatio = newMaxCollateralRatio;

    emit MaxCollateralRatioSet(newMaxCollateralRatio);
  }

  function setBorrowFee(uint256 newBorrowFee) external onlyRole(_MANAGER_ROLE) {
    _s.borrowFee = newBorrowFee;

    emit BorrowFeeSet(newBorrowFee);
  }

  function setLiquidationFee(uint256 newLiquidationFee)
    external
    onlyRole(_MANAGER_ROLE)
  {
    _s.liquidationFee = newLiquidationFee;

    emit LiquidationFeeSet(newLiquidationFee);
  }

  function setMarketState(bool newState) external onlyRole(_MANAGER_ROLE) {
    _s.marketsLocked = !newState;

    emit MarketStateSet(newState);
  }

  function increaseMaxMint(uint256 increase) external onlyRole(_MANAGER_ROLE) {
    _s.maxMint += increase;

    emit MintIncreasedSet(_s.maxMint, increase);
  }

  function addYieldSource(address source) external onlyRole(_MANAGER_ROLE) {
    require(
      _s.yieldSources.add(source),
      "VaultSettersFacet: Yield source already added"
    );

    _s.yieldInfo[source].enabled = true;
  }

  function setYieldSourceState(address source, bool state)
    external
    onlyRole(_MANAGER_ROLE)
  {
    require(
      _s.yieldSources.contains(source),
      "VaultSettersFacet: Yield source does not exist"
    );

    _s.yieldInfo[source].enabled = state;
  }
}
