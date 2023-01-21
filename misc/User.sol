// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {CallLib} from "../lib/CallLib.sol";

contract User {
  /// @notice only used for tests!
  function batchCall(
    bytes calldata data
  ) external payable returns (bytes memory result) {
    uint256 offset = 0;

    while (offset < data.length) {
      uint256 value = 0;

      address target = address(bytes20(data[offset:offset + 20]));
      offset += 20;

      uint256 callDataLength = uint24(bytes3(data[offset:offset + 3]));
      offset += 3;

      if (callDataLength & 0x800000 != 0) {
        value = uint128(bytes16(data[offset:offset + 16]));
        offset += 16;
        callDataLength &= 0x7FFFFF;
      }

      bytes memory callResult = CallLib.callFunc(
        target,
        data[offset:offset + callDataLength],
        value
      );

      offset += callDataLength;
      result = abi.encodePacked(result, uint32(callResult.length), callResult);
    }
  }

  /// @notice only used for tests!
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return User.onERC721Received.selector;
  }
}
