// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {CreditAccountV1Storage} from "./CreditAccountV1Storage.sol";
import {ICreditAccount, TransferInfo} from "./ICreditAccount.sol";

contract CreditAccountV1 is CreditAccountV1Storage {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc ICreditAccount
  function getAccount(address owner) external returns (uint256 tokenId) {
    if (balanceOf(owner) > 0) return tokenOfOwnerByIndex(owner, 0);

    _tokenIds.increment();
    tokenId = _tokenIds.current();

    _transferAllowed = true;
    _mint(owner, tokenId);

    emit CreditAccountCreated(msg.sender, tokenId);
  }

  /// @inheritdoc ICreditAccount
  function startTransfer(address to) external {
    require(to != address(0), "CreditAccountV1: Target address cannot be 0");

    require(
      balanceOf(msg.sender) > 0,
      "CreditAccountV1: No credit account on sender"
    );

    require(
      balanceOf(to) == 0,
      "CreditAccountV1: Target already has a credit account"
    );

    uint256 time = systemClock.time();
    uint256 token = tokenOfOwnerByIndex(msg.sender, 0);

    transfers[msg.sender] = TransferInfo({
      timestamp: time,
      token: token,
      to: to
    });

    address currentTo = transfers[msg.sender].to;

    if (currentTo != address(0)) {
      _transfersTo[currentTo].remove(msg.sender);
    }

    _transfersTo[to].add(msg.sender);

    emit TransferStarted(msg.sender, to, token, time);
  }

  /// @inheritdoc ICreditAccount
  function cancelTransfer() external {
    TransferInfo storage info = transfers[msg.sender];

    require(info.timestamp > 0, "CreditAccountV1: Transfer does not exist");

    emit TransferCancelled(msg.sender, info.to, info.token);

    _transfersTo[transfers[msg.sender].to].remove(msg.sender);

    transfers[msg.sender] = TransferInfo({
      timestamp: 0,
      token: 0,
      to: address(0)
    });
  }

  /// @inheritdoc ICreditAccount
  function acceptTransfer(address from) external {
    require(
      balanceOf(msg.sender) == 0,
      "CreditAccountV1: Target already has a credit account"
    );

    TransferInfo storage info = transfers[from];

    require(
      info.to == msg.sender,
      "CreditAccountV1: Target is not the message sender"
    );

    require(info.timestamp > 0, "CreditAccountV1: Transfer does not exist");

    require(
      info.timestamp + transferTime >= systemClock.time(),
      "CreditAccountV1: Transfer expired"
    );

    uint256 token = tokenOfOwnerByIndex(from, 0);

    if (info.token != token) {
      _transfersTo[msg.sender].remove(from);
      transfers[from] = TransferInfo({timestamp: 0, token: 0, to: address(0)});

      return;
    }

    _transferAllowed = true;
    _transfersTo[msg.sender].remove(from);
    transfers[from] = TransferInfo({timestamp: 0, token: 0, to: address(0)});

    _transfer(from, msg.sender, token);
  }

  /// @notice Sets the transfer time
  /// @param newTransferTime The new transfer time
  /// @custom:protected onlyOwner
  function setTransferTime(uint256 newTransferTime) external onlyOwner {
    transferTime = newTransferTime;
    emit TransferTimeSet(newTransferTime);
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

  /// @inheritdoc ICreditAccount
  function allTransfersTo(
    address to
  )
    external
    view
    returns (TransferInfo[] memory infos, address[] memory froms)
  {
    EnumerableSet.AddressSet storage set = _transfersTo[to];
    uint256 length = set.length();

    infos = new TransferInfo[](length);
    froms = new address[](length);

    for (uint256 i = 0; i < length; ) {
      froms[i] = set.at(i);
      infos[i] = transfers[froms[i]];

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc CreditAccountV1Storage
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override {
    require(_transferAllowed, "CreditAccountV1: Transfer not allowed");

    if (batchSize > 1) {
      revert("CreditAccountV1: Consecutive transfers not supported");
    }

    require(
      balanceOf(to) == 0,
      "CreditAccountV1: Target already has a credit account"
    );

    _transferAllowed = false;

    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }
}
