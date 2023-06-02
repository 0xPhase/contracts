// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20, ERC20Burnable {
  uint8 internal _decimals;

  // solhint-disable-next-line no-empty-blocks
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20(string.concat("Test ", name_), string.concat("t", symbol_)) {
    _decimals = decimals_;
  }

  function mintAny(address to, uint256 amount) external {
    _mint(to, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
}
