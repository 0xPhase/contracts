// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyOwnable} from "../proxy/utils/ProxyOwnable.sol";
import {IDB, Set} from "./IDB.sol";

abstract contract DBV1Storage is ProxyOwnable, IDB {
  mapping(bytes32 => Set) internal _keys;
  mapping(bytes32 => Set) internal _values;
  EnumerableSet.Bytes32Set internal _valueList;

  /// @notice Disables initialization on the target contract
  constructor() {
    _disableInitialization();
  }
}
