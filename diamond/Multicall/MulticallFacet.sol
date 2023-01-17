// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {CallLib} from "../../lib/CallLib.sol";
import {IMulticall} from "./IMulticall.sol";

contract MulticallFacet is IMulticall {
  /// @inheritdoc	IMulticall
  function multicall(
    bytes[] calldata data
  ) external override returns (bytes[] memory results) {
    results = new bytes[](data.length);

    for (uint256 i = 0; i < data.length; i++) {
      results[i] = CallLib.delegateCallFunc(address(this), data[i]);
    }

    return results;
  }
}
