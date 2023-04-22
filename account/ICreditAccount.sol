// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ISystemClock} from "../clock/ISystemClock.sol";
import {Manager} from "../core/Manager.sol";
import {IDB} from "../db/IDB.sol";

struct TransferInfo {
  uint256 timestamp;
  uint256 token;
  address to;
}

interface ICreditAccount {
  /// @notice Event emitted when a credit account is created
  /// @param creator The account that created the credit account
  /// @param tokenId The id of the created account
  event CreditAccountCreated(address indexed creator, uint256 tokenId);

  /// @notice Event emitted when a transfer is started
  /// @param from The account initiating the transfer
  /// @param to The target account of the transfer
  /// @param timestamp The onchain timestamp when the transfer was started
  event TransferStarted(
    address indexed from,
    address indexed to,
    uint256 tokenId,
    uint256 timestamp
  );

  /// @notice Event emitted when a transfer is cancelled manually
  /// @param from The account initiating the transfer
  /// @param to The target account of the transfer
  event TransferCancelled(
    address indexed from,
    address indexed to,
    uint256 tokenId
  );

  /// @notice Event emitted when the transfer time is set
  /// @param newTransferTime The new transfer time
  event TransferTimeSet(uint256 newTransferTime);

  /// @notice Gets or creates the user's account
  /// @param owner The owner address
  /// @return tokenId The id of the account
  function getAccount(address owner) external returns (uint256 tokenId);

  /// @notice Initiates a token transfer to the `to` account
  /// @param to The target account
  function startTransfer(address to) external;

  /// @notice Cancels a potential transfer
  function cancelTransfer() external;

  /// @notice Accepts a pending transfer from `from` account
  /// @param from The originating address
  function acceptTransfer(address from) external;

  /// @notice Returns the DB contract
  /// @return The DB contract
  function db() external view returns (IDB);

  /// @notice Returns the System Clock contract
  /// @return The System Clock contract
  function systemClock() external view returns (ISystemClock);

  /// @notice Returns the Manager contract
  /// @return The Manager contract
  function manager() external view returns (Manager);

  /// @notice Returns the transfer for the from account
  /// @param from The account the transfer is from
  /// @return timestamp The time the transfer was initiated
  /// @return token The token to transfer
  /// @return to The target of the transfer
  function transfers(
    address from
  ) external view returns (uint256 timestamp, uint256 token, address to);

  function allTransfersTo(
    address to
  ) external view returns (TransferInfo[] memory infos, address[] memory froms);

  /// @notice Returns the transfer time
  /// @return The transfer time
  function transferTime() external view returns (uint256);

  /// @notice Returns the next token index
  /// @return The next token index
  function index() external view returns (uint256);

  /// @notice Gets the user's account or returns 0 if no account present
  /// @param owner The owner address
  /// @return tokenId The id of the account
  function viewAccount(address owner) external view returns (uint256 tokenId);
}
