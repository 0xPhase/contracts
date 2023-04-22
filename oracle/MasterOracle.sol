// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IOracle} from "./IOracle.sol";

contract MasterOracle is Ownable, Multicall, IOracle {
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  EnumerableMap.AddressToUintMap private _assets;

  /// @notice Event emmited when an asset oracle is set
  /// @param asset The asset address
  /// @param newOracle The oracle address
  event AssetSet(address indexed asset, address indexed newOracle);

  /// @notice Constructor for the MasterOracle contract
  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  /// @notice Sets the oracle for an address, address(0) removes the oracle and the asset
  /// @param asset The asset address
  /// @param newOracle The oracle address
  /// @custom:protected onlyOwner
  function setAsset(address asset, address newOracle) external onlyOwner {
    if (newOracle == address(0)) {
      _assets.remove(asset);

      emit AssetSet(asset, address(0));

      return;
    }

    _assets.set(asset, uint256(uint160(newOracle)));

    emit AssetSet(asset, newOracle);
  }

  /// @inheritdoc	IOracle
  function getPrice(
    address asset
  ) external view override returns (uint256 price) {
    address oracleAddress = oracle(asset);

    require(
      oracleAddress != address(0),
      "MasterOracle: Asset does not have an oracle"
    );

    return IOracle(oracleAddress).getPrice(asset);
  }

  /// @notice Returns all the assets in the master oracle
  /// @return results The list of asset addresses
  function assets() external view returns (address[] memory results) {
    uint256 length = _assets.length();

    results = new address[](length);

    for (uint256 i = 0; i < length; ) {
      (address asset, ) = _assets.at(i);
      results[i] = asset;

      unchecked {
        i++;
      }
    }
  }

  /// @notice Returns the oracle for the address, address(0) if no oracle found
  /// @param asset The asset address
  /// @return The oracle address
  function oracle(address asset) public view returns (address) {
    if (!_assets.contains(asset)) return address(0);

    return address(uint160(_assets.get(asset)));
  }
}
