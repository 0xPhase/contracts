// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {OwnableBase} from "../Ownable/OwnableBase.sol";
import {IDiamondLoupe} from "../IDiamondLoupe.sol";
import {CallLib} from "../../lib/CallLib.sol";
import {IProxy} from "../../proxy/IProxy.sol";
import {Proxy} from "../../proxy/Proxy.sol";

contract CloneDiamond is Proxy, OwnableBase {
  bytes32 public constant DIAMOND_TARGET_STORAGE_SLOT =
    bytes32(uint256(keccak256("clone.diamond.target.storage")) - 1);

  /// @notice Event emitted when the target diamond changes
  /// @param oldTarget The old diamond target
  /// @param newTarget The new diamond target
  /// @param changer The address that called the function
  event TargetChanged(
    address indexed oldTarget,
    address indexed newTarget,
    address indexed changer
  );

  /// @notice The constructor for the CloneDiamond contract
  /// @param owner_ The owner of clone
  /// @param target_ The initial diamond target
  /// @param initializer_ The optional initializer address
  /// @param initializerData_ The optional initializer calldata
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

  /// @notice Changes the target diamond
  /// @param newTarget The new diamond target
  /// @param initializer_ The optional initializer address
  /// @param initializerData_ The optional initializer calldata
  /// @custom:protected onlyOwner
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

  /// @notice Initializes the diamond
  /// @param initializer_ The initializer address
  /// @param initializerData_ The initializer calldata
  /// @custom:protected onlyOwner
  function initialize(
    address initializer_,
    bytes memory initializerData_
  ) external onlyOwner {
    CallLib.delegateCallFunc(initializer_, initializerData_);
  }

  /// @inheritdoc IProxy
  function implementation(
    bytes4 sig
  ) public view override returns (address _implementation) {
    bytes32 slot = DIAMOND_TARGET_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      _implementation := sload(slot)
    }

    _implementation = IDiamondLoupe(_implementation).facetAddress(sig);
  }

  /// @inheritdoc IProxy
  function proxyType() public pure override returns (uint256 _type) {
    _type = 2;
  }

  /// @notice Sets the target address in the storage
  /// @param newTarget The new target address
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
}
