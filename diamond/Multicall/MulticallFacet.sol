// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IMulticall} from "./IMulticall.sol";

contract MulticallFacet is IMulticall {
  function multicall(bytes[] calldata data)
    external
    override
    returns (bytes[] memory results)
  {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = _functionDelegateCall(address(this), data[i]);
    }
    return results;
  }

  function _functionDelegateCall(address target, bytes memory data)
    private
    returns (bytes memory)
  {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return
      Address.verifyCallResult(
        success,
        returndata,
        "MulticallFacet: Low-level delegate call failed"
      );
  }
}
