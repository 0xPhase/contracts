// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {SlotLib} from "../../lib/SlotLib.sol";
import {ClockStorage} from "./IClock.sol";

abstract contract ClockBase {
  modifier updateTime() {
    _updateTime();
    _;
  }

  function _updateTime() internal {
    ClockStorage storage data = _storage();

    if (block.timestamp > data.lastTime) {
      data.lastTime = block.timestamp;
    }
  }

  function _time() internal view returns (uint256) {
    return Math.max(block.timestamp, _lastTime());
  }

  function _lastTime() internal view returns (uint256) {
    ClockStorage storage data = _storage();
    return data.lastTime;
  }

  function _storage() internal pure returns (ClockStorage storage data) {
    bytes32 slot = SlotLib.slot(string("clock.storage"));

    // solhint-disable-next-line no-inline-assembly
    assembly {
      data.slot := slot
    }
  }
}
