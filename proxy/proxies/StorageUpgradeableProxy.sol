// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {ProxyOwnable} from "../utils/ProxyOwnable.sol";
import {Storage} from "../../misc/Storage.sol";
import {CallLib} from "../../lib/CallLib.sol";
import {IProxy} from "../IProxy.sol";
import {Proxy} from "../Proxy.sol";

/// @title Admin Upgradeable Proxy contract
/// @author 0xPhase
/// @dev Implementation of the Proxy contract in an owner upgradeable way
contract StorageUpgradeableProxy is ProxyOwnable, Proxy {
  using StorageSlot for bytes32;

  bytes32 internal constant _STORAGE_SLOT =
    bytes32(uint256(keccak256("proxy.storage")) - 1);

  bytes32 internal constant _SLOT_SLOT =
    bytes32(uint256(keccak256("proxy.storage.slot")) - 1);

  /// @dev Event emitted after upgrade of proxy
  /// @param _newStorage Address of the new storage
  /// @param _newSlot Slot of the new implementation
  event Upgraded(address indexed _newStorage, bytes32 indexed _newSlot);

  /// @dev Initializes the upgradeable proxy with an initial implementation specified by `_target`.
  /// @param _owner Address of proxy owner
  /// @param _storage Address of the storage contract
  /// @param _slot Slot of the implementation
  /// @param _initialCall Optional initial calldata
  constructor(
    address _owner,
    address _storage,
    bytes32 _slot,
    bytes memory _initialCall
  ) {
    _setImplementation(_storage, _slot);
    _initializeOwnership(_owner);

    if (_initialCall.length > 0) {
      CallLib.delegateCallFunc(address(this), _initialCall);
    }
  }

  /// @dev Function to upgrade contract implementation
  /// @notice Only callable by the ecosystem owner
  /// @param _newStorage Address of the new storage
  /// @param _newSlot Slot of the new implementation
  /// @param _oldImplementationData Optional call data for old implementation before upgrade
  /// @param _newImplementationData Optional call data for new implementation after upgrade
  function upgradeTo(
    address _newStorage,
    bytes32 _newSlot,
    bytes memory _oldImplementationData,
    bytes memory _newImplementationData
  ) external onlyOwner {
    if (_oldImplementationData.length > 0) {
      CallLib.delegateCallFunc(implementation(), _oldImplementationData);
    }

    _setImplementation(_newStorage, _newSlot);

    if (_newImplementationData.length > 0) {
      CallLib.delegateCallFunc(implementation(), _newImplementationData);
    }

    emit Upgraded(_newStorage, _newSlot);
  }

  /// @inheritdoc IProxy
  function implementation()
    public
    view
    override
    returns (address _implementation)
  {
    address _storage = _STORAGE_SLOT.getAddressSlot().value;
    bytes32 _slot = _SLOT_SLOT.getBytes32Slot().value;

    _implementation = Storage(_storage).readAddress(_slot);
  }

  /// @inheritdoc IProxy
  function proxyType() public pure override returns (uint256 _type) {
    _type = 2;
  }

  /// @dev Function to upgrade contract implementation
  /// @param _newStorage Address of the new storage
  /// @param _newSlot Slot of the new implementation
  function _setImplementation(address _newStorage, bytes32 _newSlot) internal {
    _STORAGE_SLOT.getAddressSlot().value = _newStorage;
    _SLOT_SLOT.getBytes32Slot().value = _newSlot;
  }
}
