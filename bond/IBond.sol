// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IAccessControl} from "../diamond/AccessControl/IAccessControl.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IERC20} from "../diamond/ERC20/IERC20.sol";
import {Manager} from "../core/Manager.sol";
import {ICash} from "../core/ICash.sol";

enum BondState {
  Active,
  BackedOut,
  Exited
}

struct Bond {
  BondState state;
  uint256 amount;
  uint256 shares;
  uint256 start;
}

struct BondStorage {
  mapping(uint256 => Bond[]) bonds;
  Manager manager;
  ICreditAccount creditAccount;
  ICash cash;
  uint256 bondDuration;
}

interface IBondAccounting {
  function bond(uint256 user, uint256 amount) external;

  function exit(uint256 user, uint256 index) external;
}

interface IBondGetters {
  function bonds(uint256 user) external view returns (Bond[] memory);

  function creditAccount() external view returns (ICreditAccount);

  function cash() external view returns (ICash);

  function bondDuration() external view returns (uint256);
}

interface IBondSetters {
  function setBondDuration(uint256 duration) external;
}

// solhint-disable-next-line no-empty-blocks
interface IBond is
  IBondAccounting,
  IBondGetters,
  IBondSetters,
  IERC20,
  IAccessControl
{

}
