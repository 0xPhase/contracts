// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ShareLib} from "../../../lib/ShareLib.sol";
import {ICash} from "../../../core/ICash.sol";
import {IBond} from "../../../bond/IBond.sol";
import {IOracle} from "../../IOracle.sol";

contract CashOracle is IOracle {
  ICash public cash;
  IBond public bond;

  constructor(ICash cash_, IBond bond_) {
    cash = cash_;
    bond = bond_;
  }

  /// @inheritdoc	IOracle
  function getPrice(
    address asset
  ) external view override returns (uint256 price) {
    if (asset == address(cash)) return 1 ether;

    if (asset == address(bond))
      return
        ShareLib.calculateAmount(1, bond.totalSupply(), bond.totalBalance());

    revert("CashOracle: Not a cash asset");
  }
}
