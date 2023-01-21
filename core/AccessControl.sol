// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IDB} from "../db/IDB.sol";

interface IAccessControl {
  struct RoleData {
    mapping(address => bool) members;
    EnumerableSet.Bytes32Set keys;
    bytes32 adminRole;
  }

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

  /// @notice Grants the role to the account
  /// @param role The granted role
  /// @param account The account the role is granted to
  function grantRoleAccount(bytes32 role, address account) external;

  /// @notice Grants the role to the DB key
  /// @param role The granted role
  /// @param key The DB key the role is granted to
  function grantRoleKey(bytes32 role, bytes32 key) external;

  /// @notice Revokes the role from the account
  /// @param role The revoked role
  /// @param account The account the role is revoked from
  function revokeRoleAccount(bytes32 role, address account) external;

  /// @notice Revokes the role from the DB key
  /// @param role The revoked role
  /// @param key The DB key the role is revoked from
  function revokeRoleKey(bytes32 role, bytes32 key) external;

  /// @notice Removes the role from the message sender
  /// @param role The revoked role
  /// @param account The message sender
  function renounceRole(bytes32 role, address account) external;

  /// @notice Gets the DB contract
  /// @return The DB contract
  function db() external view returns (IDB);

  /// @notice Checks if the account has the role
  /// @param role The role the account is checked against
  /// @param account The
  /// @return If the account has the role
  function hasRole(bytes32 role, address account) external view returns (bool);

  /// @notice Gets the admin of the role
  /// @param role The role to get the admin for
  /// @return The admin of the role
  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

contract AccessControl is IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  IDB public db;
  mapping(bytes32 => RoleData) internal _roles;

  /// @notice Checks if the message sender has the role
  /// @param role The role to check against
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /// @inheritdoc	IAccessControl
  /// @custom:protected onlyRole(getRoleAdmin(role))
  function grantRoleAccount(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRoleAccount(role, account);
  }

  /// @inheritdoc	IAccessControl
  /// @custom:protected onlyRole(getRoleAdmin(role))
  function grantRoleKey(
    bytes32 role,
    bytes32 key
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRoleKey(role, key);
  }

  /// @inheritdoc	IAccessControl
  /// @custom:protected onlyRole(getRoleAdmin(role))
  function revokeRoleAccount(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRoleAccount(role, account);
  }

  /// @inheritdoc	IAccessControl
  /// @custom:protected onlyRole(getRoleAdmin(role))
  function revokeRoleKey(
    bytes32 role,
    bytes32 key
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRoleKey(role, key);
  }

  /// @inheritdoc	IAccessControl
  function renounceRole(bytes32 role, address account) public virtual override {
    require(
      account == msg.sender,
      "AccessControl: can only renounce roles for self"
    );

    _revokeRoleAccount(role, account);
  }

  /// @inheritdoc	ERC165
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @inheritdoc	IAccessControl
  function hasRole(
    bytes32 role,
    address account
  ) public view virtual override returns (bool) {
    RoleData storage roleData = _roles[role];

    if (roleData.members[account]) return true;

    bytes32 addr = bytes32(bytes20(account));
    uint256 length = roleData.keys.length();

    for (uint256 i = 0; i < length; i++) {
      if (db.hasPair(roleData.keys.at(i), addr)) return true;
    }

    return false;
  }

  /// @inheritdoc	IAccessControl
  function getRoleAdmin(
    bytes32 role
  ) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
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
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /// @notice Grants the role to the account
  /// @param role The granted role
  /// @param account The account the role is granted to
  function _grantRoleAccount(bytes32 role, address account) internal virtual {
    if (!_roles[role].members[account]) {
      _roles[role].members[account] = true;
      emit RoleAccountGranted(role, account, msg.sender);
    }
  }

  /// @notice Grants the role to the DB key
  /// @param role The granted role
  /// @param key The DB key the role is granted to
  function _grantRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_roles[role].keys.add(key)) {
      emit RoleKeyGranted(role, key, msg.sender);
    }
  }

  /// @notice Revokes the role from the account
  /// @param role The revoked role
  /// @param account The account the role is revoked from
  function _revokeRoleAccount(bytes32 role, address account) internal virtual {
    if (_roles[role].members[account]) {
      _roles[role].members[account] = false;
      emit RoleAccountRevoked(role, account, msg.sender);
    }
  }

  /// @notice Revokes the role from the DB key
  /// @param role The revoked role
  /// @param key The DB key the role is revoked from
  function _revokeRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_roles[role].keys.remove(key)) {
      emit RoleKeyRevoked(role, key, msg.sender);
    }
  }

  /// @notice Sets the DB contract address
  /// @param db_ The DB contract
  function _initializeDB(IDB db_) internal {
    db = db_;
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
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControl: account ",
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

  // solhint-disable-next-line ordering
  uint256[48] private __gap;
}
