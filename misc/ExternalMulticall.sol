// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ExternalMulticall {
  function multicall(bytes[] calldata data)
    public
    returns (bytes[] memory results)
  {
    results = new bytes[](data.length);

    for (uint256 i = 0; i < data.length; i++) {
      bytes calldata itemData = data[i];
      bytes memory returnData;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        function allocate(length) -> pos {
          pos := mload(0x40)
          mstore(0x40, add(pos, length))
        }

        let target := allocate(0x20)
        let callData := allocate(sub(itemData.length, 20))

        calldatacopy(add(target, 12), itemData.offset, 20)

        calldatacopy(
          callData,
          add(itemData.offset, 20),
          sub(itemData.length, 20)
        )

        let result := call(
          gas(),
          mload(target),
          0,
          callData,
          sub(itemData.length, 20),
          0,
          0
        )

        returnData := allocate(add(returndatasize(), 0x21))

        mstore(returnData, add(returndatasize(), 0x01))
        mstore8(add(returnData, 0x20), result)

        returndatacopy(add(returnData, 0x21), 0, returndatasize())
      }

      results[i] = returnData;
    }
  }
}
