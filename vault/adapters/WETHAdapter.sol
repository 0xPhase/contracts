// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VaultBase} from "../diamond/VaultBase.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {CallLib} from "../../lib/CallLib.sol";
import {IAdapter} from "../IAdapter.sol";

contract WETHAdapter is VaultBase, IAdapter {
  using SafeERC20 for IERC20;

  struct WETHAdapterData {
    bool isETH;
  }

  /// @inheritdoc	IAdapter
  function deposit(
    uint256,
    uint256 amount,
    bytes memory data
  ) external payable override {
    WETHAdapterData memory adapterData = abi.decode(data, (WETHAdapterData));

    if (adapterData.isETH) {
      require(
        msg.value == amount,
        "WETHAdapter: Message value must equal deposit amount"
      );

      IWETH(address(_s().asset)).deposit{value: amount}();
    } else {
      require(msg.value == 0, "WETHAdapter: Message value cannot be 0");

      _s().asset.safeTransferFrom(msg.sender, address(this), amount);
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
      IWETH(address(_s().asset)).withdraw(amount);
      CallLib.transferTo(msg.sender, amount);
    } else {
      _s().asset.safeTransfer(msg.sender, amount);
    }
  }
}
