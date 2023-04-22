// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {CallLib} from "../../lib/CallLib.sol";
import {IMulticall} from "./IMulticall.sol";

contract MulticallFacet is IMulticall {
  /// @inheritdoc	IMulticall
  /// @custom:never payable
  function multicall(
    bytes[] calldata data
  ) external override returns (bytes[] memory results) {
    results = new bytes[](data.length);

    for (uint256 i = 0; i < data.length; ) {
      results[i] = CallLib.delegateCallFunc(address(this), data[i]);

      unchecked {
        i++;
      }
    }

    return results;
  }
}
