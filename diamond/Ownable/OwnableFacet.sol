// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {OwnableStorage, IOwnable} from "./IOwnable.sol";
import {OwnableBase} from "./OwnableBase.sol";

contract OwnableFacet is OwnableBase, IOwnable {
  /// @inheritdoc	IOwnable
  /// @custom:protected onlyOwner
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(
      newOwner != address(0),
      "OwnableFacet: New owner is the zero address"
    );

    _transferOwnership(newOwner);
  }

  /// @inheritdoc	IOwnable
  /// @custom:protected onlyOwner
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /// @inheritdoc	IOwnable
  function owner() public view virtual returns (address) {
    return _owner();
  }
}
