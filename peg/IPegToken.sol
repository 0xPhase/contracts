// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20SnapshotUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20PermitUpgradeable} from "../lib/token/ERC20/ERC20PermitUpgradeable.sol";
import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {IDB} from "../db/IDB.sol";

interface IPegToken {
  /// @notice Takes a snapshot of the current token state
  function snapshot() external;

  /// @notice Mints tokens for the manager
  /// @param to The address to mint tokens to
  /// @param amount The amount of tokens to mint
  function mintManager(address to, uint256 amount) external;

  /// @notice Burns tokens for the manager
  /// @param from The address to burn tokens from
  /// @param amount The amount of tokens to burn
  function burnManager(address from, uint256 amount) external;

  /// @notice Transfers tokens for the manager
  /// @param from The address to transfer the tokens from
  /// @param to The address to transfer the tokens to
  /// @param amount The amount of tokens to transfer
  function transferManager(address from, address to, uint256 amount) external;
}

abstract contract PegTokenV1Storage is
  IPegToken,
  Initializable,
  ProxyInitializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  ERC20SnapshotUpgradeable,
  ERC20PermitUpgradeable,
  AccessControl
{
  bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the peg token contract on version 1
  /// @param db_ The protocol DB
  function initializePegTokenV1(
    IDB db_,
    string memory name_,
    string memory symbol_
  ) external initialize("v1") initializer {
    string memory fullName = string.concat("Phase ", name_);

    __ERC20_init(fullName, symbol_);
    __ERC20Burnable_init();
    __ERC20Snapshot_init();
    __ERC20Permit_init(fullName, db_);

    _initializeElement(db_);

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(SNAPSHOT_ROLE, keccak256("DEV"));
    _grantRoleKey(MANAGER_ROLE, keccak256("VAULT"));
    _grantRoleKey(MANAGER_ROLE, keccak256("PSM"));
    _grantRoleKey(MANAGER_ROLE, keccak256("BOND"));
  }

  // The following functions are overrides required by Solidity.

  /// @inheritdoc	ERC20Upgradeable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}