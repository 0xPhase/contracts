// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IDB} from "../../../db/IDB.sol";
import {IYield} from "../../IYield.sol";

abstract contract YieldBase is Ownable, IYield {
  using SafeERC20 for IERC20;

  IERC20 public asset;

  /// @inheritdoc IYield
  /// @custom:protected onlyOwner
  function deposit(uint256 amount) external override onlyOwner {
    _onDeposit(amount);

    emit Deposit(amount);
  }

  /// @inheritdoc IYield
  /// @custom:protected onlyOwner
  function withdraw(
    uint256 amount
  ) external override onlyOwner returns (uint256) {
    _onWithdraw(amount);

    asset.safeTransfer(owner(), amount);

    emit Withdraw(amount);

    return amount;
  }

  /// @inheritdoc IYield
  /// @custom:protected onlyOwner
  function fullWithdraw() external override onlyOwner returns (uint256) {
    _onFullWithdraw();

    uint256 amount = asset.balanceOf(address(this));

    asset.safeTransfer(owner(), amount);
    emit Withdraw(amount);

    return amount;
  }

  /// @notice Initializes the yield base contract
  /// @param asset_ The yield asset
  function _initializeBaseYield(IERC20 asset_, address balancer) internal {
    asset = asset_;

    _transferOwnership(balancer);
  }

  /// @notice Ran when a deposit is made
  /// @param amount The deposit amount
  function _onDeposit(uint256 amount) internal virtual;

  /// @notice Ran when a withdraw is made
  /// @param amount The withdraw amount
  function _onWithdraw(uint256 amount) internal virtual;

  /// @notice Ran when a full withdraw is made
  function _onFullWithdraw() internal virtual;
}
