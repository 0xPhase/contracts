// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract BringIntoHardhatContext {
  TimelockController internal _timelockController;

  constructor() {
    revert("BringIntoHardhatContext: Do NOT deploy");
  }
}
