// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MathLib {
  /// @notice Returns the smaller unsigned integer
  /// @param a The first unsigned integer
  /// @param b The second unsigned integer
  /// @return The smaller unsigned integer
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) return b;
    return a;
  }

  /// @notice Returns the bigger unsigned integer
  /// @param a The first unsigned integer
  /// @param b The second unsigned integer
  /// @return The bigger unsigned integer
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) return a;
    return b;
  }

  /// @notice Scales an integer from a decimal to another one
  /// @param amount The original amount
  /// @param fromDecimals The original decimals
  /// @param toDecimals The target decimals
  /// @return The resulting integer
  function scaleAmount(
    int256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
  ) internal pure returns (int256) {
    if (fromDecimals == toDecimals) {
      return amount;
    } else if (fromDecimals < toDecimals) {
      return amount * int256(uint256(10) ** uint256(toDecimals - fromDecimals));
    } else {
      return amount / int256(uint256(10) ** uint256(fromDecimals - toDecimals));
    }
  }

  /// @notice Scales an unsigned integer from a decimal to another one
  /// @param amount The original amount
  /// @param fromDecimals The original decimals
  /// @param toDecimals The target decimals
  /// @return The resulting unsigned integer
  function scaleAmount(
    uint256 amount,
    uint8 fromDecimals,
    uint8 toDecimals
  ) internal pure returns (uint256) {
    if (fromDecimals == toDecimals) {
      return amount;
    } else if (fromDecimals < toDecimals) {
      return
        amount * uint256(uint256(10) ** uint256(toDecimals - fromDecimals));
    } else {
      return
        amount / uint256(uint256(10) ** uint256(fromDecimals - toDecimals));
    }
  }

  /// @notice Returns a positive unsigned integer or 0
  /// @param number The signed integer number
  /// @return The resulting positive or 0 unsigned integer
  function onlyPositive(int256 number) internal pure returns (uint256) {
    if (number >= 0) {
      return uint256(number);
    } else {
      return 0;
    }
  }
}
