// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ISystemClock, SystemClockStorageV1} from "./ISystemClock.sol";
import {MathLib} from "../lib/MathLib.sol";

contract SystemClockV1 is SystemClockStorageV1 {
  /// @inheritdoc ISystemClock
  function time() external override returns (uint256) {
    uint256 curTime = getTime();

    if (curTime > lastTime) {
      lastTime = curTime;
    }

    return lastTime;
  }

  /// @inheritdoc ISystemClock
  function getTime() public view override returns (uint256) {
    return MathLib.max(block.timestamp, lastTime);
  }
}
