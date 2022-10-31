// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IVault} from "./IVault.sol";

interface IInterest {
  function getInterest(IVault vault) external view returns (uint256 interest);
}
