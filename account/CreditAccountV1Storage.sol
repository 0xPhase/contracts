// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount, TransferInfo} from "./ICreditAccount.sol";
import {ProxyOwnable} from "../proxy/utils/ProxyOwnable.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {Manager} from "../core/Manager.sol";
import {IDB} from "../db/IDB.sol";

abstract contract CreditAccountV1Storage is
  Initializable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  ERC721BurnableUpgradeable,
  ProxyInitializable,
  ProxyOwnable,
  ICreditAccount
{
  mapping(address => TransferInfo) public transfers;
  IDB public db;
  ISystemClock public systemClock;
  Manager public manager;
  uint256 public transferTime;

  mapping(address => EnumerableSet.AddressSet) internal _transfersTo;
  CountersUpgradeable.Counter internal _tokenIds;
  bool internal _transferAllowed;

  /// @notice Disables initialization on the target contract
  constructor() initializer {
    _disableInitialization();
  }

  /// @notice Initializes the credit account contract on version 1
  /// @param db_ The protocol DB
  /// @param initialTransferTime_ The initial transfer time
  function initializeCreditAccountV1(
    IDB db_,
    uint256 initialTransferTime_
  ) external initialize("v1") initializer {
    require(
      address(db_) != address(0),
      "CreditAccountV1Storage: DB cannot be 0 address"
    );

    __ERC721_init("Phase Credit Account", "CREDIT");
    __ERC721Enumerable_init();
    __ERC721Burnable_init();

    db = db_;
    systemClock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));
    manager = Manager(db_.getAddress("MANAGER"));
    transferTime = initialTransferTime_;

    emit TransferTimeSet(initialTransferTime_);
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
