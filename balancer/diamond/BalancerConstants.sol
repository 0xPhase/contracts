// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

library BalancerConstants {
  bytes32 public constant BALANCER_STORAGE_SLOT =
    bytes32(uint256(keccak256("balancer.diamond.storage")) - 1);

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

  uint256 public constant APR_DEFAULT = 0.01 ether;
  uint256 public constant APR_MIN_TIME = 1 hours;
  uint256 public constant APR_DURATION = 14 days;
}
