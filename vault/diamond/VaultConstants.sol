// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library VaultConstants {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  bytes32 public constant REBATE_CAUSE = keccak256("REBATE_CAUSE");
  bytes32 public constant PROTOCOL_CAUSE = keccak256("PROTOCOL_CAUSE");

  bytes32 public constant TREASURY_FEE = keccak256("TREASURY_FEE");
  bytes32 public constant REBATE_FEE = keccak256("REBATE_FEE");
  bytes32 public constant LIQUIDATION_FEE = keccak256("LIQUIDATION_FEE");
  bytes32 public constant STEP_MIN_DEPOSIT = keccak256("STEP_MIN_DEPOSIT");
}
