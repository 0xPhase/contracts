// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {AdminUpgradeableProxy} from "../proxy/proxies/AdminUpgradeableProxy.sol";
import {IFactory} from "./IFactory.sol";

contract AdminUpgradeableProxyFactory is IFactory {
  /// @inheritdoc	IFactory
  function create(
    bytes calldata constructorData
  ) external override returns (address created) {
    (address owner_, address target_, bytes memory initialCall_) = abi.decode(
      constructorData,
      (address, address, bytes)
    );

    created = address(new AdminUpgradeableProxy(owner_, target_, initialCall_));

    emit ContractCreated(msg.sender, created);
  }

  /// @inheritdoc	IFactory
  function create2(
    bytes calldata constructorData,
    bytes32 salt
  ) external override returns (address created) {
    (address owner_, address target_, bytes memory initialCall_) = abi.decode(
      constructorData,
      (address, address, bytes)
    );

    created = address(
      new AdminUpgradeableProxy{salt: salt}(owner_, target_, initialCall_)
    );

    emit ContractCreated2(msg.sender, salt, created);
  }
}
