// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ElementBase} from "../Element/ElementBase.sol";
import {ClockStorage} from "./IClock.sol";

abstract contract ClockBase is ElementBase {
  bytes32 internal constant _CLOCK_STORAGE_SLOT =
    bytes32(uint256(keccak256("clock.base.storage")) - 1);

  /// @notice Updates the time
  modifier updateTime() {
    _updateTime();
    _;
  }

  /// @notice Initializes the clock base contract
  function _initializeClock() internal {
    _cs().systemClock = ISystemClock(_db().getAddress("SYSTEM_CLOCK"));
  }

  /// @notice Updates the time
  function _updateTime() internal {
    _cs().systemClock.time();
  }

  /// @notice Gets the time without updating it
  /// @return The current time
  function _time() internal view returns (uint256) {
    return _cs().systemClock.getTime();
  }

  /// @notice Gets the last updated time
  /// @return The last updated time
  function _lastTime() internal view returns (uint256) {
    return _cs().systemClock.lastTime();
  }

  /// @notice Returns the pointer to the clock storage
  /// @return s Clock storage pointer
  function _cs() internal pure returns (ClockStorage storage s) {
    bytes32 slot = _CLOCK_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
