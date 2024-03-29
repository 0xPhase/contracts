// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVaultGetters, UserInfo, VaultStorage} from "../IVault.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {IPegToken} from "../../peg/IPegToken.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {IYield} from "../../yield/IYield.sol";
import {IInterest} from "../IInterest.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultGettersFacet is VaultBase, IVaultGetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc	IVaultGetters
  function userInfo(
    uint256 user
  ) external view override returns (UserInfo memory) {
    return _s().userInfo[user];
  }

  /// @inheritdoc	IVaultGetters
  function isSolvent(uint256 user) external view override returns (bool) {
    return _isSolvent(user);
  }

  /// @inheritdoc	IVaultGetters
  function debtValue(uint256 user) external view override returns (uint256) {
    return _debtValueUser(user);
  }

  /// @inheritdoc	IVaultGetters
  function debtShares(uint256 user) external view override returns (uint256) {
    return _s().debtShares[user];
  }

  /// @inheritdoc	IVaultGetters
  function depositValue(uint256 user) external view override returns (uint256) {
    return _depositValueUser(user);
  }

  /// @inheritdoc	IVaultGetters
  function deposit(uint256 user) external view override returns (uint256) {
    return _deposit(user);
  }

  /// @inheritdoc	IVaultGetters
  function yieldDeposit(
    uint256 user
  ) external view override returns (uint256 result) {
    return _yieldDeposit(user);
  }

  /// @inheritdoc	IVaultGetters
  function pureDeposit(uint256 user) external view override returns (uint256) {
    return _pureDeposit(user);
  }

  /// @inheritdoc	IVaultGetters
  function price() external view override returns (uint256) {
    return _price();
  }

  /// @inheritdoc	IVaultGetters
  function getInterest() external view override returns (uint256) {
    return _interest();
  }

  /// @inheritdoc	IVaultGetters
  function collectiveCollateral()
    external
    view
    override
    returns (uint256 result)
  {
    VaultStorage storage s = _s();

    return s.asset.balanceOf(address(this)) + s.balancer.totalBalance(s.asset);
  }

  /// @inheritdoc	IVaultGetters
  function systemClock() external view override returns (ISystemClock) {
    return _s().systemClock;
  }

  /// @inheritdoc	IVaultGetters
  function manager() external view override returns (Manager) {
    return _s().manager;
  }

  /// @inheritdoc	IVaultGetters
  function cash() external view override returns (IPegToken) {
    return _s().cash;
  }

  /// @inheritdoc	IVaultGetters
  function treasury() external view override returns (ITreasury) {
    return _s().treasury;
  }

  /// @inheritdoc	IVaultGetters
  function varStorage() external view override returns (Storage) {
    return _s().varStorage;
  }

  /// @inheritdoc	IVaultGetters
  function asset() external view override returns (IERC20) {
    return _s().asset;
  }

  /// @inheritdoc	IVaultGetters
  function priceOracle() external view override returns (IOracle) {
    return _s().priceOracle;
  }

  /// @inheritdoc	IVaultGetters
  function interest() external view override returns (IInterest) {
    return _s().interest;
  }

  /// @inheritdoc	IVaultGetters
  function maxMint() external view override returns (uint256) {
    return _s().maxMint;
  }

  /// @inheritdoc	IVaultGetters
  function maxCollateralRatio() external view override returns (uint256) {
    return _s().maxCollateralRatio;
  }

  /// @inheritdoc	IVaultGetters
  function borrowFee() external view override returns (uint256) {
    return _s().borrowFee;
  }

  /// @inheritdoc	IVaultGetters
  function liquidationFee() external view override returns (uint256) {
    return _s().liquidationFee;
  }

  /// @inheritdoc	IVaultGetters
  function healthTargetMinimum() external view override returns (uint256) {
    return _s().healthTargetMinimum;
  }

  /// @inheritdoc	IVaultGetters
  function healthTargetMaximum() external view override returns (uint256) {
    return _s().healthTargetMaximum;
  }

  /// @inheritdoc	IVaultGetters
  function collectiveDebt() external view override returns (uint256) {
    return _s().collectiveDebt;
  }

  /// @inheritdoc	IVaultGetters
  function totalDebtShares() external view override returns (uint256) {
    return _s().totalDebtShares;
  }

  /// @inheritdoc	IVaultGetters
  function lastDebtUpdate() external view override returns (uint256) {
    return _s().lastDebtUpdate;
  }

  /// @inheritdoc	IVaultGetters
  function contextLocked() external view override returns (bool) {
    return _s().contextLocked;
  }

  /// @inheritdoc	IVaultGetters
  function marketsLocked() external view override returns (bool) {
    return _s().marketsLocked;
  }
}
