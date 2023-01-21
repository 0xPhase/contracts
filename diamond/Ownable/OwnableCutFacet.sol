// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IDiamondCut} from "../IDiamondCut.sol";
import {OwnableBase} from "./OwnableBase.sol";
import {DiamondLib} from "../DiamondLib.sol";

contract OwnableCutFacet is OwnableBase, IDiamondCut {
  /// @notice Function to cut the diamond
  /// @param cut The list of cuts to do
  /// @param init The optional initializer address
  /// @param initdata The optional initializer data
  /// @custom:protected onlyOwner
  function diamondCut(
    IDiamondCut.FacetCut[] memory cut,
    address init,
    bytes memory initdata
  ) external override onlyOwner {
    DiamondLib.diamondCut(cut, init, initdata);
  }
}
