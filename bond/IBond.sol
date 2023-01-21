// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IAccessControl} from "../diamond/AccessControl/IAccessControl.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IERC20} from "../diamond/ERC20/IERC20.sol";
import {Manager} from "../core/Manager.sol";
import {ICash} from "../core/ICash.sol";

enum BondState {
  Active,
  BackedOut,
  Exited
}

struct Bond {
  BondState state;
  uint256 amount;
  uint256 shares;
  uint256 start;
}

struct BondStorage {
  mapping(uint256 => Bond[]) bonds;
  Manager manager;
  ICreditAccount creditAccount;
  ICash cash;
  uint256 bondDuration;
}

interface IBondAccounting {
  /// @notice Creates a new bond
  /// @param user The owner of the bond
  /// @param amount The amount of CASH to bond
  function bond(uint256 user, uint256 amount) external;

  /// @notice Exits a bond
  /// @param user The owner of the bond
  /// @param index The index of the bond
  function exit(uint256 user, uint256 index) external;
}

interface IBondGetters {
  /// @notice Gets all the bonds for a user
  /// @param user The owner of the bonds
  /// @return List of bonds for the user
  function bonds(uint256 user) external view returns (Bond[] memory);

  /// @notice Gets the credit account contract
  /// @return The credit account contract
  function creditAccount() external view returns (ICreditAccount);

  /// @notice Gets the cash contract
  /// @return The cash contract
  function cash() external view returns (ICash);

  /// @notice Gets the bond duration
  /// @return The bond duration in seconds
  function bondDuration() external view returns (uint256);
}

interface IBondSetters {
  /// @notice Sets the bond duration
  /// @param duration The new bond duration
  function setBondDuration(uint256 duration) external;
}

// solhint-disable-next-line no-empty-blocks
interface IBond is
  IBondAccounting,
  IBondGetters,
  IBondSetters,
  IERC20,
  IAccessControl
{

}
