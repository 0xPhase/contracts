// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {ITreasury} from "../treasury/ITreasury.sol";
import {IYield} from "./IYield.sol";
import {IDB} from "../db/IDB.sol";

struct Asset {
  EnumerableSet.AddressSet yields;
  mapping(uint256 => uint256) shares;
  uint256 totalShares;
}

struct Yield {
  IYield yieldSrc;
  uint256 start;
  uint256 apr;
  uint256 lastUpdate;
  uint256 lastDeposit;
  bool state;
}

struct Offset {
  IYield yieldSrc;
  uint256 apr;
  uint256 offset;
  bool isPositive;
}

interface IBalancer {
  event YieldAPRSet(IERC20 indexed asset, uint256 timestamp, uint256 apr);

  event PerformanceFeeSet(uint256 apr);

  function deposit(IERC20 asset, uint256 user, uint256 amount) external;

  function withdraw(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) external returns (uint256);

  function fullWithdraw(IERC20 asset, uint256 user) external returns (uint256);

  function assetAPR(IERC20 asset) external view returns (uint256);

  /// @notice Gets the time weighted average APR for the yield
  /// @param yieldSrc The yield source
  /// @return The time weighted average APR
  function twaa(IYield yieldSrc) external view returns (uint256);

  function totalBalance(IERC20 asset) external view returns (uint256);

  function balanceOf(
    IERC20 asset,
    uint256 user
  ) external view returns (uint256);

  function yields(IERC20 asset) external view returns (Yield[] memory);

  function allYields() external view returns (address[] memory);

  function offsets(
    IERC20 asset
  )
    external
    view
    returns (Offset[] memory arr, uint256 totalNegative, uint256 totalPositive);
}

abstract contract BalancerV1Storage is
  IBalancer,
  ProxyInitializable,
  AccessControl
{
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

  uint256 public constant APR_DEFAULT = 0.01 ether;
  uint256 public constant APR_MIN_TIME = 0.2 days;
  uint256 public constant APR_DURATION = 14 days;

  mapping(IYield => Yield) internal _yield;
  mapping(IERC20 => Asset) internal _asset;
  EnumerableSet.AddressSet internal _assets;
  EnumerableSet.AddressSet internal _yields;

  ISystemClock public systemClock;
  ITreasury public treasury;
  uint256 public performanceFee;
  uint256 public feeAccount;

  /// @notice Initializes the balancer contract on version 1
  /// @param db_ The protocol DB
  function initializeBalancerV1(
    IDB db_,
    uint256 initialPerformanceFee_
  ) external initialize("v1") {
    systemClock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));
    treasury = ITreasury(db_.getAddress("TREASURY"));
    performanceFee = initialPerformanceFee_;

    feeAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT")).getAccount(
      db_.getAddress("MANAGER")
    );

    _initializeElement(db_);

    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));
    _grantRoleKey(DEV_ROLE, keccak256("DEV"));
    _grantRoleKey(VAULT_ROLE, keccak256("VAULT"));

    emit PerformanceFeeSet(initialPerformanceFee_);
  }
}
