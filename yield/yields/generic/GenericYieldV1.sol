// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {GenericYieldV1Storage} from "./IGenericYield.sol";
import {ShareLib} from "../../../lib/ShareLib.sol";
import {MathLib} from "../../../lib/MathLib.sol";
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
    } else if (action >= 2 && action <= 3) {
      bytes4 selector = abi.decode(data, (bytes4));
      uint256 pps = _pricePerShare();

      if (action == 2) {
        data = abi.encodeWithSelector(selector);
      } else {
        data = abi.encodeWithSelector(selector, address(this));
      }

      bytes memory result = CallLib.viewFunc(target, data);
      uint256 shares = abi.decode(result, (uint256));

      return ((shares * pps) / 1 ether) + asset.balanceOf(address(this));
    }

    revert("GenericYieldV1: Generic index for balance out of bounds");
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256 amount) internal override {
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
  function _onWithdraw(uint256 amount) internal override {
    uint256 action = withdrawGeneric.action;
    bytes memory data = withdrawGeneric.data;

    if (action >= 0 && action <= 5) {
      if (action == 0) {
        bytes4 selector = abi.decode(data, (bytes4));
        data = abi.encodeWithSelector(selector);
      } else if (action == 1) {
        bytes4 selector = abi.decode(data, (bytes4));
        data = abi.encodeWithSelector(selector, 2 ** 160);
      } else if (action == 2) {
        bytes4 selector = abi.decode(data, (bytes4));
        uint256 currentBalance = asset.balanceOf(address(this));

        data = abi.encodeWithSelector(
          selector,
          totalBalance() - currentBalance
        );
      } else if (action >= 3 && action <= 4) {
        bytes4 selector = abi.decode(data, (bytes4));
        uint256 shares;

        if (action == 3) {
          (, bytes4 shareSelector) = abi.decode(data, (bytes4, bytes4));

          bytes memory result = CallLib.viewFunc(
            target,
            abi.encodeWithSelector(shareSelector)
          );

          shares = abi.decode(result, (uint256));
        } else {
          uint256 balance = totalBalance();
          uint256 pps = _pricePerShare();
          uint256 currentBalance = asset.balanceOf(address(this));

          shares = ((balance - currentBalance) * 1 ether) / pps;
        }

        data = abi.encodeWithSelector(selector, shares);
      }
    } else {
      revert("GenericYieldV1: Generic index for withdraw out of bounds");
    }

    CallLib.callFunc(target, data);

    uint256 rawBalance = asset.balanceOf(address(this));
    uint256 finalBalance = rawBalance - MathLib.min(rawBalance, amount);

    if (finalBalance > 0) {
      _onDeposit(finalBalance);
    }
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(2 ** 160);
  }

  function _pricePerShare() internal view returns (uint256) {
    uint256 action = shareGeneric.action;
    bytes memory data = shareGeneric.data;

    if (action == 0) {
      bytes4 selector = abi.decode(data, (bytes4));

      return
        abi.decode(
          CallLib.viewFunc(target, abi.encodeWithSelector(selector)),
          (uint256)
        );
    } else if (action == 1) {
      (bytes4 shareSelector, bytes4 balanceSelector) = abi.decode(
        data,
        (bytes4, bytes4)
      );

      bytes memory shareResult = CallLib.viewFunc(
        target,
        abi.encodeWithSelector(shareSelector)
      );

      bytes memory balanceResult = CallLib.viewFunc(
        target,
        abi.encodeWithSelector(balanceSelector)
      );

      return
        ShareLib.calculateAmount(
          1 ether,
          abi.decode(shareResult, (uint256)),
          abi.decode(balanceResult, (uint256))
        );
    }

    revert("GenericYieldV1: Generic index for share out of bounds");
  }
}
