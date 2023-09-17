// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IStargateEthVault} from "../../../interfaces/stargate/IStargateEthVault.sol";
import {IStargateRouter} from "../../../interfaces/stargate/IStargateRouter.sol";
import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IBeefyVault} from "../../../interfaces/beefy/IBeefyVault.sol";
import {IFactory} from "../../../interfaces/stargate/IFactory.sol";
import {IPool} from "../../../interfaces/stargate/IPool.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract StargateYieldV1Storage is
  YieldBase,
  ProxyInitializable,
  Element
{
  IBeefyVault public beefyVault;
  IStargateRouter public stargateRouter;
  IStargateEthVault public stargateEthVault;
  uint256 public poolId;
  bool public isETH;
  IPool public pool;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the stargate yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  /// @param beefyVault_ The Beefy vault contract
  /// @param stargateRouter_ The Stargate router contract address
  /// @param stargateEthVault_ The Stargate ETH vault contract address
  /// @param factory_ The Stargate factory contract address
  /// @param poolId_ The Stargate pool id
  /// @param isETH_ If the underlying asset is ETH
  function initializeStargateYieldV1(
    IDB db_,
    IERC20 asset_,
    IBeefyVault beefyVault_,
    IStargateRouter stargateRouter_,
    IStargateEthVault stargateEthVault_,
    IFactory factory_,
    uint256 poolId_,
    bool isETH_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    IPool pool_ = IPool(factory_.getPool(poolId_));

    beefyVault = beefyVault_;
    stargateRouter = stargateRouter_;
    stargateEthVault = stargateEthVault_;
    poolId = poolId_;
    pool = pool_;
    isETH = isETH_;
  }
}
