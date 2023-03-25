// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {GenericYieldV1Storage} from "./IGenericYield.sol";
import {CallLib} from "../../../lib/CallLib.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract GenericYieldV1 is GenericYieldV1Storage {
  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    uint256 action = balanceGeneric.action;
    bytes memory data = balanceGeneric.data;

    if (action >= 0 && action <= 1) {
      bytes4 selector = abi.decode(data, (bytes4));

      if (action == 0) {
        data = abi.encodeWithSelector(selector);
      } else {
        data = abi.encodeWithSelector(selector, address(this));
      }

      bytes memory result = CallLib.viewFunc(target, data);
      uint256 balance = abi.decode(result, (uint256));

      return balance + asset.balanceOf(address(this));
    }

    revert("GenericYieldV1: Generic index for balance out of bounds");
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override {
    uint256 amount = asset.balanceOf(address(this));
    uint256 action = depositGeneric.action;
    bytes memory data = depositGeneric.data;

    asset.approve(address(target), amount);

    if (action >= 0 && action <= 4) {
      bytes4 selector = abi.decode(data, (bytes4));

      if (action == 0) {
        data = abi.encodeWithSelector(selector);
      } else if (action == 1) {
        data = abi.encodeWithSelector(selector, amount);
      } else if (action == 2) {
        data = abi.encodeWithSelector(selector, address(this));
      } else if (action == 3) {
        data = abi.encodeWithSelector(selector, amount, address(this));
      } else if (action == 4) {
        data = abi.encodeWithSelector(selector, address(this), amount);
      }

      CallLib.callFunc(target, data);
    }

    revert("GenericYieldV1: Generic index for deposit out of bounds");
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override {}

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance());
  }
}
