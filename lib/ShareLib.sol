// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

/// @title Share Math Library
/// @author 0xPhase
/// @dev A library to calculate share math with
library ShareLib {
  /// @dev Calculate amount from shares
  /// @param shares Amount of vault shares
  /// @param totalShares Total shares for vault
  /// @param balance Total amount
  /// @return amount Calculated amount
  function calculateAmount(
    uint256 shares,
    uint256 totalShares,
    uint256 balance
  ) internal pure returns (uint256 amount) {
    if (totalShares == 0 || shares == 0) return 0;

    amount = (shares * balance) / totalShares;
  }

  /// @dev Calculate shares from amount
  /// @param amount Amount
  /// @param totalShares Total shares for vault
  /// @param balance Total amount
  /// @return shares Calculated shares
  function calculateShares(
    uint256 amount,
    uint256 totalShares,
    uint256 balance
  ) internal pure returns (uint256 shares) {
    if (totalShares == 0) return amount;
    if (balance == 0) return 0;

    return (amount * totalShares) / balance;
  }
}
