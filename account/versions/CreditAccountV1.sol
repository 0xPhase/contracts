// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {CreditAccountStorageV1} from "../ICreditAccount.sol";

contract CreditAccountV1 is CreditAccountStorageV1 {
  using CountersUpgradeable for CountersUpgradeable.Counter;

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
