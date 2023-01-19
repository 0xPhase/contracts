// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VaultBase} from "../diamond/VaultBase.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {IAdapter} from "../IAdapter.sol";

struct WETHAdapterData {
  bool isETH;
}

contract WETHAdapter is VaultBase, IAdapter {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IAdapter
  function deposit(
    uint256,
    uint256 amount,
    uint256 value,
    bytes memory data
  ) external override {
    WETHAdapterData memory adapterData = abi.decode(data, (WETHAdapterData));

    if (adapterData.isETH) {
      require(
        value == amount,
        "WETHAdapter: Message value must equal deposit amount"
      );

      IWETH(address(_s.asset)).deposit{value: amount}();
    } else {
      require(value == 0, "WETHAdapter: Message value not 0");

      _s.asset.safeTransferFrom(msg.sender, address(this), amount);
    }
  }

  /// @inheritdoc	IAdapter
  function withdraw(
    uint256,
    uint256 amount,
    bytes memory data
  ) external override {
    WETHAdapterData memory adapterData = abi.decode(data, (WETHAdapterData));

    if (adapterData.isETH) {
      IWETH(address(_s.asset)).withdraw(amount);
      payable(msg.sender).transfer(amount);
    } else {
      _s.asset.safeTransfer(msg.sender, amount);
    }
  }
}
