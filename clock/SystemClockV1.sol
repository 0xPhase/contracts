// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SystemClockV1Storage} from "./SystemClockV1Storage.sol";
import {ISystemClock} from "./ISystemClock.sol";
import {MathLib} from "../lib/MathLib.sol";

contract SystemClockV1 is SystemClockV1Storage {
  /// @inheritdoc ISystemClock
  function time() external override returns (uint256 curTime) {
    curTime = lastTime;

    if (block.timestamp > curTime) {
      lastTime = block.timestamp;
      return block.timestamp;
    }
  }

  /// @inheritdoc ISystemClock
  function getTime() public view override returns (uint256) {
    return MathLib.max(block.timestamp, lastTime);
  }
}
