// SPDX-License-Identifier: BUSL-1.1
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
import {IAdapter} from "./IAdapter.sol";
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
  /// @notice Adds collateral for the user
  /// @param user The user id
  /// @param amount The amount to add
  /// @param extraData The extra adapter data
  function addCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) external payable;

  /// @notice Removes collateral from the user
  /// @param user The user id
  /// @param amount The amount to remove
  /// @param extraData The extra adapter data
  function removeCollateral(
    uint256 user,
    uint256 amount,
    bytes memory extraData
  ) external;

  /// @notice Mints CASH for the user
  /// @param user The user id
  /// @param amount Yhe amount to mint
  function mintUSD(uint256 user, uint256 amount) external;

  /// @notice Mints CASH for the user
  /// @param user The user id
  /// @param amount The amount to mint
  /// @param useMax If minting too much, mint max allowed instead
  function mintUSD(uint256 user, uint256 amount, bool useMax) external;

  /// @notice Repays CASH for the user
  /// @param user The user id
  /// @param shares The amount of shares to repay
  function repayUSD(uint256 user, uint256 shares) external;

  /// @notice Repays CASH for the user
  /// @param user The user id
  /// @param shares The amount of shares to repay
  /// @param useMax If repaying too much, repay as much as wallet balance allows
  function repayUSD(uint256 user, uint256 shares, bool useMax) external;
}

interface IVaultGetters {
  /// @notice Returns if the user is solvent
  /// @param user The user id
  /// @return If the user is solvent
  function isSolvent(uint256 user) external view returns (bool);

  /// @notice Returns the user's debt value in dollars
  /// @param user The user id
  /// @return The debt value
  function debtValue(uint256 user) external view returns (uint256);

  /// @notice Returns the user's deposit value in dollars
  /// @param user The user id
  /// @return The deposit value
  function depositValue(uint256 user) external view returns (uint256);

  /// @notice Returns the user's total deposit in token amount
  /// @param user The user id
  /// @return The total deposit
  function deposit(uint256 user) external view returns (uint256);

  /// @notice Returns the user's yield deposit in token amount
  /// @param user The user id
  /// @return The yield deposit
  function yieldDeposit(uint256 user) external view returns (uint256);

  /// @notice Returns the user's vault deposit in token amount
  /// @param user The user id
  /// @return The vault deposit
  function pureDeposit(uint256 user) external view returns (uint256);

  /// @notice Returns all yield sources used by the user
  /// @param user The user id
  /// @return The list of yield sources
  function yieldSources(uint256 user) external view returns (address[] memory);

  /// @notice Returns the price of the underlying asset from the oracle
  /// @return The underlying asset price
  function price() external view returns (uint256);

  /// @notice Returns the interest rate for the vault
  /// @return The interest rate
  function getInterest() external view returns (uint256);

  /// @notice Returns the total amount of collateral in the vault and invested in all yield sources
  /// @return The amount of collateral
  function collectiveCollateral() external view returns (uint256);

  /// @notice Returns all the available yield sources
  /// @return The list of yield sources
  function allYieldSources() external view returns (address[] memory);

  /// @notice Returns the user info for the user
  /// @param user The user id
  /// @return The user info
  function userInfo(uint256 user) external view returns (UserInfo memory);

  /// @notice Returns the yield info for the source
  /// @param yieldSource The yield source address
  /// @return The yield info
  function yieldInfo(
    address yieldSource
  ) external view returns (YieldInfo memory);

  /// @notice Returns the manager contract
  /// @return The manager contract
  function manager() external view returns (Manager);

  /// @notice Returns the cash contract
  /// @return The cash contract
  function cash() external view returns (ICash);

  /// @notice Returns the treasury contract
  /// @return The treasury contract
  function treasury() external view returns (ITreasury);

  /// @notice Returns the storage contract
  /// @return The storage contract
  function varStorage() external view returns (Storage);

  /// @notice Returns the asset token contract
  /// @return The asset token contract
  function asset() external view returns (IERC20);

  /// @notice Returns the price oracle contract
  /// @return The price oracle contract
  function priceOracle() external view returns (IOracle);

  /// @notice Returns the max mint
  /// @return The max mint
  function maxMint() external view returns (uint256);

  /// @notice Returns the interest contract
  /// @return The interest contract
  function interest() external view returns (IInterest);

  /// @notice Returns the max collateral ratio
  /// @return The max collateral ratio
  function maxCollateralRatio() external view returns (uint256);

  /// @notice Returns the borrow fee
  /// @return The borrow fee
  function borrowFee() external view returns (uint256);

  /// @notice Returns the liquidation fee
  /// @return The liquidation fee
  function liquidationFee() external view returns (uint256);

  /// @notice Returns the health target minimum
  /// @return The health target minimum
  function healthTargetMinimum() external view returns (uint256);

  /// @notice Returns the health target maximum
  /// @return The health target minimum
  function healthTargetMaximum() external view returns (uint256);

  /// @notice Returns the collective debt
  /// @return The collective debt
  function collectiveDebt() external view returns (uint256);

  /// @notice Returns the total debt shares
  /// @return The total debt shares
  function totalDebtShares() external view returns (uint256);

  /// @notice Returns the last debt update timestamp
  /// @return The last debt update timestamp
  function lastDebtUpdate() external view returns (uint256);

  /// @notice Returns if the context is currently locked due to a sensitive function being called
  /// @return If the context is currently locked
  function contextLocked() external view returns (bool);

  /// @notice Returns if the market is current locked
  /// @return If the matket is currently locked
  function marketsLocked() external view returns (bool);
}

interface IVaultLiquidation {
  /// @notice Liquidates a user based on liquidationInfo(user)
  /// @param user The user id
  function liquidateUser(uint256 user) external;

  /// @notice Returns liquidation info about the user
  /// @param user The user id
  /// @return The liquidation info
  function liquidationInfo(
    uint256 user
  ) external view returns (LiquidationInfo memory);
}

interface IVaultSetters {
  /// @notice Sets the health target for a liquidation for the user
  /// @param user The user id
  /// @param healthTarget The health target
  function setHealthTarget(uint256 user, uint256 healthTarget) external;
}

interface IVaultYield {
  /// @notice Deposits collateral into the yield source for the user
  /// @param user The user id
  /// @param yieldSource The yield source
  /// @param amount The deposit amount
  function depositYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  ) external;

  /// @notice Withdraws collateral from the yield source for the user
  /// @param user The user id
  /// @param yieldSource The yield source
  /// @param amount The withdraw amount
  function withdrawYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  ) external;

  /// @notice Withdraws all collateral from the yield source for the user
  /// @param user The user id
  /// @param yieldSource The yield source
  function withdrawFullYield(uint256 user, address yieldSource) external;

  /// @notice Withdraws all collateral from all yield sources for the user
  /// @param user The user id
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
