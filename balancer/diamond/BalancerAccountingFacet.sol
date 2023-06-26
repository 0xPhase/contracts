// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerAccounting} from "../interfaces/IBalancerAccounting.sol";
import {Asset, Offset, Yield, BalancerStorage, OffsetState} from "../IBalancer.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {IYield} from "../../yield/IYield.sol";

contract BalancerAccountingFacet is BalancerBase, IBalancerAccounting {
  using EnumerableSet for EnumerableSet.AddressSet;
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

    (Offset[] memory arr, uint256 totalNegative, ) = _calculations().offsets(
      asset
    );

    if (arr.length == 0) {
      return;
    }

    if (totalNegative == 0) {
      for (uint256 i = 0; i < arr.length; ) {
        Offset memory offset = arr[i];

        if (offset.state == OffsetState.None) {
          unchecked {
            i++;
          }

          continue;
        }

        IYield yieldSrc = IYield(ast.yields.at(i));
        uint256 toDeposit = asset.balanceOf(address(this));

        _updateAPR(yieldSrc);

        asset.safeTransfer(address(yieldSrc), toDeposit);
        yieldSrc.deposit(toDeposit);

        s.yield[yieldSrc].lastDeposit = yieldSrc.totalBalance();

        return;
      }

      return;
    }

    uint256 acc = asset.balanceOf(address(this));

    for (uint256 i = 0; i < arr.length; ) {
      Offset memory offset = arr[i];

      if (offset.state != OffsetState.Negative) {
        unchecked {
          i++;
        }

        continue;
      }

      Yield storage yield = s.yield[offset.yieldSrc];

      _updateAPR(offset.yieldSrc);

      // `min()` to account for small inconsistencies with integer division
      uint256 yieldAmount = MathLib.min(
        (amount * offset.offset) / totalNegative,
        acc
      );

      asset.safeTransfer(address(offset.yieldSrc), yieldAmount);
      offset.yieldSrc.deposit(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;

        if (acc == 0) return;

        i++;
      }
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
    require(amount > 0, "BalancerAccountingFacet: Cannot withdraw 0 balance");

    BalancerStorage storage s = _s();
    Asset storage ast = s.asset[asset];

    uint256 total = _getters().totalBalance(asset);

    uint256 shares = MathLib.min(
      ShareLib.calculateShares(amount, ast.totalShares, total),
      ast.shares[user]
    );

    require(shares > 0, "BalancerAccountingFacet: Cannot withdraw 0 shares");

    ast.shares[user] -= shares;
    ast.totalShares -= shares;

    emit Withdraw(asset, user, amount, shares);

    uint256 curBalance = asset.balanceOf(address(this));

    if (curBalance >= amount) {
      asset.safeTransfer(msg.sender, amount);
      return amount;
    }

    (Offset[] memory arr, , ) = _calculations().offsets(asset);

    require(arr.length > 0, "BalancerInitializer: No yields on withdraw");

    uint256 acc;

    unchecked {
      acc = amount - curBalance;
    }

    for (uint256 i = 0; i < arr.length; ) {
      Offset memory offset = arr[i];

      if (offset.state != OffsetState.Positive) {
        unchecked {
          i++;
        }

        continue;
      }

      Yield storage yield = s.yield[offset.yieldSrc];

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      offset.yieldSrc.withdraw(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;

        if (acc == 0) {
          asset.safeTransfer(msg.sender, amount);
          return amount;
        }

        i++;
      }
    }

    for (uint256 i = 0; i < arr.length; ) {
      Offset memory offset = arr[i];
      uint256 balance = offset.yieldSrc.totalBalance();

      if (offset.state == OffsetState.None) {
        unchecked {
          i++;
        }

        continue;
      }

      Yield storage yield = s.yield[offset.yieldSrc];
      uint256 yieldAmount = MathLib.min(balance, acc);

      _updateAPR(offset.yieldSrc);

      if (yieldAmount == balance) {
        offset.yieldSrc.fullWithdraw();
      } else {
        offset.yieldSrc.withdraw(yieldAmount);
      }

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      unchecked {
        acc -= yieldAmount;

        if (acc == 0) {
          asset.safeTransfer(msg.sender, amount);
          return amount;
        }

        i++;
      }
    }

    revert("BalancerAccountingFacet: No way to pay requested amount");
  }
}
