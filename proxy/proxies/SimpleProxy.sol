// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {CallLib} from "../../lib/CallLib.sol";
import {IProxy} from "../IProxy.sol";
import {Proxy} from "../Proxy.sol";

/// @title Simple Proxy contract
/// @author 0xPhase
/// @dev Implementation of the Proxy contract without upgrades
contract SimpleProxy is Proxy {
  using StorageSlot for bytes32;

  bytes32 internal constant _IMPLEMENTATION_SLOT =
    bytes32(uint256(keccak256("proxy.implementation")) - 1);

  /// @dev Initializes the proxy with an implementation specified by `_target`.
  /// @param _target Address of contract for proxy
  /// @param _initialCall Optional initial calldata
  constructor(address _target, bytes memory _initialCall) {
    _setImplementation(_target);

    if (_initialCall.length > 0) {
      CallLib.delegateCallFunc(address(this), _initialCall);
    }
  }

  /// @inheritdoc IProxy
  function implementation(
    bytes4
  ) public view override returns (address _implementation) {
    _implementation = _IMPLEMENTATION_SLOT.getAddressSlot().value;
  }

  /// @inheritdoc IProxy
  function proxyType() public pure override returns (uint256 _type) {
    _type = 1;
  }

  /// @dev Function to set contract implementation
  /// @param _newImplementation Address of the new implementation
  function _setImplementation(address _newImplementation) internal {
    _IMPLEMENTATION_SLOT.getAddressSlot().value = _newImplementation;
  }
}
