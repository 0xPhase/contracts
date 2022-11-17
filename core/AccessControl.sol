// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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

  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  event RoleAccountGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  event RoleAccountRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  event RoleKeyGranted(
    bytes32 indexed role,
    bytes32 indexed key,
    address indexed sender
  );

  event RoleKeyRevoked(
    bytes32 indexed role,
    bytes32 indexed key,
    address indexed sender
  );

  function grantRoleAccount(bytes32 role, address account) external;

  function grantRoleKey(bytes32 role, bytes32 key) external;

  function revokeRoleAccount(bytes32 role, address account) external;

  function revokeRoleKey(bytes32 role, bytes32 key) external;

  function renounceRole(bytes32 role, address account) external;

  function db() external view returns (IDB);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

contract AccessControl is IAccessControl, ERC165 {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  IDB public db;
  mapping(bytes32 => RoleData) internal _roles;

  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  function grantRoleAccount(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _grantRoleAccount(role, account);
  }

  function grantRoleKey(bytes32 role, bytes32 key)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _grantRoleKey(role, key);
  }

  function revokeRoleAccount(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _revokeRoleAccount(role, account);
  }

  function revokeRoleKey(bytes32 role, bytes32 key)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
    _revokeRoleKey(role, key);
  }

  function renounceRole(bytes32 role, address account) public virtual override {
    require(
      account == msg.sender,
      "AccessControl: can only renounce roles for self"
    );

    _revokeRoleAccount(role, account);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function hasRole(bytes32 role, address account)
    public
    view
    virtual
    override
    returns (bool)
  {
    RoleData storage roleData = _roles[role];

    if (roleData.members[account]) return true;

    bytes32 addr = bytes32(bytes20(account));
    uint256 length = roleData.keys.length();

    for (uint256 i = 0; i < length; i++) {
      if (db.hasPair(roleData.keys.at(i), addr)) return true;
    }

    return false;
  }

  function getRoleAdmin(bytes32 role)
    public
    view
    virtual
    override
    returns (bytes32)
  {
    return _roles[role].adminRole;
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRoleAccount(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  function _grantRoleAccount(bytes32 role, address account) internal virtual {
    if (!_roles[role].members[account]) {
      _roles[role].members[account] = true;
      emit RoleAccountGranted(role, account, msg.sender);
    }
  }

  function _grantRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_roles[role].keys.add(key)) {
      emit RoleKeyGranted(role, key, msg.sender);
    }
  }

  function _revokeRoleAccount(bytes32 role, address account) internal virtual {
    if (_roles[role].members[account]) {
      _roles[role].members[account] = false;
      emit RoleAccountRevoked(role, account, msg.sender);
    }
  }

  function _revokeRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_roles[role].keys.remove(key)) {
      emit RoleKeyRevoked(role, key, msg.sender);
    }
  }

  function _setDB(IDB db_) internal {
    db = db_;
  }

  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, msg.sender);
  }

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
