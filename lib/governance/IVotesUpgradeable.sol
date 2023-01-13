// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVotesUpgradeable {
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  function delegate(address delegatee) external;

  function delegateBySig(
    address delegator,
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    bytes memory sig
  ) external;

  function getVotes(address account) external view returns (uint256);

  function getPastVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint256);

  function getPastTotalSupply(uint256 blockNumber)
    external
    view
    returns (uint256);

  function delegates(address account) external view returns (address);
}
