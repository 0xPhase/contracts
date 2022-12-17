// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IDB} from "../../db/IDB.sol";

struct RoleData {
  mapping(address => bool) members;
  EnumerableSet.Bytes32Set keys;
  bytes32 adminRole;
}

struct AccessControlStorage {
  IDB db;
  mapping(bytes32 => RoleData) roles;
}

interface IAccessControl {
  function grantRoleAccount(bytes32 role, address account) external;

  function grantRoleKey(bytes32 role, bytes32 key) external;

  function revokeRoleAccount(bytes32 role, address account) external;

  function revokeRoleKey(bytes32 role, bytes32 key) external;

  function renounceRole(bytes32 role, address account) external;

  function db() external view returns (IDB);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}
