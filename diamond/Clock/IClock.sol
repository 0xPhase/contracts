// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ISystemClock} from "../../clock/ISystemClock.sol";

struct ClockStorage {
  ISystemClock systemClock;
}
