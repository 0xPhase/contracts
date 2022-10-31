// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessRing is AccessControl {
  constructor(address manager) {
    _setupRole(DEFAULT_ADMIN_ROLE, manager);
  }

  function hasRole(string memory role, address account)
    public
    view
    returns (bool)
  {
    return hasRole(keccak256(bytes(role)), account);
  }
}
