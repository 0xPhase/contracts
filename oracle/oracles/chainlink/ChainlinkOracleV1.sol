// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ChainlinkOracleStorageV1} from "./IChainlinkOracle.sol";
import {IAggregator} from "../../../interfaces/IAggregator.sol";
import {MathLib} from "../../../lib/MathLib.sol";

contract ChainlinkOracleV1 is ChainlinkOracleStorageV1 {
  function setFeed(address asset, address feed) external override onlyOwner {
    priceFeeds[asset] = feed;

    emit FeedSet(asset, feed);
  }

  function getPrice(address asset)
    external
    view
    override
    returns (uint256 price)
  {
    require(
      priceFeeds[asset] != address(0),
      "ChainlinkOracleV1: Price feed does not exist"
    );

    IAggregator aggregator = IAggregator(priceFeeds[asset]);
    (, int256 itemPrice, , , ) = aggregator.latestRoundData();
    int256 scaled = MathLib.scaleAmount(itemPrice, aggregator.decimals(), 18);

    price = _absZero(scaled);
  }

  function _absZero(int256 number) internal pure returns (uint256) {
    if (number >= 0) {
      return uint256(number);
    } else {
      return 0;
    }
  }
}
