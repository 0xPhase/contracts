// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {IAavePool} from "../interfaces/aave/IAavePool.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {Manager} from "../core/Manager.sol";
import {ICash} from "../core/ICash.sol";
import {IDB} from "../db/IDB.sol";

interface IPSM {
  /// @notice Event emitted when the buy fee is set
  /// @param fee The buy fee
  event BuyFeeSet(uint256 fee);

  /// @notice Event emitted when the sell fee is set
  /// @param fee The sell fee
  event SellFeeSet(uint256 fee);

  /// @notice Event emitted when CASH is bought
  /// @param buyer The buyer address
  /// @param fee The amount of fee taken
  /// @param cashOut The amount of CASH bought
  /// @param otherIn The amount of other token sold
  event CashBought(
    address indexed buyer,
    uint256 indexed fee,
    uint256 cashOut,
    uint256 otherIn
  );

  /// @notice Event emitted when CASH is sold
  /// @param seller The seller address
  /// @param fee The amount of fee taken
  /// @param cashIn The amount of CASH sold
  /// @param otherOut The amount of other token bought
  event CashSold(
    address indexed seller,
    uint256 indexed fee,
    uint256 cashIn,
    uint256 otherOut
  );

  /// @notice Buys CASH in return for the other token
  /// @param amount Amount of other token to sell
  function buyCash(uint256 amount) external;

  /// @notice Sells CASH in return for the other token
  /// @param amount Amount of other token to buy
  function sellCash(uint256 amount) external;

  /// @notice Returns the total balance of the other token in the reserve
  /// @return The total balance of the other token
  function totalBalance() external view returns (uint256);

  /// @notice Returns the total amount traded in both directions
  /// @return The total amount traded
  function totalTraded() external view returns (uint256);

  /// @notice Returns the total amount of fees collected in both directions
  /// @return The total amount of fees collected
  function totalFees() external view returns (uint256);

  /// @notice Returns the Bond contract address
  /// @return The Bond contract address
  function bondAddress() external view returns (address);

  /// @notice Returns the buy fee
  /// @return The buy fee
  function buyFee() external view returns (uint256);

  /// @notice Returns the sell fee
  /// @return The sell fee
  function sellFee() external view returns (uint256);
}

abstract contract PSMV1Storage is AccessControl, ProxyInitializable, IPSM {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  ICash public cash;
  IAavePool public aavePool;
  IERC20 public aToken;
  IERC20 public underlying;
  address public bondAddress;
  uint256 public buyFee;
  uint256 public sellFee;
  uint256 public totalTraded;
  uint256 public totalFees;

  uint8 internal _underlyingDecimals;
  uint8 internal _aTokenDecimals;
  uint256 internal _lastUnderlyingBalance;

  // Constructor for the PSMV1Storage contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the PSM cotnract
  /// @param db_ The DB contract address
  /// @param aavePool_ The AavePool contract address
  /// @param underlying_ The underlying token address
  /// @param buyFee_ The initial buy fee
  /// @param sellFee_ The initial sell fee
  function initializePSMV1(
    IDB db_,
    IAavePool aavePool_,
    IERC20 underlying_,
    uint256 buyFee_,
    uint256 sellFee_
  ) external initialize("v1") {
    _initializeElement(db_);

    cash = ICash(db_.getAddress("CASH"));
    aavePool = aavePool_;
    aToken = IERC20(
      aavePool_.getReserveData(address(underlying_)).aTokenAddress
    );
    underlying = underlying_;
    bondAddress = db_.getAddress("BOND");
    buyFee = buyFee_;
    sellFee = sellFee_;

    _underlyingDecimals = ERC20(address(underlying_)).decimals();
    _aTokenDecimals = ERC20(address(aToken)).decimals();

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));

    emit BuyFeeSet(buyFee_);
    emit SellFeeSet(sellFee_);
  }
}
