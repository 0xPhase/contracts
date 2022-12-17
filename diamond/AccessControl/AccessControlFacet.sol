// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {AccessControlBase} from "./AccessControlBase.sol";
import {IAccessControl} from "./IAccessControl.sol";
import {IDB} from "../../db/IDB.sol";

contract AccessControlFacet is IAccessControl, AccessControlBase {
  function db() external view override returns (IDB) {
    return _acs().db;
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
      "AccessControlFacet: can only renounce roles for self"
    );

    _revokeRoleAccount(role, account);
  }

  function hasRole(bytes32 role, address account)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _hasRole(role, account);
  }

  function getRoleAdmin(bytes32 role)
    public
    view
    virtual
    override
    returns (bytes32)
  {
    return _getRoleAdmin(role);
  }
}
