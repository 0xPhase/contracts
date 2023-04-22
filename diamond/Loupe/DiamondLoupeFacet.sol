// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IDiamondLoupe} from "../IDiamondLoupe.sol";
import {DiamondLib} from "../DiamondLib.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.
contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
  /// @notice Gets all facets and their selectors.
  /// @return facets_ Facet
  function facets() external view override returns (Facet[] memory facets_) {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
    uint256 numFacets = ds.facetAddresses.length;
    facets_ = new Facet[](numFacets);

    for (uint256 i; i < numFacets; ) {
      address facetAddress_ = ds.facetAddresses[i];

      facets_[i].facetAddress = facetAddress_;
      facets_[i].functionSelectors = ds
        .facetFunctionSelectors[facetAddress_]
        .functionSelectors;

      unchecked {
        i++;
      }
    }
  }

  /// @notice Gets all the function selectors provided by a facet.
  /// @param _facet The facet address.
  /// @return facetFunctionSelectors_
  function facetFunctionSelectors(
    address _facet
  ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

    facetFunctionSelectors_ = ds
      .facetFunctionSelectors[_facet]
      .functionSelectors;
  }

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses()
    external
    view
    override
    returns (address[] memory facetAddresses_)
  {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

    facetAddresses_ = ds.facetAddresses;
  }

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param _functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(
    bytes4 _functionSelector
  ) external view override returns (address facetAddress_) {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();

    facetAddress_ = ds
      .selectorToFacetAndPosition[_functionSelector]
      .facetAddress;
  }

  /// @inheritdoc	IERC165
  function supportsInterface(
    bytes4 _interfaceId
  ) external view override returns (bool) {
    DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
    return ds.supportedInterfaces[_interfaceId];
  }
}
