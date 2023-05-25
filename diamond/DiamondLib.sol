// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IDiamondCut} from "./IDiamondCut.sol";
import {CallLib} from "../lib/CallLib.sol";

/// @notice Error emitted when the initialization reverts
/// @param _initializationContractAddress The initializer address
/// @param _calldata The initializer data
error InitializationFunctionReverted(
  address _initializationContractAddress,
  bytes _calldata
);

library DiamondLib {
  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
  }

  bytes32 public constant DIAMOND_STORAGE_SLOT =
    bytes32(uint256(keccak256("diamond.standard.diamond.storage")) - 1);

  /// @notice Event emitted when the diamond is cut
  /// @param _diamondCut The list of cuts to do
  /// @param _init The optional initializer address
  /// @param _calldata The optional initializer data
  event DiamondCut(
    IDiamondCut.FacetCut[] _diamondCut,
    address _init,
    bytes _calldata
  );

  /// @notice Internal function to cut the diamond
  /// @param _diamondCut The list of cuts to do
  /// @param _init The optional initializer address
  /// @param _calldata The optional initializer data
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;

      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else {
        revert("DiamondLib: Incorrect FacetCutAction");
      }

      unchecked {
        facetIndex++;
      }
    }

    emit DiamondCut(_diamondCut, _init, _calldata);

    initializeDiamondCut(_init, _calldata);
  }

  /// @notice Adds functions to the diamond
  /// @param _facetAddress The facet address
  /// @param _functionSelectors The function selectors to add
  function addFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    require(
      _functionSelectors.length > 0,
      "DiamondLib: No selectors in facet to cut"
    );

    DiamondStorage storage ds = diamondStorage();

    require(
      _facetAddress != address(0),
      "DiamondLib: Add facet can't be address(0)"
    );

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );

    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
      bytes4 selector = _functionSelectors[selectorIndex];

      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      require(
        oldFacetAddress == address(0),
        "DiamondLib: Can't add function that already exists"
      );

      addFunction(ds, selector, selectorPosition, _facetAddress);

      selectorPosition++;

      unchecked {
        selectorIndex++;
      }
    }
  }

  /// @notice Replaces functions in the diamond
  /// @param _facetAddress The facet address
  /// @param _functionSelectors The function selectors to replace
  function replaceFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    require(
      _functionSelectors.length > 0,
      "DiamondLib: No selectors in facet to cut"
    );

    DiamondStorage storage ds = diamondStorage();

    require(
      _facetAddress != address(0),
      "DiamondLib: Add facet can't be address(0)"
    );

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );

    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
      bytes4 selector = _functionSelectors[selectorIndex];

      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      require(
        oldFacetAddress != _facetAddress,
        "DiamondLib: Can't replace function with same function"
      );

      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);

      selectorPosition++;

      unchecked {
        selectorIndex++;
      }
    }
  }

  /// @notice Removes functions from the diamond
  /// @param _facetAddress The facet address
  /// @param _functionSelectors The function selectors to remove
  function removeFunctions(
    address _facetAddress,
    bytes4[] memory _functionSelectors
  ) internal {
    require(
      _functionSelectors.length > 0,
      "DiamondLib: No selectors in facet to cut"
    );

    DiamondStorage storage ds = diamondStorage();

    // if function does not exist then do nothing and return
    require(
      _facetAddress == address(0),
      "DiamondLib: Remove facet address must be address(0)"
    );

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
      bytes4 selector = _functionSelectors[selectorIndex];

      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      removeFunction(ds, oldFacetAddress, selector);

      unchecked {
        selectorIndex++;
      }
    }
  }

  /// @notice Adds a facet to the diamond
  /// @param ds The diamond storage pointer
  /// @param _facetAddress The facet address to add
  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    require(
      Address.isContract(_facetAddress),
      "DiamondLib: Facet must be a contract"
    );

    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
      .facetAddresses
      .length;

    ds.facetAddresses.push(_facetAddress);
  }

  /// @notice Adds a function to the diamond
  /// @param ds The diamond storage pointer
  /// @param _selector The function selector to add
  /// @param _selectorPosition The function selector position
  /// @param _facetAddress The facet address
  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    FacetAddressAndPosition storage addressAndPosition = ds
      .selectorToFacetAndPosition[_selector];

    addressAndPosition.functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    addressAndPosition.facetAddress = _facetAddress;
  }

  /// @notice Removes a function from the diamond
  /// @param ds The diamond storage pointer
  /// @param _facetAddress The facet address
  /// @param _selector The function selector to remove
  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    require(
      _facetAddress != address(0),
      "DiamondLib: Can't remove function that doesn't exist"
    );

    // an immutable function is a function defined directly in a diamond
    require(
      _facetAddress != address(this),
      "DiamondLib: Can't remove immutable function"
    );

    FacetFunctionSelectors storage functionSelectors = ds
      .facetFunctionSelectors[_facetAddress];

    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition;

    uint256 lastSelectorPosition = functionSelectors.functionSelectors.length -
      1;

    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = functionSelectors.functionSelectors[
        lastSelectorPosition
      ];

      functionSelectors.functionSelectors[selectorPosition] = lastSelector;

      ds
        .selectorToFacetAndPosition[lastSelector]
        .functionSelectorPosition = uint96(selectorPosition);
    }

    // delete the last selector
    functionSelectors.functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = functionSelectors.facetAddressPosition;

      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];

        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds
          .facetFunctionSelectors[lastFacetAddress]
          .facetAddressPosition = facetAddressPosition;
      }

      ds.facetAddresses.pop();

      delete functionSelectors.facetAddressPosition;
    }
  }

  /// @notice Initializes the diamond
  /// @param _init The initializer address
  /// @param _calldata The initializer data
  function initializeDiamondCut(
    address _init,
    bytes memory _calldata
  ) internal {
    if (_init == address(0)) {
      return;
    }

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory error) = _init.delegatecall(_calldata);

    if (!success) {
      if (error.length > 0) {
        // bubble up error
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(error)
          revert(add(32, error), returndata_size)
        }
      } else {
        revert InitializationFunctionReverted(_init, _calldata);
      }
    }
  }

  /// @notice Returns the diamond storage pointer
  /// @return ds The diamond storage pointer
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      ds.slot := position
    }
  }
}
