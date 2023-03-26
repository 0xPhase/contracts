// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {CreditAccountStorageV1, ICreditAccount} from "./ICreditAccount.sol";

contract CreditAccountV1 is CreditAccountStorageV1 {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /// @inheritdoc ICreditAccount
  function getAccount(address owner) external returns (uint256 tokenId) {
    if (balanceOf(owner) > 0) return tokenOfOwnerByIndex(owner, 0);

    _tokenIds.increment();
    tokenId = _tokenIds.current();
    _mint(owner, tokenId);

    emit CreditAccountCreated(msg.sender, tokenId);
  }

  /// @inheritdoc ICreditAccount
  function viewAccount(address owner) external view returns (uint256 tokenId) {
    if (balanceOf(owner) == 0) return 0;
    return tokenOfOwnerByIndex(owner, 0);
  }

  /// @inheritdoc ICreditAccount
  function index() external view returns (uint256) {
    return _tokenIds.current();
  }

  /// @inheritdoc CreditAccountStorageV1
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override {
    if (batchSize > 1) {
      revert("CreditAccountV1: Consecutive transfers not supported");
    }

    require(
      balanceOf(to) == 0,
      "CreditAccountV1: Target already has a credit account"
    );

    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }
}
