// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ClockStorage, IClock} from "./IClock.sol";
import {ClockBase} from "./ClockBase.sol";

contract ClockFacet is ClockBase, IClock {
  /// @inheritdoc	IClock
  function time() public view override returns (uint256) {
    return _time();
  }

  /// @inheritdoc	IClock
  function lastTime() public view override returns (uint256) {
    return _lastTime();
  }
}
