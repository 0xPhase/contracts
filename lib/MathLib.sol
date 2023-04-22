// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

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

  /// @notice Returns the value inside the range
  /// @param v The unsigned integer value
  /// @param minimum The minimum unsigned integer
  /// @param maximum The maximum unsigned integer
  /// @return The value inside the range
  function clamp(
    uint256 v,
    uint256 minimum,
    uint256 maximum
  ) internal pure returns (uint256) {
    if (v > maximum) return maximum;
    if (v < minimum) return minimum;
    return v;
  }

  /// @notice Returns the value inside the range
  /// @param v The integer value
  /// @param minimum The minimum integer
  /// @param maximum The maximum integer
  /// @return The value inside the range
  function clamp(
    int256 v,
    int256 minimum,
    int256 maximum
  ) internal pure returns (int256) {
    if (v > maximum) return maximum;
    if (v < minimum) return minimum;
    return v;
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
      uint256 diff;

      unchecked {
        diff = uint256(toDecimals - fromDecimals);
      }

      return amount * int256(uint256(10) ** diff);
    } else {
      uint256 diff;

      unchecked {
        diff = uint256(fromDecimals - toDecimals);
      }

      int256 power = int256(uint256(10) ** diff);

      unchecked {
        return amount / power;
      }
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
      uint256 diff;

      unchecked {
        diff = uint256(toDecimals - fromDecimals);
      }

      return amount * uint256(uint256(10) ** diff);
    } else {
      uint256 diff;

      unchecked {
        diff = uint256(fromDecimals - toDecimals);
      }

      uint256 power = uint256(uint256(10) ** diff);

      unchecked {
        return amount / power;
      }
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
