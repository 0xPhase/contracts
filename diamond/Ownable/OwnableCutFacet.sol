// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IDiamondCut} from "../IDiamondCut.sol";
import {OwnableBase} from "./OwnableBase.sol";
import {DiamondLib} from "../DiamondLib.sol";

contract OwnableCutFacet is OwnableBase, IDiamondCut {
  function diamondCut(
    IDiamondCut.FacetCut[] memory cut,
    address init,
    bytes memory initdata
  ) external override onlyOwner {
    DiamondLib.diamondCut(cut, init, initdata);
  }
}
