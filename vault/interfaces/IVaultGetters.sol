// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMulticall} from "../../diamond/Multicall/IMulticall.sol";
import {ICreditAccount} from "../../account/ICreditAccount.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {IBalancer} from "../../yield/IBalancer.sol";
import {IPegToken} from "../../peg/IPegToken.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {Storage} from "../../misc/Storage.sol";
import {Manager} from "../../core/Manager.sol";
import {IInterest} from "../IInterest.sol";
import {IAdapter} from "../IAdapter.sol";
import {IBond} from "../../bond/IBond.sol";

interface IVaultGetters {
  /// @notice Returns if the user is solvent
  /// @param user The user id
  /// @return If the user is solvent
  function isSolvent(uint256 user) external view returns (bool);

  /// @notice Returns the user's debt value in dollars
  /// @param user The user id
  /// @return The debt value
  function debtValue(uint256 user) external view returns (uint256);

  /// @notice Returns the user's debt shares
  /// @param user The user id
  /// @return The debt shares
  function debtShares(uint256 user) external view returns (uint256);

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

  /// @notice Returns the price of the underlying asset from the oracle
  /// @return The underlying asset price
  function price() external view returns (uint256);

  /// @notice Returns the interest rate for the vault
  /// @return The interest rate
  function getInterest() external view returns (uint256);

  /// @notice Returns the total amount of collateral in the vault and invested in yield
  /// @return The amount of collateral
  function collectiveCollateral() external view returns (uint256);

  /// @notice Returns the system clock contract
  /// @return The system clock contract
  function systemClock() external view returns (ISystemClock);

  /// @notice Returns the manager contract
  /// @return The manager contract
  function manager() external view returns (Manager);

  /// @notice Returns the cash contract
  /// @return The cash contract
  function cash() external view returns (IPegToken);

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
