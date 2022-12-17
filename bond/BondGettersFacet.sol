// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IBondGetters, Bond} from "./IBond.sol";
import {BondBase} from "./BondBase.sol";
import {ICash} from "../core/ICash.sol";

contract BondGettersFacet is BondBase, IBondGetters {
  function bonds(uint256 user)
    external
    view
    override
    returns (Bond[] memory result)
  {
    Bond[] storage list = _s.bonds[user];
    uint256 length = list.length;

    result = new Bond[](length);

    for (uint256 i = 0; i < length; i++) {
      result[i] = list[i];
    }
  }

  function creditAccount() external view override returns (ICreditAccount) {
    return _s.creditAccount;
  }

  function cash() external view override returns (ICash) {
    return _s.cash;
  }

  function bondDuration() external view override returns (uint256) {
    return _s.bondDuration;
  }
}
