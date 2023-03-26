// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ICreditAccount} from "../account/ICreditAccount.sol";
import {IBondSetters, Bond} from "./IBond.sol";
import {BondBase} from "./BondBase.sol";

contract BondSettersFacet is BondBase, IBondSetters {
  /// @inheritdoc	IBondSetters
  /// @custom:protected onlyRole(_MANAGER_ROLE)
  function setBondDuration(uint256 duration) external onlyRole(_MANAGER_ROLE) {
    _s.bondDuration = duration;
    emit BondDurationSet(duration);
  }

  /// @inheritdoc	IBondSetters
  /// @custom:protected onlyRole(_MANAGER_ROLE)
  function setProtocolExitPortion(
    uint256 protocolExitPortion
  ) external onlyRole(_MANAGER_ROLE) {
    _s.protocolExitPortion = protocolExitPortion;
    emit ProtocolExitPortionSet(protocolExitPortion);
  }
}
