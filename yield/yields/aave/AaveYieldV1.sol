// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {AaveYieldV1Storage} from "./IAaveYield.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract AaveYieldV1 is AaveYieldV1Storage {
  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    return aToken.balanceOf(address(this)) + asset.balanceOf(address(this));
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override {
    uint256 amount = asset.balanceOf(address(this));

    asset.approve(address(aavePool), amount);
    aavePool.deposit(address(asset), amount, address(this), 0);
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override {
    aavePool.withdraw(address(asset), amount, address(this));
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance());
  }
}
