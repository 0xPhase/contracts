// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyOwnable} from "../proxy/utils/ProxyOwnable.sol";

interface IDB {
  struct Set {
    bool exists;
    EnumerableSet.Bytes32Set list;
  }

  enum OpcodeType {
    VALUE,
    LENGTH,
    CONTAINS,
    INVERSE,
    ADD,
    SUB,
    MUL,
    DIV,
    EQ,
    GT,
    LT,
    NEQ,
    GTE,
    LTE,
    AND,
    OR,
    NAND
  }

  struct Opcode {
    OpcodeType opcode;
    bytes data;
  }

  struct ValueOpcode {
    uint256 value;
  }

  struct ContainsOpcode {
    bytes32[] keys;
  }

  struct InverseOpcode {
    Opcode value;
  }

  struct ArithmeticOperatorOpcode {
    Opcode[] values;
  }

  struct ComparatorOpcode {
    Opcode a;
    Opcode b;
  }

  struct GateOpcode {
    Opcode[] values;
  }

  function add(bytes32 key, bytes32 value) external;

  function add(bytes32 key, address value) external;

  function set(bytes32 key, bytes32 value) external;

  function set(bytes32 key, address value) external;

  function add(bytes32[] memory keys, bytes32 value) external;

  function add(bytes32[] memory keys, address value) external;

  function add(bytes32 key, bytes32[] memory values) external;

  function add(bytes32 key, address[] memory values) external;

  function removeKey(bytes32 key) external;

  function removeValue(bytes32 value) external;

  function removePair(bytes32 key, bytes32 value) external;

  function digest(Opcode memory opcode)
    external
    view
    returns (bytes32[] memory result);

  function getValueB32(bytes32 key) external view returns (bytes32);

  function getValue(string memory key) external view returns (bytes32);

  function getAddressB32(bytes32 key) external view returns (address);

  function getAddress(string memory key) external view returns (address);

  function getValues(bytes32 key) external view returns (bytes32[] memory arr);

  function getKeys(bytes32 value) external view returns (bytes32[] memory arr);

  function hasKey(bytes32 key) external view returns (bool);

  function hasValue(bytes32 value) external view returns (bool);

  function hasPair(bytes32 key, bytes32 value) external view returns (bool);
}

abstract contract DBV1Storage is ProxyOwnable, IDB {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  mapping(bytes32 => Set) internal _keys;
  mapping(bytes32 => Set) internal _values;
  EnumerableSet.Bytes32Set internal _valueList;
}
