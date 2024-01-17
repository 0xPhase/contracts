// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPegToken} from "../peg/IPegToken.sol";

interface ILiquidity {
  function cash() external view returns (IPegToken);

  function underlying() external view returns (IERC20);

  function balances(uint256 index) external view returns (uint256);

  function cashPrice(
    uint256 amountIn
  ) external view returns (uint256 amountOut);

  function underlyingPrice(
    uint256 amountIn
  ) external view returns (uint256 amountOut);

  struct MintInput {
    uint256 amountIn;
  }

  function mint(
    MintInput memory mintInput
  ) external returns (uint256 amountOut);

  struct BurnInput {
    uint256 shares;
  }

  function burn(
    BurnInput memory burnInput
  ) external returns (uint256 amountOut);

  struct SwapInput {
    bool isCash;
    uint200 amountIn;
    uint48 expiry;
    uint256 amountOutMin;
  }

  function swap(
    SwapInput memory swapInput
  ) external returns (uint256 amountOut);
}
