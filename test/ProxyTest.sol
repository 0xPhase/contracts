// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ProxyOwnable} from "../proxy/utils/ProxyOwnable.sol";

interface IProxyTest {
  function setTest(uint256 val) external;

  function readTest() external view returns (uint256);
}

abstract contract BaseProxyTest is IProxyTest {
  uint256 internal _override;

  function setTest(uint256 val) external virtual override {
    _override = val;
  }
}

contract ProxyTestA is BaseProxyTest {
  function readTest() external view override returns (uint256) {
    if (_override == 0) return 1;
    return _override;
  }
}

contract ProxyTestB is BaseProxyTest {
  function readTest() external view override returns (uint256) {
    if (_override == 0) return 2;
    return _override;
  }
}

contract ProxyTestC is BaseProxyTest {
  function readTest() external view override returns (uint256) {
    if (_override == 0) return 3;
    return _override;
  }
}

contract ProxyTestOwnable is ProxyOwnable {
  function initializeOwner() external {
    // Meant to be called in initializer
    _initializeOwnership(msg.sender);
  }
}

contract ProxyTestInitializable is ProxyInitializable {
  uint256 public counter;

  function initializeTest() external initialize("test") {
    counter++;
  }
}
