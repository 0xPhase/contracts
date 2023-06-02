// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IChainOracle, Chain, ChainItem} from "./IChainOracle.sol";
import {ChainOracleV1Storage} from "./ChainOracleV1Storage.sol";
import {IAggregator} from "../../../interfaces/IAggregator.sol";
import {MathLib} from "../../../lib/MathLib.sol";
import {IOracle} from "../../IOracle.sol";

contract ChainOracleV1 is ChainOracleV1Storage {
  /// @inheritdoc	IChainOracle
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function setChain(
    address asset,
    ChainItem[] memory chain
  ) external override onlyRole(MANAGER_ROLE) {
    _chains[asset] = Chain({chain: chain});

    emit ChainSet(asset, chain);
  }

  /// @inheritdoc	IChainOracle
  function assetChain(
    address asset
  ) external view override returns (ChainItem[] memory chain) {
    return _chains[asset].chain;
  }

  /// @inheritdoc	IOracle
  function getPrice(
    address asset
  ) external view override returns (uint256 price) {
    Chain storage chain = _chains[asset];
    uint256 length = chain.chain.length;

    require(length > 0, "ChainOracleV1: Price feed does not exist");

    ChainItem storage firstItem = chain.chain[0];

    price = firstItem.oracle.getPrice(firstItem.asset);

    if (length > 1) {
      for (uint256 i = 1; i < length; ) {
        ChainItem storage item = chain.chain[i];

        price = (price * item.oracle.getPrice(item.asset)) / 1 ether;

        unchecked {
          i++;
        }
      }
    }
  }
}
