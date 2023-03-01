// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {AccessControlStorage, RoleData} from "./IAccessControl.sol";
import {ElementBase} from "../Element/ElementBase.sol";
import {IDB} from "../../db/IDB.sol";

abstract contract AccessControlBase is ElementBase {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  bytes32 internal constant _ACCESS_CONTROL_STORAGE_SLOT =
    bytes32(uint256(keccak256("access.control.storage")) - 1);

  bytes32 internal constant _DEFAULT_ADMIN_ROLE = 0x00;

  /// @notice Event emitted when the admin of a role changes
  /// @param role The role that changed
  /// @param previousAdminRole The previous admin role
  /// @param newAdminRole The new admin role
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /// @notice Event emitted when the role is granted to an account
  /// @param role The role that was granted
  /// @param account The account the role was granted to
  /// @param sender The message sender
  event RoleAccountGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /// @notice Event emitted when the role is revoked from an account
  /// @param role The role that was revoked
  /// @param account The account the role was revoked from
  /// @param sender The message sender
  event RoleAccountRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /// @notice Event emitted when the role is granted to a DB key
  /// @param role The role that was granted
  /// @param key The DB key the role was granted to
  /// @param sender The message sender
  event RoleKeyGranted(
    bytes32 indexed role,
    bytes32 indexed key,
    address indexed sender
  );

  /// @notice Event emitted when the role is revoked from a DB key
  /// @param role The role that was revoked
  /// @param key The DB key the role was revoked from
  /// @param sender The message sender
  event RoleKeyRevoked(
    bytes32 indexed role,
    bytes32 indexed key,
    address indexed sender
  );

  /// @notice Checks if the message sender has the role
  /// @param role The role to check against
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /// @notice Sets up an account with a role
  /// @param role The role to give to the account
  /// @param account The receiver account
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRoleAccount(role, account);
  }

  /// @notice Sets the admin of the role
  /// @param role The role to set the admin for
  /// @param adminRole The admin role
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = _getRoleAdmin(role);
    _acs().roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /// @notice Grants the role to the account
  /// @param role The granted role
  /// @param account The account the role is granted to
  function _grantRoleAccount(bytes32 role, address account) internal virtual {
    AccessControlStorage storage acs = _acs();

    if (!acs.roles[role].members[account]) {
      acs.roles[role].members[account] = true;
      emit RoleAccountGranted(role, account, msg.sender);
    }
  }

  /// @notice Grants the role to the DB key
  /// @param role The granted role
  /// @param key The DB key the role is granted to
  function _grantRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_acs().roles[role].keys.add(key)) {
      emit RoleKeyGranted(role, key, msg.sender);
    }
  }

  /// @notice Revokes the role from the account
  /// @param role The revoked role
  /// @param account The account the role is revoked from
  function _revokeRoleAccount(bytes32 role, address account) internal virtual {
    AccessControlStorage storage acs = _acs();

    if (acs.roles[role].members[account]) {
      acs.roles[role].members[account] = false;
      emit RoleAccountRevoked(role, account, msg.sender);
    }
  }

  /// @notice Revokes the role from the DB key
  /// @param role The revoked role
  /// @param key The DB key the role is revoked from
  function _revokeRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_acs().roles[role].keys.remove(key)) {
      emit RoleKeyRevoked(role, key, msg.sender);
    }
  }

  /// @notice Checks if the message sender has the role
  /// @param role The role to check against
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, msg.sender);
  }

  /// @notice Checks if the account has the role
  /// @param role The role to check against
  /// @param account The account to check for
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!_hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControlBase: account ",
            Strings.toHexString(uint160(account), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32),
            " for AccessControl ",
            Strings.toHexString(uint160(address(this)), 20)
          )
        )
      );
    }
  }

  /// @notice Checks if the account has the role
  /// @param role The role the account is checked against
  /// @param account The
  /// @return If the account has the role
  function _hasRole(
    bytes32 role,
    address account
  ) internal view virtual returns (bool) {
    AccessControlStorage storage acs = _acs();
    RoleData storage roleData = acs.roles[role];

    if (roleData.members[account]) return true;

    bytes32 addr = bytes32(bytes20(account));
    uint256 length = roleData.keys.length();

    for (uint256 i = 0; i < length; i++) {
      if (_db().hasPair(roleData.keys.at(i), addr)) return true;
    }

    return false;
  }

  /// @notice Gets the admin of the role
  /// @param role The role to get the admin for
  /// @return The admin of the role
  function _getRoleAdmin(bytes32 role) internal view virtual returns (bytes32) {
    return _acs().roles[role].adminRole;
  }

  /// @notice Returns the pointer to the access control storage
  /// @return s Access control storage pointer
  function _acs() internal pure returns (AccessControlStorage storage s) {
    bytes32 slot = _ACCESS_CONTROL_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
