// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20SnapshotUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20PermitUpgradeable} from "../lib/token/ERC20/ERC20PermitUpgradeable.sol";
import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {IDB} from "../db/IDB.sol";

interface ICash {
  function snapshot() external;

  function mintManager(address to, uint256 amount) external;

  function burnManager(address to, uint256 amount) external;
}

abstract contract CashV1Storage is
  ICash,
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

  function initializeCashV1(IDB db_) external initialize("v1") initializer {
    __ERC20_init("Phase Dollar", "CASH");
    __ERC20Burnable_init();
    __ERC20Snapshot_init();
    __ERC20Permit_init("Phase Dollar");

    _setDB(db_);

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(SNAPSHOT_ROLE, keccak256("DEV"));
    _grantRoleKey(MANAGER_ROLE, keccak256("VAULT"));
    _grantRoleKey(MANAGER_ROLE, keccak256("PSM"));
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
