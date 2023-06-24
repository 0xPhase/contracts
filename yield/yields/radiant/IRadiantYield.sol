// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

import {IRadiantLendingPool} from "../../../interfaces/radiant/IRadiantLendingPool.sol";

abstract contract RadiantYieldV1Storage is
  YieldBase,
  ProxyInitializable,
  Element
{
  IRadiantLendingPool public radiantPool;
  IERC20 public aToken;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the radiant yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  /// @param radiantPool_ The Radiant pool contract address
  function initializeRadiantYieldV1(
    IDB db_,
    IERC20 asset_,
    IRadiantLendingPool radiantPool_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    address aTokenAddress = radiantPool_
      .getReserveData(address(asset_))
      .aTokenAddress;

    require(
      aTokenAddress != address(0),
      "RadiantYieldV1Storage: AToken is zero address"
    );

    radiantPool = radiantPool_;
    aToken = IERC20(aTokenAddress);
  }
}
