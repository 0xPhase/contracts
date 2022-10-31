// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AdminUpgradeableProxy} from "../proxy/proxies/AdminUpgradeableProxy.sol";
import {ITreasury, TreasuryStorageV1} from "../treasury/ITreasury.sol";
import {TreasuryV1} from "../treasury/TreasuryV1.sol";
import {CallLib} from "../lib/CallLib.sol";

contract Manager is Ownable {
  mapping(bytes32 => address) public contracts;
  address public dev;

  event ContractSet(bytes32 indexed id, address addr);

  event NewDev(address indexed setter, address newDev);

  modifier onlyAuthorized() {
    require(
      msg.sender == address(this) || msg.sender == owner(),
      "Manager: Caller not authorized"
    );

    _;
  }

  constructor(address dev_) {
    dev = dev_;
  }

  function batchCall(bytes calldata data)
    external
    payable
    onlyAuthorized
    returns (bytes memory result)
  {
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

  function setDev(address newDev) external {
    require(
      msg.sender == address(this) || msg.sender == dev,
      "Manager: Not the dev"
    );

    dev = newDev;

    emit NewDev(msg.sender, newDev);
  }

  function setContract(bytes32 id, address addr) external onlyAuthorized {
    contracts[id] = addr;

    emit ContractSet(id, addr);
  }

  function getContract(string memory name) external view returns (address) {
    return contracts[keccak256(bytes(name))];
  }

  function contractExists(bytes32 id) external view returns (bool) {
    return contracts[id] != address(0);
  }
}
