// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract EIP712Upgradeable is Initializable {
  /* solhint-disable var-name-mixedcase */

  bytes32 private constant _TYPE_HASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  bytes32 private _HASHED_NAME;
  bytes32 private _HASHED_VERSION;

  /* solhint-enable var-name-mixedcase */

  // solhint-disable-next-line func-name-mixedcase
  function __EIP712_init(string memory name, string memory version)
    internal
    onlyInitializing
  {
    _HASHED_NAME = keccak256(bytes(name));
    _HASHED_VERSION = keccak256(bytes(version));
  }

  function _hashTypedDataV4(bytes32 structHash)
    internal
    view
    virtual
    returns (bytes32)
  {
    return _toTypedDataHash(_domainSeparatorV4(), structHash);
  }

  function _domainSeparatorV4() internal view returns (bytes32) {
    return
      _buildDomainSeparator(
        _TYPE_HASH,
        _EIP712NameHash(),
        _EIP712VersionHash()
      );
  }

  // solhint-disable-next-line func-name-mixedcase
  function _EIP712NameHash() internal view virtual returns (bytes32) {
    return _HASHED_NAME;
  }

  // solhint-disable-next-line func-name-mixedcase
  function _EIP712VersionHash() internal view virtual returns (bytes32) {
    return _HASHED_VERSION;
  }

  function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }

  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 nameHash,
    bytes32 versionHash
  ) private view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          typeHash,
          nameHash,
          versionHash,
          block.chainid,
          address(this)
        )
      );
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   */
  // solhint-disable-next-line ordering
  uint256[50] private __gap;
}
