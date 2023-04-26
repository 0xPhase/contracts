// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {AccessControlBase} from "./AccessControlBase.sol";
import {IDiamondCut} from "../IDiamondCut.sol";
import {DiamondLib} from "../DiamondLib.sol";

bytes32 constant DIAMOND_CUT_ROLE = keccak256("DIAMOND_CUT_ROLE");

contract AccessControlCutFacet is AccessControlBase, IDiamondCut {
  /// @notice External function to cut the diamond requiring the DIAMOND_CUT_ROLE role
  /// @param cut The list of cuts to do
  /// @param init The optional initializer address
  /// @param initdata The optional initializer data
  /// @custom:protected onlyRole(DIAMOND_CUT_ROLE)
  function diamondCut(
    IDiamondCut.FacetCut[] memory cut,
    address init,
    bytes memory initdata
  ) external override onlyRole(DIAMOND_CUT_ROLE) {
    DiamondLib.diamondCut(cut, init, initdata);
  }
}
