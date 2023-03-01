// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Yield, Offset, Asset, IBalancer, BalancerV1Storage} from "../IBalancer.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {IYield} from "../IYield.sol";

contract BalancerV1 is BalancerV1Storage {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @inheritdoc	IBalancer
  /// @custom:protected onlyRole(VAULT_ROLE)
  function deposit(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) external override onlyRole(VAULT_ROLE) {
    Asset storage ast = _asset[asset];
    uint256 total = totalBalance(asset);

    uint256 shares = ShareLib.calculateShares(
      amount,
      ast.totalShares,
      total - amount
    );

    ast.shares[user] += shares;
    ast.totalShares += shares;

    (Offset[] memory arr, , ) = offsets(asset);

    if (arr.length == 0) {
      return;
    }

    uint256 acc = asset.balanceOf(address(this));

    for (uint256 i = 0; i < arr.length; i++) {
      if (acc == 0) return;

      Offset memory offset = arr[i];
      Yield storage yld = _yield[offset.yield];

      if (offset.isPositive) continue;
      if (!yld.state) continue;

      _updateAPR(offset.yield);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      asset.safeTransfer(address(offset.yield), yieldAmount);
      offset.yield.deposit(yieldAmount);

      yld.lastDeposit = offset.yield.totalBalance();

      acc -= yieldAmount;
    }

    for (uint256 i = 0; i < arr.length; i++) {
      Offset memory offset = arr[i];
      Yield storage yld = _yield[offset.yield];

      if (!yld.state) continue;

      _updateAPR(offset.yield);

      asset.safeTransfer(address(offset.yield), acc);
      offset.yield.deposit(acc);

      yld.lastDeposit = offset.yield.totalBalance();

      return;
    }
  }

  /// @inheritdoc	IBalancer
  /// @custom:protected onlyRole(VAULT_ROLE)
  function withdraw(
    IERC20 asset,
    uint256 user,
    uint256 amount
  ) public override onlyRole(VAULT_ROLE) returns (uint256) {
    require(amount > 0, "BalancerV1: Withdrawing 0 balance");

    Asset storage ast = _asset[asset];

    uint256 total = totalBalance(asset);
    uint256 shares = ShareLib.calculateShares(amount, ast.totalShares, total);

    require(ast.shares[user] >= shares, "BalancerV1: Not enough shares");

    ast.shares[user] -= shares;
    ast.totalShares -= shares;

    if (asset.balanceOf(address(this)) >= amount) {
      asset.safeTransfer(msg.sender, amount);
      return amount;
    }

    (Offset[] memory arr, , ) = offsets(asset);

    require(arr.length > 0, "BalancerV1: No yields on withdraw");

    uint256 acc = amount - asset.balanceOf(address(this));

    for (uint256 i = 0; i < arr.length; i++) {
      if (acc == 0) {
        asset.safeTransfer(msg.sender, amount);
        return amount;
      }

      Offset memory offset = arr[i];
      Yield storage yld = _yield[offset.yield];

      if (!offset.isPositive) continue;
      if (!yld.state) continue;

      _updateAPR(offset.yield);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      offset.yield.withdraw(yieldAmount);

      yld.lastDeposit = offset.yield.totalBalance();

      acc -= yieldAmount;
    }

    for (uint256 i = 0; i < arr.length; i++) {
      if (acc == 0) {
        asset.safeTransfer(msg.sender, amount);
        return amount;
      }

      Offset memory offset = arr[i];
      Yield storage yld = _yield[offset.yield];
      uint256 balance = offset.yield.totalBalance();

      if (!yld.state) continue;

      _updateAPR(offset.yield);

      uint256 yieldAmount = MathLib.min(balance, acc);

      if (yieldAmount == balance) {
        offset.yield.fullWithdraw();
      } else {
        offset.yield.withdraw(yieldAmount);
      }

      yld.lastDeposit = offset.yield.totalBalance();

      acc -= yieldAmount;
    }

    revert("BalancerV1: No way to pay requested amount");
  }

  /// @inheritdoc	IBalancer
  /// @custom:protected onlyRole(VAULT_ROLE)
  function fullWithdraw(
    IERC20 asset,
    uint256 user
  ) external override onlyRole(VAULT_ROLE) returns (uint256) {
    return withdraw(asset, user, balanceOf(asset, user));
  }

  /// @custom:protected onlyRole(MANAGER_ROLE)
  function addYield(IYield yield) external onlyRole(MANAGER_ROLE) {
    Yield storage yld = _yield[yield];
    IERC20 asset = yield.asset();
    Asset storage ast = _asset[asset];

    require(ast.yields.add(address(yield)), "BalancerV1: Yield already exists");

    _assets.add(address(asset));
    _yields.add(address(yield));

    yld.yield = yield;
    yld.start = systemClock.time();
    yld.lastUpdate = yld.start;
    yld.state = true;
  }

  /// @custom:protected onlyRole(DEV_ROLE)
  function setYieldState(IYield yield, bool state) external onlyRole(DEV_ROLE) {
    Yield storage yld = _yield[yield];

    yld.state = state;

    if (!state) {
      yield.fullWithdraw();
    }

    _updateAPR(yield);
  }

  /// @inheritdoc	IBalancer
  function totalBalance(
    IERC20 asset
  ) public view override returns (uint256 amount) {
    EnumerableSet.AddressSet storage set = _asset[asset].yields;

    amount = IERC20(asset).balanceOf(address(this));

    for (uint256 i = 0; i < set.length(); i++) {
      amount += IYield(set.at(i)).totalBalance();
    }
  }

  /// @inheritdoc	IBalancer
  function balanceOf(
    IERC20 asset,
    uint256 user
  ) public view override returns (uint256) {
    Asset storage ast = _asset[asset];

    return
      ShareLib.calculateAmount(
        ast.shares[user],
        ast.totalShares,
        totalBalance(asset)
      );
  }

  /// @inheritdoc	IBalancer
  function offsets(
    IERC20 asset
  )
    public
    view
    returns (Offset[] memory arr, uint256 totalNegative, uint256 totalPositive)
  {
    Yield[] memory infos = yields(asset);
    uint256 infoLength = infos.length;

    if (infoLength == 0) {
      return (new Offset[](0), 0, 0);
    }

    arr = new Offset[](infoLength);

    uint256 totalAPR = 0;

    for (uint256 i = 0; i < infoLength; i++) {
      if (!infos[i].state) continue;

      IYield yield = IYield(infos[i].yield);
      uint256 apr = twaa(yield);
      totalAPR += apr;

      arr[i].apr = apr;
      arr[i].yield = yield;
    }

    uint256 averagePerAPR = (totalBalance(asset) * 1 ether) / totalAPR;

    for (uint256 i = 0; i < infoLength; i++) {
      if (!infos[i].state) {
        arr[i].isPositive = true;
        arr[i].offset = 0;

        continue;
      }

      uint256 yieldBalance = IYield(infos[i].yield).totalBalance();
      uint256 targetBalance = (averagePerAPR * arr[i].apr) / 1 ether;

      if (yieldBalance >= targetBalance) {
        uint256 offset = yieldBalance - targetBalance;

        arr[i].isPositive = true;
        arr[i].offset = offset;
        totalPositive += offset;
      } else {
        uint256 offset = targetBalance - yieldBalance;

        arr[i].isPositive = false;
        arr[i].offset = offset;
        totalNegative += offset;
      }
    }
  }

  /// @inheritdoc	IBalancer
  function twaa(IYield yield) public view override returns (uint256) {
    Yield storage info = _yield[yield];

    if (
      info.start == 0 || (systemClock.getTime() - info.start) < APR_MIN_TIME
    ) {
      return APR_DEFAULT;
    }

    return _calcAPR(yield);
  }

  /// @inheritdoc	IBalancer
  function yields(IERC20 asset) public view returns (Yield[] memory arr) {
    EnumerableSet.AddressSet storage set = _asset[asset].yields;
    uint256 length = set.length();

    if (length == 0) {
      return new Yield[](0);
    }

    arr = new Yield[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = _yield[IYield(set.at(i))];
    }
  }

  /// @inheritdoc	IBalancer
  function allYields() public view returns (address[] memory arr) {
    uint256 length = _yields.length();

    if (length == 0) {
      return new address[](0);
    }

    arr = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      arr[i] = _yields.at(i);
    }
  }

  function _updateAPR(IYield yield) internal {
    Yield storage yld = _yield[yield];

    uint256 time = systemClock.time();
    uint256 total = yield.totalBalance();

    if (total == 0) {
      yld.apr = 0;
      yld.start = time;
      yld.lastUpdate = time;
      yld.lastDeposit = total;

      return;
    }

    yld.apr = _calcAPR(yield);
    yld.lastUpdate = time;
    yld.lastDeposit = total;
  }

  function _calcAPR(IYield yield) internal view returns (uint256) {
    uint256 totalBal = yield.totalBalance();

    if (totalBal == 0) return 0;

    Yield storage yld = _yield[yield];
    uint256 time = systemClock.getTime();

    uint256 start = MathLib.max(time - APR_DURATION, yld.start);
    uint256 update = MathLib.max(time - APR_DURATION, yld.lastUpdate);

    if (time == update) return yld.apr;

    uint256 total = time - start;
    uint256 left = update - start;
    uint256 right = time - update;

    uint256 increase = totalBal - yld.lastDeposit;

    uint256 rightAPR = (increase * right * 1 ether) /
      (yld.lastDeposit * 365.25 days);

    return ((left * yld.apr) + (right * rightAPR)) / total;
  }
}
