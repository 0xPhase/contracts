// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyOwnable} from "../../../proxy/utils/ProxyOwnable.sol";
import {IOracle} from "../../IOracle.sol";

interface IChainlinkOracle is IOracle {
  event FeedSet(address indexed asset, address feed);

  function setFeed(address asset, address feed) external;
}

abstract contract ChainlinkOracleStorageV1 is ProxyOwnable, IChainlinkOracle {
  mapping(address => address) public priceFeeds;

  EnumerableSet.AddressSet internal _feeds;

  constructor() {
    _disableInitialization();
  }
}
