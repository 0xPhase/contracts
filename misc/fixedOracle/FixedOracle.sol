// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IOracle} from "../../oracle/IOracle.sol";
import {IFixedOracle} from "./IFixedOracle.sol";

contract FixedOracle is Ownable, Multicall, IFixedOracle {
  mapping(address => uint256) internal _price;

  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  /// @inheritdoc	IFixedOracle
  /// @custom:protected onlyOwner
  function setPrice(address asset, uint256 price) external override onlyOwner {
    _price[asset] = price;
    emit PriceSet(asset, price);
  }

  /// @inheritdoc	IOracle
  function getPrice(
    address asset
  ) external view override returns (uint256 price) {
    return _price[asset];
  }
}
