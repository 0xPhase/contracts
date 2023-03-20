// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {Manager} from "../core/Manager.sol";
import {IDB} from "../db/IDB.sol";

interface ICreditAccount {
  /// @notice Event emitted when a credit account is created
  /// @param creator The account that created the credit account
  /// @param tokenId The id of the created account
  event CreditAccountCreated(address indexed creator, uint256 tokenId);

  /// @notice Gets or creates the user's account
  /// @return tokenId The id of the account
  function getAccount(address owner) external returns (uint256 tokenId);

  /// @notice Gets the user's account or returns 0 if no account present
  /// @return tokenId The id of the account
  function viewAccount(address owner) external view returns (uint256 tokenId);
}

abstract contract CreditAccountStorageV1 is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  ProxyInitializable,
  ICreditAccount
{
  IDB public db;
  Manager public manager;

  CountersUpgradeable.Counter internal _tokenIds;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the credit account contract on version 1
  /// @param db_ The protocol DB
  function initializeCreditAccountV1(
    IDB db_
  ) external initialize("v1") initializer {
    __ERC721_init("Phase Credit Account", "CREDIT");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();

    db = db_;
    manager = Manager(db_.getAddress("MANAGER"));
  }

  // The following functions are overrides required by Solidity.

  /// @inheritdoc	ERC721Upgradeable
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /// @inheritdoc	ERC721Upgradeable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }
}
