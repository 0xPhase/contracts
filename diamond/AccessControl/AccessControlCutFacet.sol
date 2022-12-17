// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {AccessControlBase} from "./AccessControlBase.sol";
import {IDiamondCut} from "../IDiamondCut.sol";
import {DiamondLib} from "../DiamondLib.sol";

bytes32 constant DIAMOND_CUT_ROLE = keccak256("DIAMOND_CUT_ROLE");

contract AccessControlCutFacet is AccessControlBase, IDiamondCut {
  function diamondCut(
    IDiamondCut.FacetCut[] memory cut,
    address init,
    bytes memory initdata
  ) external override onlyRole(DIAMOND_CUT_ROLE) {
    DiamondLib.diamondCut(cut, init, initdata);
  }
}
