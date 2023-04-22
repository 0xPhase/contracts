// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ITreasury, TokenInfo, Cause} from "./ITreasury.sol";
import {TreasuryStorageV1} from "./TreasuryStorageV1.sol";
import {CallLib} from "../lib/CallLib.sol";

contract TreasuryV1 is TreasuryStorageV1 {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  address public constant override ETH_ADDRESS =
    0x1111111111111111111111111111111111111111;

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /// @inheritdoc	ITreasury
  function donate(
    string memory cause,
    address token,
    uint256 amount
  ) external payable override {
    donate(keccak256(bytes(cause)), token, amount);
  }

  /// @inheritdoc	ITreasury
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function spend(
    string memory cause,
    address token,
    uint256 amount,
    address to
  ) external override {
    spend(keccak256(bytes(cause)), token, amount, to);
  }

  /// @inheritdoc	ITreasury
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function increaseUnsafe(
    bytes32 cause,
    address token,
    uint256 amount
  ) external override onlyRole(MANAGER_ROLE) {
    _changeToken(cause, token, amount, true);
  }

  /// @notice Donates any extra tokens in the current address to the cause
  /// @param cause The cause to donate to
  /// @param token The donated token address (ETH_ADDRESS for ETH)
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function donateExtra(
    bytes32 cause,
    address token
  ) external onlyRole(MANAGER_ROLE) {
    uint256 balance = token == ETH_ADDRESS
      ? address(this).balance
      : IERC20(token).balanceOf(address(this));

    uint256 difference = balance - _globalCause.token[token].balance;

    require(difference > 0, "TreasuryV1: No extra tokens");

    _changeToken(cause, token, difference, true);

    emit Donated(cause, token, difference);
  }

  /// @inheritdoc	ITreasury
  function tokenBalance(
    address token
  ) external view override returns (uint256) {
    return _globalCause.token[token].balance;
  }

  /// @inheritdoc	ITreasury
  function tokenBalance(
    string memory cause,
    address token
  ) external view override returns (uint256) {
    return tokenBalance(keccak256(bytes(cause)), token);
  }

  /// @inheritdoc	ITreasury
  function tokens() external view override returns (address[] memory arr) {
    uint256 length = _globalCause.tokens.length();
    arr = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = _globalCause.tokens.at(i);
    }
  }

  /// @inheritdoc	ITreasury
  function tokens(
    string memory cause
  ) external view override returns (address[] memory) {
    return tokens(keccak256(bytes(cause)));
  }

  /// @inheritdoc	ITreasury
  function donate(
    bytes32 cause,
    address token,
    uint256 amount
  ) public payable override {
    require(amount > 0, "TreasuryV1: Cannot donate 0 tokens");

    uint256 increase;

    if (token == ETH_ADDRESS) {
      require(amount == msg.value, "TreasuryV1: Message value mismatch");
      
      increase = msg.value;
    } else {
      require(msg.value == 0, "TreasuryV1: Message value cannot be over 0");

      IERC20 ercToken = IERC20(token);
      uint256 original = ercToken.balanceOf(address(this));

      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

      increase = ercToken.balanceOf(address(this)) - original;
    }

    _changeToken(cause, token, increase, true);

    emit Donated(cause, token, increase);
  }

  /// @inheritdoc	ITreasury
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function spend(
    bytes32 cause,
    address token,
    uint256 amount,
    address to
  ) public override onlyRole(MANAGER_ROLE) {
    require(
      tokenBalance(cause, token) >= amount,
      "TreasuryV1: Not enough tokens in cause"
    );

    _changeToken(cause, token, amount, false);

    if (token == ETH_ADDRESS) {
      payable(to).call{value: amount}("");
    } else {
      IERC20(token).safeTransfer(to, amount);
    }

    emit Spent(cause, token, to, amount);
  }

  /// @inheritdoc	ITreasury
  function tokenBalance(
    bytes32 cause,
    address token
  ) public view override returns (uint256) {
    return _cause[cause].token[token].balance;
  }

  /// @inheritdoc	ITreasury
  function tokens(
    bytes32 cause
  ) public view override returns (address[] memory arr) {
    Cause storage strCause = _cause[cause];
    uint256 length = strCause.tokens.length();
    arr = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = strCause.tokens.at(i);
    }
  }

  function _changeToken(
    bytes32 cause,
    address tokenAddress,
    uint256 amount,
    bool adding
  ) internal {
    TokenInfo storage token = _cause[cause].token[tokenAddress];
    TokenInfo storage global = _globalCause.token[tokenAddress];

    if (adding) {
      token.balance += amount;
      global.balance += amount;
    } else {
      token.balance -= amount;
      global.balance -= amount;
    }

    _checkSet(token, _cause[cause], tokenAddress);
    _checkSet(global, _globalCause, tokenAddress);
  }

  function _checkSet(
    TokenInfo storage token,
    Cause storage cause,
    address tokenAddress
  ) internal {
    if (token.balance == 0 && token.set) {
      token.set = false;
      cause.tokens.remove(tokenAddress);
    } else if (token.balance > 0 && !token.set) {
      token.set = true;
      cause.tokens.add(tokenAddress);
    }
  }
}
