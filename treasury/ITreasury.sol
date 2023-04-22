// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct TokenInfo {
  uint256 balance;
  bool set;
}

struct Cause {
  mapping(address => TokenInfo) token;
  EnumerableSet.AddressSet tokens;
}

interface ITreasury {
  /// @notice Event emitted when a token or ETH is donated to a cause
  /// @param cause The cause that was donated to
  /// @param token The donated token address (ETH_ADDRESS for ETH)
  /// @param amount The donation amount
  event Donated(bytes32 indexed cause, address indexed token, uint256 amount);

  /// @notice Event emitted when a token or ETH is spent by a cause
  /// @param cause The cause that spent
  /// @param token The spent token address (ETH_ADDRESS for ETH)
  /// @param to The spend target address
  /// @param amount The spent amount
  event Spent(
    bytes32 indexed cause,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /// @notice Donates a token or ETH to a cause
  /// @param cause The cause to donate to
  /// @param token The donated token address (ETH_ADDRESS for ETH)
  /// @param amount The donation amount
  function donate(
    bytes32 cause,
    address token,
    uint256 amount
  ) external payable;

  /// @notice Donates a token or ETH to a cause
  /// @param cause The cause to donate to
  /// @param token The donated token address (ETH_ADDRESS for ETH)
  /// @param amount The donation amount
  function donate(
    string memory cause,
    address token,
    uint256 amount
  ) external payable;

  /// @notice Spends a token or ETH from a cause
  /// @param cause The cause that's spending
  /// @param token The spent token address (ETH_ADDRESS for ETH)
  /// @param amount The spent amount
  /// @param to The spend target address
  function spend(
    bytes32 cause,
    address token,
    uint256 amount,
    address to
  ) external;

  /// @notice Spends a token or ETH from a cause
  /// @param cause The cause that's spending
  /// @param token The spent token address (ETH_ADDRESS for ETH)
  /// @param amount The spent amount
  /// @param to The spend target address
  function spend(
    string memory cause,
    address token,
    uint256 amount,
    address to
  ) external;

  /// @notice Increases the balance for a token or ETH for a cause without transferring it in
  /// @param cause The cause to increase for
  /// @param token The token address to increase (ETH_ADDRESS for ETH)
  /// @param amount The amount to increase
  function increaseUnsafe(
    bytes32 cause,
    address token,
    uint256 amount
  ) external;

  /// @notice Returns the total token or ETH balance in the treasury
  /// @param token The token address (ETH_ADDRESS for ETH)
  /// @return The balance for the token or ETH
  function tokenBalance(address token) external view returns (uint256);

  /// @notice Returns the total token or ETH balance in the treasury for the cause
  /// @param cause The cause to check for
  /// @param token The token address (ETH_ADDRESS for ETH)
  /// @return The balance for the token or ETH
  function tokenBalance(
    bytes32 cause,
    address token
  ) external view returns (uint256);

  /// @notice Returns the total token or ETH balance in the treasury for the cause
  /// @param cause The cause to check for
  /// @param token The token address (ETH_ADDRESS for ETH)
  /// @return The balance for the token or ETH
  function tokenBalance(
    string memory cause,
    address token
  ) external view returns (uint256);

  /// @notice Returns all tokens in the treasury
  /// @return The list of token addresses
  function tokens() external view returns (address[] memory);

  /// @notice Returns all tokens in the treasury for the cause
  /// @param cause The cause to check for
  /// @return The list of token addresses
  function tokens(bytes32 cause) external view returns (address[] memory);

  /// @notice Returns all tokens in the treasury for the cause
  /// @param cause The cause to check for
  /// @return The list of token addresses
  function tokens(string memory cause) external view returns (address[] memory);

  /// @notice Returns the reserved address to represent native ETH
  /// @return The reserved ETH address
  // solhint-disable-next-line func-name-mixedcase
  function ETH_ADDRESS() external view returns (address);
}
