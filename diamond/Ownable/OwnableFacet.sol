// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {OwnableStorage, IOwnable} from "./IOwnable.sol";
import {OwnableBase} from "./OwnableBase.sol";

contract OwnableFacet is OwnableBase, IOwnable {
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(
      newOwner != address(0),
      "OwnableFacet: New owner is the zero address"
    );

    _transferOwnership(newOwner);
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function owner() public view virtual returns (address) {
    return _owner();
  }
}
