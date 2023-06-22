// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IV3SwapRouter} from "../../../interfaces/uniswap/IV3SwapRouter.sol";
import {V3Constants} from "../../../interfaces/uniswap/V3Constants.sol";
import {IQuoterV2} from "../../../interfaces/uniswap/IQuoterV2.sol";
import {GMXYieldV1Storage} from "./IGMXYield.sol";
import {CallLib} from "../../../lib/CallLib.sol";
import {MathLib} from "../../../lib/MathLib.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract GMXYieldV1 is GMXYieldV1Storage {
  using SafeERC20 for IERC20;

  modifier harvest() {
    gmxRouter.compound();
    rewardTracker.claim(address(this));

    uint256 wethBalance = weth.balanceOf(address(this));

    if (wethBalance > 0) {
      weth.safeTransfer(address(router), wethBalance);

      router.exactInputSingle(
        IV3SwapRouter.ExactInputSingleParams({
          tokenIn: address(weth),
          tokenOut: address(asset),
          fee: fee,
          recipient: address(this),
          amountIn: V3Constants.CONTRACT_BALANCE,
          amountOutMinimum: 0,
          sqrtPriceLimitX96: 0
        })
      );
    }

    _;
  }

  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    uint256 wethBalance = weth.balanceOf(address(this)) +
      rewardTracker.claimable(address(this));

    bytes memory returnData = CallLib.viewFunc(
      address(quoter),
      abi.encodeWithSelector(
        IQuoterV2.quoteExactInputSingle.selector,
        IQuoterV2.QuoteExactInputSingleParams({
          tokenIn: address(weth),
          tokenOut: address(asset),
          fee: fee,
          amountIn: wethBalance,
          sqrtPriceLimitX96: 0
        })
      )
    );

    (uint256 amountOut, , , ) = abi.decode(
      returnData,
      (uint256, uint160, uint32, uint256)
    );

    return
      balanceTracker.depositBalances(address(this), address(asset)) +
      balanceTracker.claimable(address(this)) +
      amountOut +
      asset.balanceOf(address(this));
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override harvest {
    _deposit(0);
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override harvest {
    uint256 balance = asset.balanceOf(address(this));

    if (balance < amount) {
      uint256 toWithdraw = amount - balance;

      gmxRouter.unstakeGmx(
        MathLib.min(
          toWithdraw,
          balanceTracker.depositBalances(address(this), address(asset))
        )
      );
    } else {
      _deposit(amount);
    }
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance() * 2);
  }

  function _deposit(uint256 offset) internal {
    uint256 balance = asset.balanceOf(address(this)) - offset;

    if (balance > 0) {
      gmxRouter.stakeGmx(balance);
    }
  }
}
