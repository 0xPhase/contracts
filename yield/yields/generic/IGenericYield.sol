// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ProxyInitializable} from "../../../proxy/utils/ProxyInitializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Element} from "../../../proxy/utils/Element.sol";
import {IVault} from "../../../vault/IVault.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IDB} from "../../../db/IDB.sol";

struct GenericData {
  uint256 action;
  bytes data;
}

abstract contract GenericYieldV1Storage is
  YieldBase,
  ProxyInitializable,
  Element
{
  address public target;
  GenericData public depositGeneric;
  GenericData public withdrawGeneric;
  GenericData public balanceGeneric;
  GenericData public shareGeneric;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the generic yield contract on version 1
  /// @param db_ The DB contract address
  /// @param asset_ The yield asset
  function initializeGenericYieldV1(
    IDB db_,
    IERC20 asset_,
    address target_,
    GenericData memory depositGeneric_,
    GenericData memory withdrawGeneric_,
    GenericData memory balanceGeneric_,
    GenericData memory shareGeneric_
  ) external initialize("v1") {
    _initializeElement(db_);
    _initializeBaseYield(asset_, db_.getAddress("BALANCER"));

    target = target_;
    depositGeneric = depositGeneric_;
    withdrawGeneric = withdrawGeneric_;
    balanceGeneric = balanceGeneric_;
    shareGeneric = shareGeneric_;
  }
}
