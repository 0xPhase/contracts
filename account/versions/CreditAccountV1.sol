// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {CreditAccountStorageV1, ICreditAccount} from "../ICreditAccount.sol";

contract CreditAccountV1 is CreditAccountStorageV1 {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /// @inheritdoc	ICreditAccount
  function createAccount()
    external
    override
    returns (uint256 tokenId, uint256 ownerIndex)
  {
    tokenId = _tokenIds.current();
    ownerIndex = balanceOf(msg.sender);

    _tokenIds.increment();
    _safeMint(msg.sender, tokenId);

    emit CreditAccountCreated(msg.sender, tokenId, ownerIndex);
  }
}
