// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ISystemClock} from "../../../clock/ISystemClock.sol";
import {IOracle} from "../../IOracle.sol";

struct ChainItem {
  IOracle oracle;
  address asset;
}

struct Chain {
  ChainItem[] chain;
}

interface IChainOracle is IOracle {
  /// @notice Event emitted when the chain for an address is set
  /// @param asset The asset address
  /// @param chain The price chain
  event ChainSet(address indexed asset, ChainItem[] chain);

  /// @notice Sets the chain for an asset
  /// @param asset The asset address
  /// @param chain The price chain
  function setChain(address asset, ChainItem[] memory chain) external;

  /// @notice Returns the price chain for the asset
  /// @param asset The asset address
  /// @return chain The price chain
  function assetChain(
    address asset
  ) external view returns (ChainItem[] memory chain);
}
