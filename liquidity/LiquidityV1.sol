// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {LiquidityV1Storage} from "./LiquidityV1Storage.sol";
import {FixedPoint} from "../lib/FixedPoint.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {ShareLib} from "../lib/ShareLib.sol";
import {ILiquidity} from "./ILiquidity.sol";
import {MathLib} from "../lib/MathLib.sol";

contract LiquidityV1 is LiquidityV1Storage {
  using FixedPoint for uint256;
  using SafeERC20 for IERC20;

  uint256 internal constant DIFF_CHECK = 0x100000000000;

  function mint(
    ILiquidity.MintInput memory mintInput
  ) external override returns (uint256 amountOut) {
    require(
      mintInput.amountIn > 0,
      "LiquidityV1: Amount must be greater than 0"
    );

    underlying.safeTransferFrom(msg.sender, address(this), mintInput.amountIn);

    uint8 decimals = ERC20(address(underlying)).decimals();

    // x=(a*y)/b
    uint256 cashAmount = balances[0] == 0
      ? MathLib.scaleAmount(mintInput.amountIn, decimals, 18)
      : (balances[0] * mintInput.amountIn) / balances[1];

    cash.mintManager(address(this), cashAmount);

    amountOut = ShareLib.calculateShares(
      mintInput.amountIn,
      totalSupply(),
      balances[1]
    );

    balances[0] += cashAmount;
    balances[1] += mintInput.amountIn;

    _mint(msg.sender, amountOut);
  }

  function burn(
    ILiquidity.BurnInput memory burnInput
  ) external override returns (uint256 amountOut) {
    require(burnInput.shares > 0, "LiquidityV1: Shares must be greater than 0");

    amountOut = ShareLib.calculateAmount(
      burnInput.shares,
      totalSupply(),
      balances[1]
    );

    _burn(msg.sender, burnInput.shares);

    // x=(a*y)/b
    uint256 cashDiff = MathLib.min(
      (balances[0] * amountOut) / balances[1],
      balances[0]
    );

    balances[0] -= cashDiff;
    balances[1] -= amountOut;

    cash.burnManager(address(this), cashDiff);

    underlying.safeTransfer(msg.sender, amountOut);
  }

  function swap(
    ILiquidity.SwapInput memory swapInput
  ) external override returns (uint256 amountOut) {
    require(
      swapInput.amountIn > 0,
      "LiquidityV1: Amount must be greater than 0"
    );

    require(
      swapInput.expiry > _clock.time(),
      "LiquidityV1: Expiry must be greater than current timestamp"
    );

    amountOut = swapInput.isCash
      ? cashPrice(swapInput.amountIn)
      : underlyingPrice(swapInput.amountIn);

    require(
      amountOut >= swapInput.amountOutMin,
      "LiquidityV1: Insufficient output amount"
    );

    if (swapInput.isCash) {
      cash.transferManager(msg.sender, address(this), swapInput.amountIn);
      underlying.safeTransfer(msg.sender, amountOut);

      balances[0] += swapInput.amountIn;
      balances[1] -= amountOut;
    } else {
      underlying.safeTransferFrom(
        msg.sender,
        address(this),
        swapInput.amountIn
      );
      IERC20(address(cash)).safeTransfer(msg.sender, amountOut);

      balances[0] -= amountOut;
      balances[1] += swapInput.amountIn;
    }
  }

  function cashPrice(
    uint256 amountIn
  ) public view override returns (uint256 amountOut) {
    if (balances[0] == 0 || balances[1] == 0) return 0;

    uint8 decimals = ERC20(address(underlying)).decimals();
    uint256 a = balances[0].toQ128(18);
    uint256 b = balances[1].toQ128(decimals);

    uint256 i = amountIn.toQ128(18);
    uint256 d = _dx(a, b, i) * 50;
    uint256 l = d > b ? 0 : b - d;

    uint256 result = _find(a, b, i, b, l, _fnx);

    return (b - result).fromQ128(decimals);
  }

  function underlyingPrice(
    uint256 amountIn
  ) public view override returns (uint256 amountOut) {
    if (balances[0] == 0 || balances[1] == 0) return 0;

    uint8 decimals = ERC20(address(underlying)).decimals();
    uint256 a = balances[0].toQ128(18);
    uint256 b = balances[1].toQ128(decimals);

    uint256 i = amountIn.toQ128(decimals);
    uint256 d = _dy(a, b, i) * 50;
    uint256 l = d > a ? 0 : a - d;

    uint256 result = _find(a, b, i, a, l, _fny);

    return (a - result).fromQ128(18);
  }

  function _k(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b.pow(3)) + b.mul(a.pow(3));
  }

  function _find(
    uint256 a,
    uint256 b,
    uint256 effector,
    uint256 higher,
    uint256 lower,
    function(uint256, uint256, uint256, uint256)
      internal
      pure
      returns (uint256) fn
  ) internal pure returns (uint256) {
    uint256 k = _k(a, b);
    uint256 diff = k / 10_000_000;

    for (uint256 i = 0; i < 1024; ) {
      uint256 middle = (higher + lower) / 2;
      uint256 check = fn(a, b, effector, middle);

      if (check >= k && (check - k) <= diff) {
        return middle;
      } else if (check > k) {
        higher = middle;
      } else if (check < k) {
        lower = middle;
      }

      unchecked {
        i++;
      }
    }

    revert("LiquidityV1: Cannot find answer");
  }

  function _fnx(
    uint256 a,
    uint256,
    uint256 effector,
    uint256 application
  ) internal pure returns (uint256) {
    return _k(a + effector, application);
  }

  function _fny(
    uint256,
    uint256 b,
    uint256 effector,
    uint256 application
  ) internal pure returns (uint256) {
    return _k(application, b + effector);
  }

  function _dx(
    uint256 a,
    uint256 b,
    uint256 change
  ) internal pure returns (uint256) {
    return (b.mul(change)).div(a + change);
  }

  function _dy(
    uint256 a,
    uint256 b,
    uint256 change
  ) internal pure returns (uint256) {
    return (a.mul(change)).div(b + change);
  }
}
