// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {StringLib} from "./StringLib.sol";

library CallLib {
  using StringLib for string;

  function callFunc(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return callFunc(target, data, 0);
  }

  function callFunc(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "CallLib: insufficient balance for call"
    );

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, target, "call");
  }

  function delegateCallFunc(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, target, "delegateCall");
  }

  function verifyCallResult(
    bool success,
    bytes memory result,
    address target,
    string memory method
  ) internal pure returns (bytes memory) {
    if (success) {
      return result;
    }

    if (result.length == 0)
      revert(
        string("CallLib: Function ")
          .append(method)
          .append(" reverted silently for ")
          .append(StringLib.toHex(bytes32(uint256(uint160(target)) << 96)))
      );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      revert(add(32, result), mload(result))
    }
  }
}
