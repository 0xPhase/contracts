// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {AaveYieldV1Storage} from "./IAaveYield.sol";
import {TestUSDC} from "../../test/TestUSDC.sol";
import {BaseYield} from "../base/BaseYield.sol";
import {BaseYield} from "../base/BaseYield.sol";
import {IVault} from "../../vault/IVault.sol";
import {Clock} from "../../misc/Clock.sol";
import {IDB} from "../../db/IDB.sol";
import {IYield} from "../IYield.sol";

contract AaveYieldV1 is AaveYieldV1Storage {
  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    return
      aToken.balanceOf(address(this)) + underlying.balanceOf(address(this));
  }

  /// @inheritdoc	BaseYield
  function _onDeposit(uint256, uint256, uint256) internal override {
    uint256 amount = underlying.balanceOf(address(this));

    underlying.approve(address(aavePool), amount);
    aavePool.deposit(address(underlying), amount, address(this), 0);
  }

  function _preWithdraw(uint256, uint256 amount) internal override {
    aavePool.withdraw(address(underlying), amount, address(this));
  }
}
