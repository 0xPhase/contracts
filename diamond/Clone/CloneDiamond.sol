// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {OwnableBase} from "../Ownable/OwnableBase.sol";
import {IDiamondLoupe} from "../IDiamondLoupe.sol";
import {CallLib} from "../../lib/CallLib.sol";

contract CloneDiamond is OwnableBase {
  bytes32 public constant DIAMOND_TARGET_STORAGE_SLOT =
    bytes32(uint256(keccak256("clone.diamond.target.storage")) - 1);

  event TargetChanged(
    address indexed oldTarget,
    address indexed newTarget,
    address indexed changer
  );

  constructor(
    address owner_,
    address target_,
    address initializer_,
    bytes memory initializerData_
  ) {
    _transferOwnership(owner_);
    _setCloneDiamondTarget(target_);

    if (initializerData_.length > 0) {
      CallLib.delegateCallFunc(initializer_, initializerData_);
    }
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  // solhint-disable-next-line no-complex-fallback
  fallback() external payable {
    address target = _getCloneDiamondTarget();

    // get facet from function selector
    address facet = IDiamondLoupe(target).facetAddress(msg.sig);

    require(facet != address(0), "CloneDiamond: Function does not exist");

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

  function changeTarget(
    address newTarget,
    address initializer_,
    bytes memory initializerData_
  ) external onlyOwner {
    _setCloneDiamondTarget(newTarget);

    if (initializerData_.length > 0) {
      CallLib.delegateCallFunc(initializer_, initializerData_);
    }
  }

  function initialize(address initializer_, bytes memory initializerData_)
    external
    onlyOwner
  {
    CallLib.delegateCallFunc(initializer_, initializerData_);
  }

  function _setCloneDiamondTarget(address newTarget) internal {
    bytes32 slot = DIAMOND_TARGET_STORAGE_SLOT;
    address oldTarget;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      oldTarget := sload(slot)
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newTarget)
    }

    emit TargetChanged(oldTarget, newTarget, msg.sender);
  }

  function _getCloneDiamondTarget() internal view returns (address target) {
    bytes32 slot = DIAMOND_TARGET_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      target := sload(slot)
    }
  }
}
