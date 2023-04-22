// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IPegToken} from "../../../peg/IPegToken.sol";
import {ShareLib} from "../../../lib/ShareLib.sol";
import {IBond} from "../../../bond/IBond.sol";
import {IOracle} from "../../IOracle.sol";

contract CashOracle is IOracle {
  IPegToken public immutable cash;
  IBond public immutable bond;

  /// @notice Initializes the Cash Oracle contract
  /// @param cash_ The Cash contract
  /// @param bond_ The Bond contract
  constructor(IPegToken cash_, IBond bond_) {
    require(
      address(cash_) != address(0),
      "CashOracle: Cash cannot be 0 address"
    );

    require(
      address(bond_) != address(0),
      "CashOracle: Bond cannot be 0 address"
    );

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
        ShareLib.calculateAmount(
          1 ether,
          bond.totalSupply(),
          bond.totalBalance()
        );

    revert("CashOracle: Not a cash asset");
  }
}
