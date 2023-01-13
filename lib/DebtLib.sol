// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DebtLib {
  /// @dev Amount debt calculation formula
  /// @param totalAmount Total amount + debt
  /// @param deposit Deposit of address
  /// @param totalDeposit Total deposits
  function calculateDebt(
    uint256 totalAmount,
    uint256 deposit,
    uint256 totalDeposit
  ) internal pure returns (uint256) {
    return (deposit * totalAmount * 2) / totalDeposit;
  }

  /// @dev Amount calculation formula
  /// @param deposit User's deposit
  /// @param totalDeposit Total deposits
  /// @param totalAmount Total amount + debt
  /// @param debt User's debt
  function calculateAmount(
    uint256 deposit,
    uint256 totalDeposit,
    uint256 totalAmount,
    uint256 debt
  ) internal pure returns (uint256) {
    return (deposit * totalAmount) / totalDeposit - debt;
  }
}
