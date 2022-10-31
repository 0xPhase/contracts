// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ProxyOwnable} from "../../../proxy/utils/ProxyOwnable.sol";
import {IOracle} from "../../IOracle.sol";

interface IChainlinkOracle is IOracle {
  event FeedSet(address indexed asset, address feed);

  function setFeed(address asset, address feed) external;
}

abstract contract ChainlinkOracleStorageV1 is ProxyOwnable, IChainlinkOracle {
  mapping(address => address) public priceFeeds;
}
