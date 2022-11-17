// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IYield {
  event Deposit(uint256 indexed user, uint256 amount, uint256 shares);

  event Withdraw(uint256 indexed user, uint256 amount, uint256 shares);

  function receiveDeposit(uint256 user, uint256 amount) external;

  function receiveWithdraw(uint256 user, uint256 amount)
    external
    returns (uint256);

  function receiveFullWithdraw(uint256 user) external returns (uint256);

  function asset() external view returns (IERC20);

  function balance(uint256 user) external view returns (uint256);

  function shares(uint256 user) external view returns (uint256);
}
