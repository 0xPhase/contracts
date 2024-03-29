// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {IBondGetters, Bond} from "./IBond.sol";
import {Manager} from "../core/Manager.sol";
import {BondBase} from "./BondBase.sol";

contract BondGettersFacet is BondBase, IBondGetters {
  /// @inheritdoc	IBondGetters
  function bonds(
    uint256 user
  ) external view override returns (Bond[] memory result) {
    Bond[] storage list = _s().bonds[user];
    uint256 length = list.length;

    result = new Bond[](length);

    for (uint256 i = 0; i < length; ) {
      result[i] = list[i];

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc	IBondGetters
  function manager() external view override returns (Manager) {
    return _s().manager;
  }

  /// @inheritdoc	IBondGetters
  function creditAccount() external view override returns (ICreditAccount) {
    return _s().creditAccount;
  }

  /// @inheritdoc	IBondGetters
  function cash() external view override returns (IPegToken) {
    return _s().cash;
  }

  /// @inheritdoc	IBondGetters
  function bondDuration() external view override returns (uint256) {
    return _s().bondDuration;
  }

  /// @inheritdoc	IBondGetters
  function totalBalance() external view override returns (uint256) {
    return _totalBalance();
  }
}
