// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20PermitUpgradeable {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes memory sig
  ) external;

  function nonces(address owner) external view returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}
