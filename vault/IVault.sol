// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAccessControl} from "../diamond/AccessControl/IAccessControl.sol";
import {IMulticall} from "../diamond/Multicall/IMulticall.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {ITreasury} from "../treasury/ITreasury.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {Storage} from "../misc/Storage.sol";
import {Manager} from "../core/Manager.sol";
import {IInterest} from "./IInterest.sol";
import {ICash} from "../core/ICash.sol";
import {IBond} from "../bond/IBond.sol";

struct UserInfo {
  // User info
  uint256 version;
  uint256 deposit;
  uint256 debtShares;
  uint256 healthTarget;
}

struct UserYield {
  // User yield
  EnumerableSet.AddressSet yieldSources;
}

struct YieldInfo {
  // Yield info
  bool enabled;
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
  mapping(uint256 => UserYield) userYield;
  mapping(address => YieldInfo) yieldInfo;
  EnumerableSet.AddressSet yieldSources;
  // External contracts
  IERC20 asset;
  IOracle priceOracle;
  IInterest interest;
  Storage varStorage;
  Manager manager;
  ICreditAccount creditAccount;
  ICash cash;
  ITreasury treasury;
  IBond bond;
  // Vault variables
  uint256 maxMint;
  uint256 maxCollateralRatio;
  uint256 borrowFee;
  uint256 liquidationFee;
  uint256 healthTargetMinimum;
  uint256 healthTargetMaximum;
  // Debt info
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

interface IVaultAccounting {
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) external payable;

  function removeCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) external;

  function mintUSD(uint256 user, uint256 amount) external;

  function mintUSD(
    uint256 user,
    uint256 amount,
    bool useMax
  ) external;

  function repayUSD(uint256 user, uint256 shares) external;

  function repayUSD(
    uint256 user,
    uint256 shares,
    bool useMax
  ) external;
}

interface IVaultGetters {
  function isSolvent(uint256 user) external view returns (bool);

  function debtValue(uint256 user) external view returns (uint256);

  function depositValue(uint256 shares) external view returns (uint256);

  function deposit(uint256 user) external view returns (uint256);

  function yieldDeposit(uint256 user) external view returns (uint256);

  function pureDeposit(uint256 user) external view returns (uint256);

  function yieldSources(uint256 user) external view returns (address[] memory);

  function price() external view returns (uint256);

  function getInterest() external view returns (uint256);

  function collectiveCollateral() external view returns (uint256);

  function allYieldSources() external view returns (address[] memory);

  function userInfo(uint256 user) external view returns (UserInfo memory);

  function yieldInfo(address yieldSource)
    external
    view
    returns (YieldInfo memory);

  function manager() external view returns (Manager);

  function cash() external view returns (ICash);

  function treasury() external view returns (ITreasury);

  function varStorage() external view returns (Storage);

  function asset() external view returns (IERC20);

  function priceOracle() external view returns (IOracle);

  function maxMint() external view returns (uint256);

  function interest() external view returns (IInterest);

  function maxCollateralRatio() external view returns (uint256);

  function borrowFee() external view returns (uint256);

  function liquidationFee() external view returns (uint256);

  function healthTargetMinimum() external view returns (uint256);

  function healthTargetMaximum() external view returns (uint256);

  function collectiveDebt() external view returns (uint256);

  function totalDebtShares() external view returns (uint256);

  function lastDebtUpdate() external view returns (uint256);

  function contextLocked() external view returns (bool);

  function marketsLocked() external view returns (bool);
}

interface IVaultLiquidation {
  function liquidateUser(uint256 user) external;

  function liquidationInfo(uint256 user)
    external
    view
    returns (LiquidationInfo memory);
}

interface IVaultSetters {
  function setHealthTarget(uint256 user, uint256 healthTarget) external;
}

interface IVaultYield {
  function depositYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  ) external;

  function withdrawYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  ) external;

  function withdrawFullYield(uint256 user, address yieldSource) external;

  function withdrawEverythingYield(uint256 user) external;
}

// solhint-disable-next-line no-empty-blocks
interface IVault is
  IVaultAccounting,
  IVaultGetters,
  IVaultLiquidation,
  IVaultSetters,
  IVaultYield,
  IAccessControl,
  IMulticall
{

}
