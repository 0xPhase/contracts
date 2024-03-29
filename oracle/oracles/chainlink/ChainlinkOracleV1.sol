// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ChainlinkOracleV1Storage} from "./ChainlinkOracleV1Storage.sol";
import {IChainlinkOracle, PriceFeed} from "./IChainlinkOracle.sol";
import {IAggregator} from "../../../interfaces/IAggregator.sol";
import {MathLib} from "../../../lib/MathLib.sol";
import {IOracle} from "../../IOracle.sol";

contract ChainlinkOracleV1 is ChainlinkOracleV1Storage {
  /// @inheritdoc	IChainlinkOracle
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function setFeed(
    address asset,
    address feed,
    uint256 heartbeat
  ) external override onlyRole(MANAGER_ROLE) {
    priceFeeds[asset] = PriceFeed({feed: feed, heartbeat: heartbeat});

    emit FeedSet(asset, feed);
  }

  /// @inheritdoc	IOracle
  function getPrice(
    address asset
  ) external view override returns (uint256 price) {
    PriceFeed storage feed = priceFeeds[asset];

    require(
      feed.feed != address(0),
      "ChainlinkOracleV1: Price feed does not exist"
    );

    IAggregator aggregator = IAggregator(feed.feed);
    (, int256 itemPrice, , uint256 updatedAt, ) = aggregator.latestRoundData();

    require(
      systemClock.getTime() <= updatedAt + feed.heartbeat,
      "ChainlinkOracleV1: Oracle took too long to update price"
    );

    int256 scaled = MathLib.scaleAmount(itemPrice, aggregator.decimals(), 18);

    price = MathLib.onlyPositive(scaled);
  }
}
