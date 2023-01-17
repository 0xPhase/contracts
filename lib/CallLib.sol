// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library CallLib {
  /// @notice Calls an external function without value
  /// @param target The target contract
  /// @param data The calldata
  /// @return The result of the call
  function callFunc(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    return callFunc(target, data, 0);
  }

  /// @notice Calls an external function with value
  /// @param target The target contract
  /// @param data The calldata
  /// @param value The value sent with the call
  /// @return The result of the call
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

  /// @notice Calls an external function in current storage
  /// @param target The target contract
  /// @param data The calldata
  /// @return The result of the call
  function delegateCallFunc(
    address target,
    bytes memory data
  ) internal returns (bytes memory) {
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);

    return verifyCallResult(success, returndata, target, "delegateCall");
  }

  /// @notice Verifies if a contract call succeeded
  /// @param success If the call itself succeeded
  /// @param result The result of the call
  /// @param target The called contract
  /// @param method The method type, call or delegateCall
  /// @return The result of the call
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
        string.concat(
          "CallLib: Function ",
          method,
          " reverted silently for ",
          Strings.toHexString(target)
        )
      );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      revert(add(32, result), mload(result))
    }
  }
}
