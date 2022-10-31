// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";

interface ITreasury {
  struct TokenInfo {
    uint256 balance;
    bool set;
  }

  struct Cause {
    mapping(address => TokenInfo) token;
    address[] tokens;
  }

  event Donated(bytes32 indexed cause, address indexed token, uint256 amount);

  event Spent(
    bytes32 indexed cause,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  function donate(
    bytes32 cause,
    address token,
    uint256 amount
  ) external payable;

  function donate(
    string memory cause,
    address token,
    uint256 amount
  ) external payable;

  function spend(
    bytes32 cause,
    address token,
    uint256 amount,
    address to
  ) external;

  function spend(
    string memory cause,
    address token,
    uint256 amount,
    address to
  ) external;

  function increaseUnsafe(
    bytes32 cause,
    address token,
    uint256 amount
  ) external;

  function tokenBalance(address token) external view returns (uint256);

  function tokenBalance(bytes32 cause, address token)
    external
    view
    returns (uint256);

  function tokenBalance(string memory cause, address token)
    external
    view
    returns (uint256);

  function tokens() external view returns (address[] memory);

  function tokens(bytes32 cause) external view returns (address[] memory);

  function tokens(string memory cause) external view returns (address[] memory);

  // solhint-disable-next-line func-name-mixedcase
  function ETH_ADDRESS() external view returns (address);
}

abstract contract TreasuryStorageV1 is
  AccessControl,
  ProxyInitializable,
  ITreasury
{
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  mapping(bytes32 => Cause) internal _cause;
  Cause internal _globalCause;

  function initializeTreasuryV1(address manager) public initialize("v1") {
    _grantRole(DEFAULT_ADMIN_ROLE, manager);
  }
}
