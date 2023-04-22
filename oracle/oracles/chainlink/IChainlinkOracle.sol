// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ISystemClock} from "../../../clock/ISystemClock.sol";
import {IOracle} from "../../IOracle.sol";

struct PriceFeed {
  address feed;
  uint256 heartbeat;
}

interface IChainlinkOracle is IOracle {
  /// @notice Event emitted when the feed for an address is set
  /// @param asset The asset address
  /// @param feed The feed address
  event FeedSet(address indexed asset, address feed);

  /// @notice Sets the feed for an asset
  /// @param asset The asset address
  /// @param feed The feed address
  /// @param heartbeat The maximum heartbeat duration
  function setFeed(address asset, address feed, uint256 heartbeat) external;

  /// @notice Returns the feed for the asset
  /// @param feed The feed address
  /// @param heartbeat The maximum heartbeat duration
  function priceFeeds(
    address asset
  ) external view returns (address feed, uint256 heartbeat);

  /// @notice Returns the System Clock contract
  /// @return The System Clock contract
  function systemClock() external view returns (ISystemClock);
}
