// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {ICometExt} from "../../../interfaces/compound/comet/ICometExt.sol";
import {IComet} from "../../../interfaces/compound/comet/IComet.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

abstract contract CompoundYieldV1Storage is
  YieldBase,
  ProxyInitializable,
  Element
{
  IComet public comet;
  ICometExt public cometExt;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the compound yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  /// @param comet_ The Compound Comet contract address
  /// @param cometExt_ The Compound Comet Ext contract address
  function initializeCompoundYieldV1(
    IDB db_,
    IERC20 asset_,
    IComet comet_,
    ICometExt cometExt_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    comet = comet_;
    cometExt = cometExt_;
  }
}
