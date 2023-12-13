// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {IRewardsController} from "../../../interfaces/seamless/IRewardsController.sol";
import {IAerodromeRouter} from "../../../interfaces/aerodrome/IAerodromeRouter.sol";
import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract SeamlessYieldV1Storage is
  YieldBase,
  ProxyInitializable,
  Element
{
  IPool public aavePool;
  IERC20 public aToken;
  IRewardsController public rewards;

  IAerodromeRouter public router;
  IAerodromeRouter.Route[] public sellRoute;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the seamless yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  /// @param aavePool_ The Aave pool contract address
  /// @param rewards_ The rewards distributor contract address
  /// @param router_ The Aerodrome router contract address
  /// @param sellPath_ The sell path to convert the yield asset to the base asset
  function initializeSeamlessYieldV1(
    IDB db_,
    IERC20 asset_,
    IPool aavePool_,
    IRewardsController rewards_,
    IAerodromeRouter router_,
    IAerodromeRouter.Route[] memory sellPath_
  ) external initialize("v1") {
    require(
      address(rewards_) != address(0),
      "SeamlessYieldV1Storage: Rewards Distributor address is zero"
    );

    require(
      address(router_) != address(0),
      "SeamlessYieldV1Storage: Router address is zero"
    );

    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    address aTokenAddress = aavePool_
      .getReserveData(address(asset_))
      .aTokenAddress;

    require(
      aTokenAddress != address(0),
      "SeamlessYieldV1Storage: AToken is zero address"
    );

    aavePool = aavePool_;
    aToken = IERC20(aTokenAddress);
    rewards = rewards_;

    router = router_;
    sellRoute = sellPath_;
  }
}
