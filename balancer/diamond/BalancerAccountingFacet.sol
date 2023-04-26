// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerAccounting} from "../interfaces/IBalancerAccounting.sol";
import {Asset, Offset, Yield, BalancerStorage} from "../IBalancer.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {MathLib} from "../../lib/MathLib.sol";

contract BalancerAccountingFacet is BalancerBase, IBalancerAccounting {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IBalancerAccounting
  /// @custom:protected onlyRole(BalancerConstants.VAULT_ROLE)
  function deposit(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) external override onlyRole(BalancerConstants.VAULT_ROLE) {
    BalancerStorage storage s = _s();
    Asset storage ast = s.asset[asset];
    uint256 total = _getters().totalBalance(asset);

    uint256 shares = ShareLib.calculateShares(
      amount,
      ast.totalShares,
      total - amount
    );

    ast.shares[user] += shares;
    ast.totalShares += shares;

    emit Deposit(asset, user, amount, shares);

    (Offset[] memory arr, , ) = _calculations().offsets(asset);

    if (arr.length == 0) {
      return;
    }

    uint256 acc = asset.balanceOf(address(this));

    for (uint256 i = 0; i < arr.length; ) {
      if (acc == 0) return;

      Offset memory offset = arr[i];
      Yield storage yield = s.yield[offset.yieldSrc];

      if (offset.isPositive || !yield.state) {
        unchecked {
          i++;
        }

        continue;
      }

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      asset.safeTransfer(address(offset.yieldSrc), yieldAmount);
      offset.yieldSrc.deposit(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;
        i++;
      }
    }

    for (uint256 i = 0; i < arr.length; ) {
      Offset memory offset = arr[i];
      Yield storage yield = s.yield[offset.yieldSrc];

      if (!yield.state) {
        unchecked {
          i++;
        }

        continue;
      }

      _updateAPR(offset.yieldSrc);

      asset.safeTransfer(address(offset.yieldSrc), acc);
      offset.yieldSrc.deposit(acc);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      break;
    }
  }

  /// @inheritdoc	IBalancerAccounting
  /// @custom:protected onlyRole(BalancerConstants.VAULT_ROLE)
  function fullWithdraw(
    IERC20 asset,
    uint256 user
  ) external override onlyRole(BalancerConstants.VAULT_ROLE) returns (uint256) {
    return withdraw(asset, user, _getters().balanceOf(asset, user));
  }

  /// @inheritdoc	IBalancerAccounting
  /// @custom:protected onlyRole(BalancerConstants.VAULT_ROLE)
  function withdraw(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) public override onlyRole(BalancerConstants.VAULT_ROLE) returns (uint256) {
    require(amount > 0, "BalancerInitializer: Cannot withdraw 0 balance");

    BalancerStorage storage s = _s();
    Asset storage ast = s.asset[asset];

    uint256 total = _getters().totalBalance(asset);

    uint256 shares = MathLib.min(
      ShareLib.calculateShares(amount, ast.totalShares, total),
      ast.shares[user]
    );

    require(shares > 0, "BalancerInitializer: Cannot withdraw 0 shares");

    ast.shares[user] -= shares;
    ast.totalShares -= shares;

    emit Withdraw(asset, user, amount, shares);

    if (asset.balanceOf(address(this)) >= amount) {
      asset.safeTransfer(msg.sender, amount);
      return amount;
    }

    (Offset[] memory arr, , ) = _calculations().offsets(asset);

    require(arr.length > 0, "BalancerInitializer: No yields on withdraw");

    uint256 acc = amount - asset.balanceOf(address(this));

    for (uint256 i = 0; i < arr.length; ) {
      if (acc == 0) {
        asset.safeTransfer(msg.sender, amount);
        return amount;
      }

      Offset memory offset = arr[i];
      Yield storage yield = s.yield[offset.yieldSrc];

      if (!offset.isPositive || !yield.state) {
        unchecked {
          i++;
        }

        continue;
      }

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      offset.yieldSrc.withdraw(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;
        i++;
      }
    }

    for (uint256 i = 0; i < arr.length; ) {
      if (acc == 0) {
        asset.safeTransfer(msg.sender, amount);
        return amount;
      }

      Offset memory offset = arr[i];
      Yield storage yield = s.yield[offset.yieldSrc];
      uint256 balance = offset.yieldSrc.totalBalance();

      if (!yield.state) {
        unchecked {
          i++;
        }

        continue;
      }

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(balance, acc);

      if (yieldAmount == balance) {
        offset.yieldSrc.fullWithdraw();
      } else {
        offset.yieldSrc.withdraw(yieldAmount);
      }

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;
        i++;
      }
    }

    if (acc == 0) {
      asset.safeTransfer(msg.sender, amount);
      return amount;
    }

    revert("BalancerInitializer: No way to pay requested amount");
  }
}
