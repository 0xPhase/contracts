// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyOwnable} from "../../../proxy/utils/ProxyOwnable.sol";
import {IOracle} from "../../IOracle.sol";

interface IChainlinkOracle is IOracle {
  /// @notice Event emitted when the feed for an address is set
  /// @param asset The asset address
  /// @param feed The feed address
  event FeedSet(address indexed asset, address feed);

  /// @notice Sets the feed for an asset
  /// @param asset The asset address
  /// @param feed The feed address
  function setFeed(address asset, address feed) external;
}

abstract contract ChainlinkOracleStorageV1 is ProxyOwnable, IChainlinkOracle {
  mapping(address => address) public priceFeeds;

  EnumerableSet.AddressSet internal _feeds;

  /// @notice The constructor for the ChainlinkOracleStorageV1 contract
  constructor() {
    _disableInitialization();
  }
}
