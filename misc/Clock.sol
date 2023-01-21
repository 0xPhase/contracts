// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {MathLib} from "../lib/MathLib.sol";
import {SlotLib} from "../lib/SlotLib.sol";

abstract contract Clock {
  struct ClockStorage {
    uint256 lastTime;
  }

  /// @notice Updates the time before running the function
  modifier updateTime() {
    _updateTime();
    _;
  }

  /// @notice Gets the time without updating it
  /// @return The current time
  function time() public view returns (uint256) {
    return MathLib.max(block.timestamp, lastTime());
  }

  /// @notice Gets the last updated time
  /// @return The last updated time
  function lastTime() public view returns (uint256) {
    ClockStorage storage data = _storage();
    return data.lastTime;
  }

  /// @notice Updates the time
  function _updateTime() internal {
    ClockStorage storage data = _storage();

    if (block.timestamp > data.lastTime) {
      data.lastTime = block.timestamp;
    }
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
