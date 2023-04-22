// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IOracle} from "../../oracle/IOracle.sol";

interface IFixedOracle is IOracle {
  /// @notice Event emitted when a price is set for an asset
  /// @param asset The asset address
  /// @param price The price of the asset
  event PriceSet(address indexed asset, uint256 price);

  /// @notice Sets the price of an asset
  /// @param asset The asset address
  /// @param price The price of the asset
  function setPrice(address asset, uint256 price) external;
}
