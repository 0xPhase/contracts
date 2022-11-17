// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {TestUSDC} from "../../test/TestUSDC.sol";
import {BaseYield} from "../base/BaseYield.sol";
import {IVault} from "../../vault/IVault.sol";
import {Clock} from "../../misc/Clock.sol";
import {IDB} from "../../db/IDB.sol";

contract MockYield is BaseYield, Clock {
  uint256 public yieldRate;
  uint256 public lastTick;

  constructor(
    IDB db_,
    IVault vault_,
    uint256 yieldRate_
  ) {
    _initializeSimpleYield(db_, vault_);
    _updateTime();

    yieldRate = yieldRate_;
    lastTick = time();
  }

  function totalBalance() public view override returns (uint256) {
    return asset.balanceOf(address(this)) + _yieldCreated();
  }

  function _preDeposit(uint256, uint256) internal override {
    _createYield();
  }

  function _preWithdraw(uint256, uint256) internal override {
    _createYield();
  }

  function _createYield() internal {
    uint256 amount = _yieldCreated();

    if (amount == 0) return;

    TestUSDC(address(asset)).mintAny(address(this), amount);
    _updateTime();
  }

  function _yieldCreated() internal view returns (uint256) {
    uint256 difference = time() - lastTick;

    if (difference == 0) return 0;

    return
      (asset.balanceOf(address(this)) * difference * yieldRate) /
      (365.25 days * 1 ether);
  }
}
