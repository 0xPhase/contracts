// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IV3SwapRouter} from "../../../interfaces/uniswap/IV3SwapRouter.sol";
import {IQuoterV2} from "../../../interfaces/uniswap/IQuoterV2.sol";
import {IGMXTracker} from "../../../interfaces/gmx/IGMXTracker.sol";
import {IGMXRouter} from "../../../interfaces/gmx/IGMXRouter.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract GMXYieldV1Storage is YieldBase, ProxyInitializable, Element {
  using SafeERC20 for IERC20;

  IERC20 public weth;
  uint24 public fee;

  IV3SwapRouter public router;
  IQuoterV2 public quoter;
  IGMXRouter public gmxRouter;
  IGMXTracker public rewardTracker;
  IGMXTracker public balanceTracker;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the GMX yield contract on version 1
  /// @param db_ The DB contract address
  /// @param weth_ The WETH asset
  /// @param gmx_ The GMX asset
  /// @param fee_ The Uniswap V3 pool fee
  /// @param router_ The Uniswap V3 router
  /// @param quoter_ The Uniswap V3 quoter
  /// @param gmxRouter_ The GMX router
  function initializeGMXYieldV1(
    IDB db_,
    IERC20 weth_,
    IERC20 gmx_,
    uint24 fee_,
    IV3SwapRouter router_,
    IQuoterV2 quoter_,
    IGMXRouter gmxRouter_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(gmx_, db_.getAddress("BALANCER"));

    weth = weth_;
    fee = fee_;
    router = router_;
    quoter = quoter_;

    gmxRouter = gmxRouter_;
    rewardTracker = IGMXTracker(gmxRouter_.feeGmxTracker());
    balanceTracker = IGMXTracker(gmxRouter_.stakedGmxTracker());

    gmx_.safeApprove(address(balanceTracker), type(uint256).max);
  }
}
