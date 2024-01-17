// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uin256 to a uint128, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint168
  function cast256to168(uint256 y) internal pure returns (uint168 z) {
    unchecked {
      // Explicit bounds check
      require((z = uint168(y)) == y, "SafeCast: cast256to168 overflow");
    }
  }
}
