// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {CloneDiamond} from "../diamond/Clone/CloneDiamond.sol";
import {IFactory} from "./IFactory.sol";

contract CloneDiamondFactory is IFactory {
  /// @inheritdoc	IFactory
  function create(
    bytes calldata constructorData
  ) external override returns (address created) {
    (
      address owner_,
      address target_,
      address initializer_,
      bytes memory initializerData_
    ) = abi.decode(constructorData, (address, address, address, bytes));

    created = address(
      new CloneDiamond(owner_, target_, initializer_, initializerData_)
    );

    emit ContractCreated(msg.sender, created);
  }

  /// @inheritdoc	IFactory
  function create2(
    bytes calldata constructorData,
    bytes32 salt
  ) external override returns (address created) {
    (
      address owner_,
      address target_,
      address initializer_,
      bytes memory initializerData_
    ) = abi.decode(constructorData, (address, address, address, bytes));

    created = address(
      new CloneDiamond{salt: salt}(
        owner_,
        target_,
        initializer_,
        initializerData_
      )
    );

    emit ContractCreated2(msg.sender, salt, created);
  }
}
