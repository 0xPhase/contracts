// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

import {IAavePool} from "../../../interfaces/aave/IAavePool.sol";

abstract contract AaveYieldV1Storage is YieldBase, ProxyInitializable, Element {
  IAavePool public aavePool;
  IERC20 public aToken;
  IERC20 public underlying;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the aave yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  /// @param aavePool_ The AavePool contract address
  function initializeAaveYieldV1(
    IDB db_,
    IERC20 asset_,
    IAavePool aavePool_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    aavePool = aavePool_;
    aToken = IERC20(aavePool_.getReserveData(address(asset_)).aTokenAddress);
    underlying = asset_;
  }
}
