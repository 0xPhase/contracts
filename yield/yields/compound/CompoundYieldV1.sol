// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICometExt} from "../../../interfaces/compound/comet/ICometExt.sol";
import {CompoundYieldV1Storage} from "./ICompoundYield.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract CompoundYieldV1 is CompoundYieldV1Storage {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    return comet.balanceOf(address(this)) + asset.balanceOf(address(this));
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
        _deposit(balance - amount);
      }
    } else if (amount > balance) {
      unchecked {
        comet.withdraw(address(asset), amount - balance);
      }
    }
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance());
  }

  function _deposit(uint256 offset) internal {
    uint256 amount = asset.balanceOf(address(this)) - offset;

    if (amount > 0) {
      asset.safeApprove(address(comet), amount);

      try comet.supply(address(asset), amount) {} catch {
        asset.safeApprove(address(comet), 0);
      }
    }
  }
}
