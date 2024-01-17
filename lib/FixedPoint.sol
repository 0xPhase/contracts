// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeCast} from "./SafeCast.sol";

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint {
  uint256 internal constant Q128 = 1 << OFFSET;
  uint256 internal constant OFFSET = 32;

  function mul(uint256 x, uint256 y) internal pure returns (uint256) {
    return (x * y) >> OFFSET;
  }

  function div(uint256 x, uint256 y) internal pure returns (uint256) {
    return (x << OFFSET) / y;
  }

  function pow(uint256 x, uint16 n) internal pure returns (uint256 a) {
    if (n == 0) return 0;

    a = x;

    for (; n > 1; n--) {
      a = mul(a, x);
    }
  }

  function q128(uint256 x) internal pure returns (uint256) {
    return x << OFFSET;
  }

  function toQ128(
    uint256 value,
    uint8 decimals
  ) internal pure returns (uint256) {
    uint256 d = 10 ** uint256(decimals);

    return ((value / d) << OFFSET) + (((value % d) * Q128) / d);
  }

  function fromQ128(
    uint256 value,
    uint8 decimals
  ) internal pure returns (uint256) {
    uint256 d = 10 ** uint256(decimals);

    return (value >> OFFSET) * d + (((value & (Q128 - 1)) * d) / Q128);
  }
}
