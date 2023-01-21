// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IDB, DBV1Storage} from "../IDB.sol";

contract DBV1 is DBV1Storage {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(bytes32 key, address value) external override onlyOwner {
    add(key, bytes32(bytes20(value)));
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function set(bytes32 key, address value) external override onlyOwner {
    set(key, bytes32(bytes20(value)));
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(
    bytes32[] memory keys,
    address value
  ) external override onlyOwner {
    add(keys, bytes32(bytes20(value)));
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(
    bytes32 key,
    bytes32[] memory values
  ) external override onlyOwner {
    Set storage keySet = _keys[key];
    EnumerableSet.Bytes32Set storage valueList = _valueList;

    for (uint256 i = 0; i < values.length; i++) {
      bytes32 value = values[i];
      Set storage valueSet = _values[value];

      keySet.exists = true;
      valueSet.exists = true;

      keySet.list.add(value);
      valueSet.list.add(key);
      valueList.add(value);
    }
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(
    bytes32 key,
    address[] memory values
  ) external override onlyOwner {
    for (uint256 i = 0; i < values.length; i++) {
      add(key, bytes32(bytes20(values[i])));
    }
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function removeValue(bytes32 value) external override onlyOwner {
    if (!hasValue(value)) return;

    Set storage valueSet = _values[value];
    EnumerableSet.Bytes32Set storage list = valueSet.list;

    while (list.length() > 0) {
      bytes32 key = list.at(0);
      Set storage keySet = _keys[key];

      keySet.list.remove(value);
      list.remove(key);

      if (keySet.list.length() == 0) {
        keySet.exists = false;
      }
    }

    valueSet.exists = false;
    _valueList.remove(value);
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function removePair(bytes32 key, bytes32 value) external override onlyOwner {
    if (!hasPair(key, value)) return;

    Set storage keySet = _keys[key];
    Set storage valueSet = _values[value];

    keySet.list.remove(value);
    valueSet.list.remove(key);
    _valueList.remove(value);

    if (keySet.list.length() == 0) {
      valueSet.exists = false;
    }

    if (valueSet.list.length() == 0) {
      valueSet.exists = false;
    }
  }

  /// @inheritdoc	IDB
  function digest(
    Opcode memory opcode
  ) external view override returns (bytes32[] memory result) {
    uint256 length = _valueList.length();
    uint256[] memory digested = _digest(opcode);
    uint256 totalTruthy = 0;

    for (uint256 i = 0; i < length; i++) {
      if (digested[i] > 0) {
        totalTruthy++;
      }
    }

    uint256 counter = 0;
    result = new bytes32[](totalTruthy);

    for (uint256 i = 0; i < length; i++) {
      if (digested[i] > 0) {
        result[counter] = _valueList.at(i);
        counter++;
      }
    }
  }

  /// @inheritdoc	IDB
  function getValue(
    string memory key
  ) external view override returns (bytes32) {
    return getValueB32(keccak256(abi.encodePacked(key)));
  }

  /// @inheritdoc	IDB
  function getAddress(
    string memory key
  ) external view override returns (address) {
    return getAddressB32(keccak256(abi.encodePacked(key)));
  }

  /// @inheritdoc	IDB
  function getValues(
    bytes32 key
  ) external view override returns (bytes32[] memory arr) {
    Set storage keySet = _keys[key];
    if (!keySet.exists) return new bytes32[](0);

    EnumerableSet.Bytes32Set storage list = keySet.list;
    uint256 length = list.length();

    arr = new bytes32[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = list.at(i);
    }
  }

  /// @inheritdoc	IDB
  function getKeys(
    bytes32 value
  ) external view override returns (bytes32[] memory arr) {
    Set storage valueSet = _values[value];
    if (!valueSet.exists) return new bytes32[](0);

    EnumerableSet.Bytes32Set storage list = valueSet.list;
    uint256 length = list.length();

    arr = new bytes32[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = list.at(i);
    }
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(bytes32 key, bytes32 value) public override onlyOwner {
    Set storage keySet = _keys[key];
    Set storage valueSet = _values[value];

    keySet.exists = true;
    valueSet.exists = true;

    keySet.list.add(value);
    valueSet.list.add(key);
    _valueList.add(value);
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function add(bytes32[] memory keys, bytes32 value) public override onlyOwner {
    Set storage valueSet = _values[value];

    for (uint256 i = 0; i < keys.length; i++) {
      bytes32 key = keys[i];
      Set storage keySet = _keys[key];

      keySet.exists = true;
      valueSet.exists = true;

      keySet.list.add(value);
      valueSet.list.add(key);
    }

    _valueList.add(value);
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function set(bytes32 key, bytes32 value) public override onlyOwner {
    removeKey(key);
    add(key, value);
  }

  /// @inheritdoc	IDB
  /// @custom:protected onlyOwner
  function removeKey(bytes32 key) public override onlyOwner {
    if (!hasKey(key)) return;

    Set storage keySet = _keys[key];
    EnumerableSet.Bytes32Set storage list = keySet.list;

    while (list.length() > 0) {
      bytes32 value = list.at(0);
      Set storage valueSet = _values[value];

      valueSet.list.remove(key);
      list.remove(value);

      if (valueSet.list.length() == 0) {
        valueSet.exists = false;
        _valueList.remove(value);
      }
    }

    keySet.exists = false;
  }

  /// @inheritdoc	IDB
  function getValueB32(bytes32 key) public view override returns (bytes32) {
    Set storage keySet = _keys[key];
    if (!keySet.exists) return bytes32(0);

    EnumerableSet.Bytes32Set storage list = keySet.list;
    if (list.length() == 0) return bytes32(0);

    return list.at(0);
  }

  /// @inheritdoc	IDB
  function getAddressB32(bytes32 key) public view override returns (address) {
    return address(bytes20(getValueB32(key)));
  }

  /// @inheritdoc	IDB
  function hasKey(bytes32 key) public view override returns (bool) {
    return _keys[key].exists;
  }

  /// @inheritdoc	IDB
  function hasValue(bytes32 value) public view override returns (bool) {
    return _values[value].exists;
  }

  /// @inheritdoc	IDB
  function hasPair(
    bytes32 key,
    bytes32 value
  ) public view override returns (bool) {
    if (!hasKey(key) || !hasValue(value)) return false;
    return _keys[key].list.contains(value);
  }

  /// @notice Executes an opcode and its descendants against every value in the DB. It is effectively a custom VM, being able to do complex computation against all values in the DB
  /// @param opcode The opcode to execute
  /// @return mem The resulting memory
  function _digest(
    Opcode memory opcode
  ) internal view returns (uint256[] memory mem) {
    OpcodeType op = opcode.opcode;
    bytes memory data = opcode.data;
    uint256 length = _valueList.length();

    mem = new uint256[](length);

    if (op == OpcodeType.VALUE) {
      ValueOpcode memory opdata = abi.decode(data, (ValueOpcode));

      for (uint256 i = 0; i < length; i++) {
        mem[i] = opdata.value;
      }
    } else if (op == OpcodeType.LENGTH) {
      for (uint256 i = 0; i < length; i++) {
        mem[i] = _values[_valueList.at(i)].list.length();
      }
    } else if (op == OpcodeType.CONTAINS) {
      ContainsOpcode memory opdata = abi.decode(data, (ContainsOpcode));
      uint256 klength = opdata.keys.length;

      for (uint256 i = 0; i < length; i++) {
        EnumerableSet.Bytes32Set storage keys = _values[_valueList.at(i)].list;
        bool contains = true;

        for (uint256 j = 0; j < klength; j++) {
          if (keys.contains(opdata.keys[j])) continue;
          contains = false;
          break;
        }

        mem[i] = contains ? 1 : 0;
      }
    } else if (op == OpcodeType.INVERSE) {
      InverseOpcode memory opdata = abi.decode(data, (InverseOpcode));
      uint256[] memory digested = _digest(opdata.value);

      for (uint256 i = 0; i < length; i++) {
        mem[i] = digested[i] > 0 ? 0 : 1;
      }
    } else if (op >= OpcodeType.ADD && op <= OpcodeType.DIV) {
      ArithmeticOperatorOpcode memory opdata = abi.decode(
        data,
        (ArithmeticOperatorOpcode)
      );

      uint256 olength = opdata.values.length;

      for (uint256 i = 0; i < olength; i++) {
        uint256[] memory digested = _digest(opdata.values[i]);

        for (uint256 j = 0; j < length; j++) {
          if (i == 0) {
            mem[j] = digested[j];
            continue;
          }

          if (op == OpcodeType.ADD) {
            mem[j] = mem[j] + digested[j];
          } else if (op == OpcodeType.SUB) {
            mem[j] = mem[j] - digested[j];
          } else if (op == OpcodeType.MUL) {
            mem[j] = mem[j] * digested[j];
          } else if (op == OpcodeType.DIV) {
            mem[j] = mem[j] / digested[j];
          }
        }
      }
    } else if (op >= OpcodeType.EQ && op <= OpcodeType.LTE) {
      ComparatorOpcode memory opdata = abi.decode(data, (ComparatorOpcode));

      uint256[] memory a = _digest(opdata.a);
      uint256[] memory b = _digest(opdata.b);

      for (uint256 i = 0; i < length; i++) {
        bool result;

        if (op == OpcodeType.EQ) {
          result = a[i] == b[i];
        } else if (op == OpcodeType.GT) {
          result = a[i] > b[i];
        } else if (op == OpcodeType.LT) {
          result = a[i] < b[i];
        } else if (op == OpcodeType.NEQ) {
          result = a[i] != b[i];
        } else if (op == OpcodeType.GTE) {
          result = a[i] >= b[i];
        } else if (op == OpcodeType.LTE) {
          result = a[i] <= b[i];
        }

        mem[i] = result ? 1 : 0;
      }
    } else if (op >= OpcodeType.AND && op <= OpcodeType.NAND) {
      GateOpcode memory opdata = abi.decode(data, (GateOpcode));

      uint256 olength = opdata.values.length;

      for (uint256 i = 0; i < olength; i++) {
        uint256[] memory digested = _digest(opdata.values[i]);

        for (uint256 j = 0; j < length; j++) {
          if (i == 0) {
            if (op == OpcodeType.NAND) {
              mem[j] = (digested[j] > 0 ? 0 : 1);
            } else {
              mem[j] = (digested[j] > 0 ? 1 : 0);
            }

            continue;
          }

          if (op == OpcodeType.AND) {
            mem[j] = ((mem[j] > 0) && (digested[j] > 0)) ? 1 : 0;
          } else if (op == OpcodeType.OR) {
            mem[j] = ((mem[j] > 0) || (digested[j] > 0)) ? 1 : 0;
          } else if (op == OpcodeType.NAND) {
            mem[j] = ((mem[j] > 0) && !(digested[j] > 0)) ? 1 : 0;
          }
        }
      }
    }
  }
}
