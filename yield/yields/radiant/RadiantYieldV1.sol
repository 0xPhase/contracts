// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RadiantYieldV1Storage} from "./IRadiantYield.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract RadiantYieldV1 is RadiantYieldV1Storage {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    return aToken.balanceOf(address(this)) + asset.balanceOf(address(this));
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override {
    _deposit(0);
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override {
    uint256 balance = asset.balanceOf(address(this));

    if (balance > amount) {
      unchecked {
        _onDeposit(balance - amount);
      }
    } else if (amount > balance) {
      unchecked {
        radiantPool.withdraw(address(asset), amount - balance, address(this));
      }
    }
  }

  function _deposit(uint256 offset) internal {
    uint256 amount = asset.balanceOf(address(this)) - offset;
    asset.safeApprove(address(radiantPool), amount);
    radiantPool.deposit(address(asset), amount, address(this), 0);
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance());
  }
}
