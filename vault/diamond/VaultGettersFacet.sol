// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultGetters, UserInfo, UserYield, YieldInfo} from "../IVault.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {IInterest} from "../IInterest.sol";
import {ICash} from "../../core/ICash.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultGettersFacet is VaultBase, IVaultGetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  function isSolvent(uint256 user) external view returns (bool) {
    return _isSolvent(user);
  }

  function debtValue(uint256 user) external view returns (uint256) {
    return _debtValueUser(user);
  }

  function depositValue(uint256 user) external view returns (uint256) {
    return _depositValueUser(user);
  }

  function deposit(uint256 user) external view returns (uint256) {
    return _deposit(user);
  }

  function yieldDeposit(uint256 user) external view returns (uint256 result) {
    return _yieldDeposit(user);
  }

  function pureDeposit(uint256 user) external view returns (uint256) {
    return _pureDeposit(user);
  }

  function yieldSources(uint256 user)
    external
    view
    returns (address[] memory sources)
  {
    UserYield storage yield = _s.userYield[user];
    uint256 length = yield.yieldSources.length();

    sources = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      sources[i] = yield.yieldSources.at(i);
    }
  }

  function price()
    external
    view
    returns (
      uint256 // override
    )
  {
    return _price();
  }

  function getInterest() external view returns (uint256) {
    return _interest();
  }

  function collectiveCollateral()
    external
    view
    returns (
      uint256 //override
    )
  {
    return _s.asset.balanceOf(address(this));
  }

  function allYieldSources() external view returns (address[] memory sources) {
    uint256 length = _s.yieldSources.length();

    sources = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      sources[i] = _s.yieldSources.at(i);
    }
  }

  function userInfo(uint256 user) external view returns (UserInfo memory) {
    return _s.userInfo[user];
  }

  function yieldInfo(address yieldSource)
    external
    view
    returns (YieldInfo memory)
  {
    return _s.yieldInfo[yieldSource];
  }

  function manager() external view returns (Manager) {
    return _s.manager;
  }

  function cash() external view returns (ICash) {
    return _s.cash;
  }

  function treasury() external view returns (ITreasury) {
    return _s.treasury;
  }

  function varStorage() external view returns (Storage) {
    return _s.varStorage;
  }

  function asset() external view returns (IERC20) {
    return _s.asset;
  }

  function priceOracle() external view returns (IOracle) {
    return _s.priceOracle;
  }

  function interest() external view returns (IInterest) {
    return _s.interest;
  }

  function maxMint() external view returns (uint256) {
    return _s.maxMint;
  }

  function maxCollateralRatio() external view returns (uint256) {
    return _s.maxCollateralRatio;
  }

  function borrowFee() external view returns (uint256) {
    return _s.borrowFee;
  }

  function liquidationFee() external view returns (uint256) {
    return _s.liquidationFee;
  }

  function healthTargetMinimum() external view returns (uint256) {
    return _s.healthTargetMinimum;
  }

  function healthTargetMaximum() external view returns (uint256) {
    return _s.healthTargetMaximum;
  }

  function collectiveDebt() external view returns (uint256) {
    return _s.collectiveDebt;
  }

  function totalDebtShares() external view returns (uint256) {
    return _s.totalDebtShares;
  }

  function lastDebtUpdate() external view returns (uint256) {
    return _s.lastDebtUpdate;
  }

  function contextLocked() external view returns (bool) {
    return _s.contextLocked;
  }

  function marketsLocked() external view returns (bool) {
    return _s.marketsLocked;
  }
}
