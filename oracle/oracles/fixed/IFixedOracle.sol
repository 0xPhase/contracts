// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOracle} from "../../IOracle.sol";

interface IFixedOracle is IOracle {
  event PriceSet(address indexed asset, uint256 price);

  function setPrice(address asset, uint256 price) external;
}
