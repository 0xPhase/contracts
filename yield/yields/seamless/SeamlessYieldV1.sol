// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SeamlessYieldV1Storage} from "./ISeamlessYield.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract SeamlessYieldV1 is SeamlessYieldV1Storage {
  using SafeERC20 for IERC20;

  modifier harvest() {
    address[] memory assets = new address[](1);
    assets[0] = address(aToken);

    rewards.claimAllRewardsToSelf(assets);

    IERC20 seam = IERC20(address(sellRoute[0].from));
    uint256 sellBalance = seam.balanceOf(address(this));

    if (sellBalance > 0.025 ether) {
      seam.safeApprove(address(router), sellBalance);

      router.swapExactTokensForTokens(
        sellBalance,
        0,
        sellRoute,
        address(this),
        block.timestamp
      );
    }

    _;
  }

  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256 balance) {
    address[] memory assets = new address[](1);
    assets[0] = address(aToken);

    IERC20 seam = IERC20(address(sellRoute[0].from));
    uint256 seamBalance = rewards.getUserRewards(
      assets,
      address(this),
      address(seam)
    ) + seam.balanceOf(address(this));

    balance = aToken.balanceOf(address(this)) + asset.balanceOf(address(this));

    if (seamBalance > 0.01 ether) {
      uint256[] memory amounts = router.getAmountsOut(seamBalance, sellRoute);

      balance += (amounts[amounts.length - 1] * 99) / 100;
    }
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override harvest {
    _deposit(0);
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override harvest {
    uint256 balance = asset.balanceOf(address(this));

    if (balance > amount) {
      unchecked {
        _deposit(balance - amount);
      }
    } else if (amount > balance) {
      unchecked {
        aavePool.withdraw(address(asset), amount - balance, address(this));
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
      asset.safeApprove(address(aavePool), amount);

      try aavePool.supply(address(asset), amount, address(this), 0) {} catch {
        asset.safeApprove(address(aavePool), 0);
      }
    }
  }
}
