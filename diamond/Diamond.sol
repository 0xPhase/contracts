// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IDiamondCut} from "./IDiamondCut.sol";
import {DiamondLib} from "./DiamondLib.sol";
import {IDB} from "../db/IDB.sol";

contract Diamond {
  /// @notice The constructor for the Diamond contract
  /// @param cut The list of cuts to do
  /// @param init The optional initializer address
  /// @param initdata The optional initializer data
  constructor(
    IDiamondCut.FacetCut[] memory cut,
    address init,
    bytes memory initdata
  ) payable {
    DiamondLib.diamondCut(cut, init, initdata);
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  // solhint-disable-next-line no-complex-fallback
  fallback() external payable {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;

    require(facet != address(0), "Diamond: Function does not exist");

    // Execute external function from facet using delegatecall and return any value.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())

      // execute function call using the facet
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

      // get any return value
      returndatacopy(0, 0, returndatasize())

      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}
