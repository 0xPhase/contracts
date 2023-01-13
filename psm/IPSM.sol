// SPDX-License-Identifier: MIT
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
  event BuyFeeSet(uint256 indexed fee);

  event SellFeeSet(uint256 indexed fee);

  function buyCash(uint256 amount) external;

  function sellCash(uint256 amount) external;

  function totalBalance() external view returns (uint256);

  function totalTraded() external view returns (uint256);

  function totalFees() external view returns (uint256);

  function bondAddress() external view returns (address);

  function buyFee() external view returns (uint256);

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

  constructor() {
    _disableInitialization();
  }

  function initializePSMV1(
    IDB db_,
    IAavePool aavePool_,
    IERC20 underlying_,
    uint256 buyFee_,
    uint256 sellFee_
  ) external initialize("v1") {
    _initializeDB(db_);

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
