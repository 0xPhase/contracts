// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {CashV1Storage} from "../ICash.sol";

contract CashV1 is CashV1Storage {
  function snapshot() external override onlyRole(SNAPSHOT_ROLE) {
    _snapshot();
  }

  function mintManager(address to, uint256 amount)
    external
    override
    onlyRole(MANAGER_ROLE)
  {
    _mint(to, amount);
  }

  function burnManager(address from, uint256 amount)
    external
    override
    onlyRole(MANAGER_ROLE)
  {
    _burn(from, amount);
  }
}
