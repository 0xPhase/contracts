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
  /// @notice Event emitted when a deposit is made
  /// @param asset The deposit asset
  /// @param user The user id
  /// @param amount The amount deposited
  /// @param shares The amount of shares given
  event Deposit(
    IERC20 indexed asset,
    uint256 indexed user,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when a withdraw is made
  /// @param asset The withdrawn asset
  /// @param user The user id
  /// @param amount The amount withdrawn
  /// @param shares The amount of shares taken
  event Withdraw(
    IERC20 indexed asset,
    uint256 indexed user,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when yield apr is set
  /// @param asset The asset
  /// @param apr The apr
  event YieldAPRSet(IERC20 indexed asset, uint256 apr);

  /// @notice Event emitted when a new yield source is added
  /// @param asset The asset
  /// @param yieldSrc The yield source
  event YieldAdded(IERC20 indexed asset, IYield indexed yieldSrc);

  /// @notice Event emitted when the yield state is set
  /// @param asset The asset
  /// @param yieldSrc The yield source
  /// @param state The yield state
  event YieldStateSet(
    IERC20 indexed asset,
    IYield indexed yieldSrc,
    bool state
  );

  /// @notice Event emitted when the performance fee is set
  /// @param fee The performance fee
  event PerformanceFeeSet(uint256 fee);

  /// @notice Deposits tokens for user
  /// @param asset The asset
  /// @param user The user id
  /// @param amount The amount of tokens deposited
  function deposit(IERC20 asset, uint256 user, uint256 amount) external;

  /// @notice Withdraws tokens from user
  /// @param asset The asset
  /// @param user The user id
  /// @param amount The amount of tokens withdrawn
  /// @return The real amount of tokens withdrawn
  function withdraw(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) external returns (uint256);

  /// @notice Fully withdraws tokens from user
  /// @param asset The asset
  /// @param user The user id
  /// @return The real amount of tokens withdrawn
  function fullWithdraw(IERC20 asset, uint256 user) external returns (uint256);

  /// @notice Returns the average apr for the asset
  /// @param asset The asset
  /// @return The average apr
  function assetAPR(IERC20 asset) external view returns (uint256);

  /// @notice Gets the time weighted average APR for the yield
  /// @param yieldSrc The yield source
  /// @return The time weighted average APR
  function twaa(IYield yieldSrc) external view returns (uint256);

  /// @notice Returns the total balance of the asset in the balancer
  /// @param asset The asset
  /// @return The total balance of the asset
  function totalBalance(IERC20 asset) external view returns (uint256);

  /// @notice Returns the balance of the asset for the user
  /// @param asset The asset
  /// @param user The user id
  /// @return The balance of the asset
  function balanceOf(
    IERC20 asset,
    uint256 user
  ) external view returns (uint256);

  /// @notice Returns the yield sources for the asset
  /// @param asset The asset
  /// @return The yield sources
  function yields(IERC20 asset) external view returns (Yield[] memory);

  /// @notice Returns all of the yield sources
  /// @return All of the yield sources
  function allYields() external view returns (address[] memory);

  /// @notice Gets the offsets in yield balances
  /// @param asset The asset
  /// @return arr The offset array
  /// @return totalNegative The total negative offsets
  /// @return totalPositive The total positive offsets
  function offsets(
    IERC20 asset
  )
    external
    view
    returns (Offset[] memory arr, uint256 totalNegative, uint256 totalPositive);

  /// @notice Returns the system clock
  /// @return The system clock
  function systemClock() external view returns (ISystemClock);

  /// @notice Returns the treasury
  /// @return The treasury
  function treasury() external view returns (ITreasury);

  /// @notice Returns the performance fee
  /// @return The performance fee
  function performanceFee() external view returns (uint256);

  /// @notice Returns the fee target account
  /// @return The fee target account
  function feeAccount() external view returns (uint256);
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

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));
    _grantRoleKey(DEV_ROLE, keccak256("DEV"));
    _grantRoleKey(VAULT_ROLE, keccak256("VAULT"));

    emit PerformanceFeeSet(initialPerformanceFee_);
  }
}
