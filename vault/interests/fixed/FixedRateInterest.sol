// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IInterest} from "../../IInterest.sol";
import {IVault} from "../../IVault.sol";

contract FixedRateInterest is Ownable, IInterest {
  uint256 public fixedInterest;

  constructor(address owner_, uint256 initialFixedInterest_) {
    fixedInterest = initialFixedInterest_;

    _transferOwnership(owner_);
  }

  function setFixedInterest(uint256 newInterest) external onlyOwner {
    fixedInterest = newInterest;
  }

  function getInterest(IVault)
    external
    view
    override
    returns (uint256 interest)
  {
    interest = fixedInterest;
  }
}
