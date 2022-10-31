// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title Share Math Library
/// @author 0xPhase
/// @dev A library to calculate share math with
library ShareLib {
  /// @dev Calculate amount from shares
  /// @param _shares Amount of vault shares
  /// @param _totalShares Total shares for vault
  /// @param _balance Total amount
  /// @return _amount Calculated amount
  function calculateAmount(
    uint256 _shares,
    uint256 _totalShares,
    uint256 _balance
  ) internal pure returns (uint256 _amount) {
    _amount = (_shares * _balance) / _totalShares;
  }

  /// @dev Calculate shares from amount
  /// @param _amount Amount
  /// @param _totalShares Total shares for vault
  /// @param _balance Total amount
  /// @return _shares Calculated shares
  function calculateShares(
    uint256 _amount,
    uint256 _totalShares,
    uint256 _balance
  ) internal pure returns (uint256 _shares) {
    return (_amount * _totalShares) / _balance;
  }
}
