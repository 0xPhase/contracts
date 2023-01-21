// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSDC is ERC20, ERC20Burnable {
  mapping(address => uint256) public counter;

  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20("Test Circle USD", "tUSDC") {}

  function mint(address to) external {
    require(counter[to] <= 2, "TestUSDC: Already minted max amount");

    _mint(to, 200_000 * (uint256(10) ** uint256(decimals())));

    counter[to]++;
  }

  function mintAny(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return 6;
  }
}
