// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {Manager} from "../core/Manager.sol";

interface ICreditAccount {
  event CreditAccountCreated(
    address indexed creator,
    uint256 tokenId,
    uint256 ownerIndex
  );

  function createAccount()
    external
    returns (uint256 tokenId, uint256 ownerIndex);
}

abstract contract CreditAccountStorageV1 is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  ProxyInitializable,
  ICreditAccount
{
  Manager public manager;

  CountersUpgradeable.Counter internal _tokenIds;

  function initializeCreditAccountV1(address manager_)
    external
    initialize("v1")
    initializer
  {
    __ERC721_init("Phase Credit Account", "CREDIT");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();

    manager = Manager(manager_);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}
