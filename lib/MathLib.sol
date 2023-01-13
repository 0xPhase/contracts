// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MathLib {
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) return b;
    return a;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) return a;
    return b;
  }

  function scaleAmount(
    int256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
  ) internal pure returns (int256) {
    if (fromDecimals == toDecimals) {
      return amount;
    }

    if (fromDecimals < toDecimals) {
      return amount * int256(uint256(10)**uint256(toDecimals - fromDecimals));
    } else if (fromDecimals > toDecimals) {
      return amount / int256(uint256(10)**uint256(fromDecimals - toDecimals));
    }

    return amount;
  }

  function scaleAmount(
    uint256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
  ) internal pure returns (uint256) {
    if (fromDecimals == toDecimals) {
      return amount;
    }

    if (fromDecimals < toDecimals) {
      return amount * uint256(uint256(10)**uint256(toDecimals - fromDecimals));
    } else if (fromDecimals > toDecimals) {
      return amount / uint256(uint256(10)**uint256(fromDecimals - toDecimals));
    }

    return amount;
  }
}
