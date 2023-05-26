// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ISystemClock} from "./ISystemClock.sol";

abstract contract SystemClockV1Storage is ISystemClock {
  uint256 public lastTime;
}
