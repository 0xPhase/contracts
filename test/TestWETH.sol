// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestWETH is ERC20, ERC20Burnable {
  event Deposit(address indexed dst, uint256 wad);
  event Withdrawal(address indexed src, uint256 wad);

  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20("Test Wrapped ETH", "tWETH") {}

  function deposit() external payable {
    _mint(msg.sender, msg.value);

    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 wad) external {
    _burn(msg.sender, wad);
    payable(msg.sender).transfer(wad);

    emit Withdrawal(msg.sender, wad);
  }

  function mintAny(address to, uint256 amount) external {
    _mint(to, amount);
  }
}
