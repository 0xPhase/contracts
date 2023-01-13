// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ClockStorage {
  uint256 lastTime;
}

interface IClock {
  function time() external view returns (uint256);

  function lastTime() external view returns (uint256);
}
