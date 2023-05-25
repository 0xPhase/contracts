// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {CallLib} from "../lib/CallLib.sol";

contract Manager is Ownable {
  bytes internal constant _OVERFLOW_MESSAGE =
    abi.encode("Manager: Call result length too long");

  uint256 internal constant _ADDRESS_OFFSET = 20;
  uint256 internal constant _CALLDATA_LENGTH_OFFSET = 3;
  uint256 internal constant _VALUE_OFFSET = 16;

  /// @notice Does a batch of calls
  /// @param data The compressed and optimized call list
  /// @return result The combined results of all the calls
  /// @custom:protected onlyOwner
  function batchCall(
    bytes calldata data
  ) external payable onlyOwner returns (bytes memory result) {
    uint256 offset = 0;

    while (offset < data.length) {
      uint256 value = 0;

      address target = address(bytes20(data[offset:offset + _ADDRESS_OFFSET]));
      offset += _ADDRESS_OFFSET;

      uint256 callDataLength = uint24(
        bytes3(data[offset:offset + _CALLDATA_LENGTH_OFFSET])
      );
      offset += _CALLDATA_LENGTH_OFFSET;

      if (callDataLength & 0x800000 != 0) {
        value = uint128(bytes16(data[offset:offset + _VALUE_OFFSET]));
        offset += _VALUE_OFFSET;
        callDataLength &= 0x7FFFFF;
      }

      bytes memory callResult = CallLib.callFunc(
        target,
        data[offset:offset + callDataLength],
        value
      );

      offset += callDataLength;

      result = callResult.length > type(uint32).max
        ? abi.encodePacked(
          result,
          uint32(_OVERFLOW_MESSAGE.length),
          _OVERFLOW_MESSAGE
        )
        : abi.encodePacked(result, uint32(callResult.length), callResult);
    }
  }
}
