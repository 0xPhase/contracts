// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library ByteStorageLib {
  function writeBytes(bytes32 slot, bytes memory data) internal {
    uint256 mem = uint256(slot);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let orig := mload(data)
      let len := add(div(orig, 32), 1)

      sstore(mem, len)
      sstore(add(mem, 0x20), orig)

      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 1)
      } {
        sstore(
          add(mem, mul(0x20, add(2, i))),
          mload(add(data, mul(0x20, add(1, i))))
        )
      }
    }
  }

  function clearBytes(bytes32 slot) internal {
    uint256 mem = uint256(slot);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let len := sload(mem)

      for {
        let i := 0
      } lt(i, add(2, len)) {
        i := add(i, 1)
      } {
        sstore(add(mem, mul(0x20, i)), 0)
      }
    }
  }

  function readBytes(bytes32 slot) internal view returns (bytes memory data) {
    uint256 mem = uint256(slot);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let len := sload(mem)
      let rLen := sload(add(mem, 0x20))
      data := mload(0x40)

      mstore(0x40, add(data, and(add(add(rLen, 0x20), 0x1f), not(0x1f))))
      mstore(data, sload(add(mem, 0x20)))

      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 1)
      } {
        mstore(
          add(data, mul(0x20, add(1, i))),
          sload(add(mem, mul(0x20, add(2, i))))
        )
      }
    }
  }

  function isEmpty(bytes32 slot) internal view returns (bool empty) {
    uint256 mem = uint256(slot);

    // solhint-disable-next-line no-inline-assembly
    assembly {
      empty := iszero(sload(mem))
    }
  }
}
