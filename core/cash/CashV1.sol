// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ICash, CashV1Storage} from "../ICash.sol";

contract CashV1 is CashV1Storage {
  /// @inheritdoc	ICash
  /// @custom:protected onlyRole(SNAPSHOT_ROLE)
  function snapshot() external override onlyRole(SNAPSHOT_ROLE) {
    _snapshot();
  }

  /// @inheritdoc	ICash
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function mintManager(
    address to,
    uint256 amount
  ) external override onlyRole(MANAGER_ROLE) {
    _mint(to, amount);
  }

  /// @inheritdoc	ICash
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function burnManager(
    address from,
    uint256 amount
  ) external override onlyRole(MANAGER_ROLE) {
    _burn(from, amount);
  }

  /// @inheritdoc	ICash
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function transferManager(
    address from,
    address to,
    uint256 amount
  ) external override onlyRole(MANAGER_ROLE) {
    _transfer(from, to, amount);
  }
}
