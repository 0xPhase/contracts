// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IPegRegistry, PegRegistryV1Storage, PegItem} from "../IPegRegistry.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {IPegToken} from "../IPegToken.sol";

contract PegRegistryV1 is PegRegistryV1Storage {
  /// @notice Adds a new peg token
  /// @param pegToken The peg token
  /// @param trackedAsset The tracked asset
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function addPegToken(
    IPegToken pegToken,
    address trackedAsset
  ) external onlyRole(MANAGER_ROLE) {
    require(!exists(pegToken), "PegRegistryV1: Peg token exists already");

    registry[pegToken] = PegItem(pegToken, trackedAsset);
  }

  /// @inheritdoc	IPegRegistry
  function exists(IPegToken pegToken) public view override returns (bool) {
    return address(registry[pegToken].pegToken) != address(0);
  }

  /// @inheritdoc	IPegRegistry
  function price(IPegToken pegToken) external view override returns (uint256) {
    require(exists(pegToken), "PegRegistryV1: Peg token does not exist");

    return oracle.getPrice(registry[pegToken].trackedAsset);
  }

  /// @inheritdoc	IOracle
  function getPrice(address asset) external view returns (uint256 price) {
    return oracle.getPrice(registry[IPegToken(asset)].trackedAsset);
  }
}
