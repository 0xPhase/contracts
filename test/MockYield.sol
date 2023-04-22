// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {YieldBase} from "../yield/yields/base/YieldBase.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {IVault} from "../vault/IVault.sol";
import {TestUSDC} from "./TestUSDC.sol";
import {IDB} from "../db/IDB.sol";

contract MockYield is YieldBase {
  ISystemClock public systemClock;
  uint256 public yieldRate;
  uint256 public lastTick;

  constructor(IERC20 asset_, uint256 yieldRate_, IDB db_) {
    systemClock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));

    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    yieldRate = yieldRate_;
    lastTick = systemClock.time();
  }

  function totalBalance() public view override returns (uint256) {
    return asset.balanceOf(address(this)) + _yieldCreated(0);
  }

  function _onDeposit(uint256 amount) internal override {
    _createYield(amount);
  }

  function _onWithdraw(uint256) internal override {
    _createYield(0);
  }

  function _onFullWithdraw() internal override {
    _createYield(0);
  }

  function _createYield(uint256 offset) internal {
    uint256 amount = _yieldCreated(offset);

    if (amount == 0) return;

    lastTick = systemClock.time();

    TestUSDC(address(asset)).mintAny(address(this), amount);
  }

  function _yieldCreated(uint256 offset) internal view returns (uint256) {
    uint256 difference = systemClock.getTime() - lastTick;

    if (difference == 0) return 0;

    return
      ((asset.balanceOf(address(this)) - offset) * difference * yieldRate) /
      (365.25 days * 1 ether);
  }
}
