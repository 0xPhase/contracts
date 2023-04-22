// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IFactory {
  /// @notice Event emitted when a contract is created with the factory
  /// @param creator The message sender
  /// @param created The created contract
  event ContractCreated(address indexed creator, address created);

  /// @notice Event emitted when a contract is created with the factory
  /// @param creator The message sender
  /// @param salt The salt
  /// @param created The created contract
  event ContractCreated2(
    address indexed creator,
    bytes32 indexed salt,
    address created
  );

  /// @notice Creates a new contract
  /// @param constructorData The constructor data passed to the new contract
  /// @return created The created contract address
  function create(
    bytes calldata constructorData
  ) external returns (address created);

  /// @notice Creates a new contract with a salt
  /// @param constructorData The constructor data passed to the new contract
  /// @param salt The salt
  /// @return created The created contract address
  function create2(
    bytes calldata constructorData,
    bytes32 salt
  ) external returns (address created);
}
