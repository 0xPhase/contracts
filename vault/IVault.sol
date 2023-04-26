// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAccessControl} from "../diamond/AccessControl/IAccessControl.sol";
import {IMulticall} from "../diamond/Multicall/IMulticall.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {ITreasury} from "../treasury/ITreasury.sol";
import {IBalancer} from "../balancer/IBalancer.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {Storage} from "../misc/Storage.sol";
import {Manager} from "../core/Manager.sol";
import {IInterest} from "./IInterest.sol";
import {IAdapter} from "./IAdapter.sol";
import {IBond} from "../bond/IBond.sol";

import {IVaultLiquidation} from "./interfaces/IVaultLiquidation.sol";
import {IVaultAccounting} from "./interfaces/IVaultAccounting.sol";
import {IVaultGetters} from "./interfaces/IVaultGetters.sol";
import {IVaultSetters} from "./interfaces/IVaultSetters.sol";

struct UserInfo {
  // User info
  uint256 version;
  uint256 deposit;
  uint256 healthTarget;
  uint256 yieldPercent;
}

struct LiquidationInfo {
  // Liquidation info
  bool solvent;
  uint256 borrowChange;
  uint256 assetReward;
  uint256 protocolFee;
  uint256 rebate;
}

struct VaultStorage {
  // Info
  mapping(uint256 => UserInfo) userInfo;
  // External contracts
  IERC20 asset;
  IOracle priceOracle;
  IInterest interest;
  Storage varStorage;
  ISystemClock systemClock;
  Manager manager;
  ICreditAccount creditAccount;
  IPegToken cash;
  ITreasury treasury;
  IBond bond;
  IBalancer balancer;
  // Vault variables
  uint256 maxMint;
  uint256 maxCollateralRatio;
  uint256 borrowFee;
  uint256 liquidationFee;
  uint256 healthTargetMinimum;
  uint256 healthTargetMaximum;
  // Debt
  mapping(uint256 => uint256) debtShares;
  uint256 collectiveDebt;
  uint256 totalDebtShares;
  uint256 lastDebtUpdate;
  // Adapter
  address adapter;
  bytes adapterData;
  // Lock state
  bool contextLocked;
  bool marketsLocked;
}

// solhint-disable-next-line no-empty-blocks
interface IVault is
  IVaultAccounting,
  IVaultGetters,
  IVaultLiquidation,
  IVaultSetters,
  IAccessControl,
  IMulticall
{

}
