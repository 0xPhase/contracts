// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AdminUpgradeableProxy} from "../proxy/proxies/AdminUpgradeableProxy.sol";
import {IFactory} from "./IFactory.sol";

contract AdminUpgradeableProxyFactory is IFactory {
  function create(bytes memory constructorData)
    external
    override
    returns (address created)
  {
    (address owner_, address target_, bytes memory initialCall_) = abi.decode(
      constructorData,
      (address, address, bytes)
    );

    created = address(new AdminUpgradeableProxy(owner_, target_, initialCall_));

    emit ContractCreated(msg.sender, created);
  }
}
