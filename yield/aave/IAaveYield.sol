// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ProxyInitializable} from "../../proxy/utils/ProxyInitializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseYield} from "../base/BaseYield.sol";
import {IVault} from "../../vault/IVault.sol";
import {IDB} from "../../db/IDB.sol";

import {IAavePool} from "../../interfaces/aave/IAavePool.sol";

interface IAaveYield {}

abstract contract AaveYieldV1Storage is
  ProxyInitializable,
  BaseYield,
  IAaveYield
{
  IAavePool public aavePool;
  IERC20 public aToken;
  IERC20 public underlying;

  constructor() {
    _disableInitialization();
  }

  function initializeAaveYieldV1(
    IDB db_,
    IVault vault_,
    IAavePool aavePool_
  ) external initialize("v1") {
    _initializeSimpleYield(db_, vault_);

    IERC20 underlying_ = asset;

    aavePool = aavePool_;
    aToken = IERC20(
      aavePool_.getReserveData(address(underlying_)).aTokenAddress
    );
    underlying = underlying_;
  }
}
