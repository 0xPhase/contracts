// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IFixedOracle} from "./IFixedOracle.sol";

contract FixedOracle is Ownable, Multicall, IFixedOracle {
  mapping(address => uint256) internal _price;

  function setPrice(address asset, uint256 price) external override onlyOwner {
    _price[asset] = price;
    emit PriceSet(asset, price);
  }

  function getPrice(address asset)
    external
    view
    override
    returns (uint256 price)
  {
    return _price[asset];
  }
}
