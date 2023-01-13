// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {SlotLib} from "../../lib/SlotLib.sol";
import {ClockStorage} from "./IClock.sol";

abstract contract ClockBase {
  /// @notice Updates the time before running the function
  modifier updateTime() {
    _updateTime();
    _;
  }

  /// @notice Updates the  time
  function _updateTime() internal {
    ClockStorage storage data = _storage();

    if (block.timestamp > data.lastTime) {
      data.lastTime = block.timestamp;
    }
  }

  /// @notice Gets the time without updating it
  /// @return The current time
  function _time() internal view returns (uint256) {
    return Math.max(block.timestamp, _lastTime());
  }

  /// @notice Gets the last updated time
  /// @return The last updated time
  function _lastTime() internal view returns (uint256) {
    ClockStorage storage data = _storage();
    return data.lastTime;
  }

  /// @notice Gets the clock storage pointer
  /// @return data The clock storage pointer
  function _storage() internal pure returns (ClockStorage storage data) {
    bytes32 slot = SlotLib.slot(string("clock.storage"));

    // solhint-disable-next-line no-inline-assembly
    assembly {
      data.slot := slot
    }
  }
}
