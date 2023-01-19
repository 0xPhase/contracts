// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IVault} from "./IVault.sol";

interface IInterest {
  /// @notice Gets the interest for the vault
  /// @param vault The vault contract address
  /// @return interest The interest
  function getInterest(IVault vault) external view returns (uint256 interest);
}
