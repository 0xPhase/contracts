// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {AccessControlStorage, RoleData} from "./IAccessControl.sol";
import {IDB} from "../../db/IDB.sol";

abstract contract AccessControlBase {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  bytes32 internal constant _ACCESS_CONTROL_STORAGE_SLOT =
    bytes32(uint256(keccak256("access.control.storage")) - 1);

  bytes32 internal constant _DEFAULT_ADMIN_ROLE = 0x00;

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

  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRoleAccount(role, account);
  }

  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = _getRoleAdmin(role);
    _acs().roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  function _grantRoleAccount(bytes32 role, address account) internal virtual {
    AccessControlStorage storage acs = _acs();

    if (!acs.roles[role].members[account]) {
      acs.roles[role].members[account] = true;
      emit RoleAccountGranted(role, account, msg.sender);
    }
  }

  function _grantRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_acs().roles[role].keys.add(key)) {
      emit RoleKeyGranted(role, key, msg.sender);
    }
  }

  function _revokeRoleAccount(bytes32 role, address account) internal virtual {
    AccessControlStorage storage acs = _acs();

    if (acs.roles[role].members[account]) {
      acs.roles[role].members[account] = false;
      emit RoleAccountRevoked(role, account, msg.sender);
    }
  }

  function _revokeRoleKey(bytes32 role, bytes32 key) internal virtual {
    if (_acs().roles[role].keys.remove(key)) {
      emit RoleKeyRevoked(role, key, msg.sender);
    }
  }

  function _setDB(IDB db_) internal {
    _acs().db = db_;
  }

  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, msg.sender);
  }

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

  function _hasRole(bytes32 role, address account)
    internal
    view
    virtual
    returns (bool)
  {
    AccessControlStorage storage acs = _acs();
    RoleData storage roleData = acs.roles[role];

    if (roleData.members[account]) return true;

    bytes32 addr = bytes32(bytes20(account));
    uint256 length = roleData.keys.length();

    for (uint256 i = 0; i < length; i++) {
      if (acs.db.hasPair(roleData.keys.at(i), addr)) return true;
    }

    return false;
  }

  function _getRoleAdmin(bytes32 role) internal view virtual returns (bytes32) {
    return _acs().roles[role].adminRole;
  }

  function _acs() internal pure returns (AccessControlStorage storage s) {
    bytes32 slot = _ACCESS_CONTROL_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
