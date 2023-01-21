// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IInterest} from "../../IInterest.sol";
import {IVault} from "../../IVault.sol";

contract FixedRateInterest is Ownable, IInterest {
  uint256 public fixedInterest;

  /// @notice Constructor for the FixedRateInterest contract
  /// @param owner_ The owner address
  /// @param initialFixedInterest_ The initial fixed interest
  constructor(address owner_, uint256 initialFixedInterest_) {
    fixedInterest = initialFixedInterest_;

    _transferOwnership(owner_);
  }

  /// @notice Sets the fixed interest
  /// @param newInterest The new fixed interest
  /// @custom:protected onlyOwner
  function setFixedInterest(uint256 newInterest) external onlyOwner {
    fixedInterest = newInterest;
  }

  /// @inheritdoc	IInterest
  function getInterest(
    IVault
  ) external view override returns (uint256 interest) {
    interest = fixedInterest;
  }
}
