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
      Yield storage yield = _yield[offset.yieldSrc];

      if (offset.isPositive) continue;
      if (!yield.state) continue;

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      asset.safeTransfer(address(offset.yieldSrc), yieldAmount);
      offset.yieldSrc.deposit(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      acc -= yieldAmount;
    }

    for (uint256 i = 0; i < arr.length; i++) {
      Offset memory offset = arr[i];
      Yield storage yield = _yield[offset.yieldSrc];

      if (!yield.state) continue;

      _updateAPR(offset.yieldSrc);

      asset.safeTransfer(address(offset.yieldSrc), acc);
      offset.yieldSrc.deposit(acc);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      break;
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
      Yield storage yield = _yield[offset.yieldSrc];

      if (!offset.isPositive) continue;
      if (!yield.state) continue;

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(offset.offset, acc);

      offset.yieldSrc.withdraw(yieldAmount);

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      acc -= yieldAmount;
    }

    for (uint256 i = 0; i < arr.length; i++) {
      if (acc == 0) {
        asset.safeTransfer(msg.sender, amount);
        return amount;
      }

      Offset memory offset = arr[i];
      Yield storage yield = _yield[offset.yieldSrc];
      uint256 balance = offset.yieldSrc.totalBalance();

      if (!yield.state) continue;

      _updateAPR(offset.yieldSrc);

      uint256 yieldAmount = MathLib.min(balance, acc);

      if (yieldAmount == balance) {
        offset.yieldSrc.fullWithdraw();
      } else {
        offset.yieldSrc.withdraw(yieldAmount);
      }

      yield.lastDeposit = offset.yieldSrc.totalBalance();

      acc -= yieldAmount;
    }

    if (acc == 0) {
      asset.safeTransfer(msg.sender, amount);
      return amount;
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

  /// @notice Adds a new yield
  /// @param yieldSrc The yield source
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function addYield(IYield yieldSrc) external onlyRole(MANAGER_ROLE) {
    Yield storage yield = _yield[yieldSrc];
    IERC20 asset = yieldSrc.asset();
    Asset storage ast = _asset[asset];

    require(
      ast.yields.add(address(yieldSrc)),
      "BalancerV1: Yield already exists"
    );

    _assets.add(address(asset));
    _yields.add(address(yieldSrc));

    yield.yieldSrc = yieldSrc;
    yield.start = systemClock.time();
    yield.lastUpdate = yield.start;
    yield.state = true;
  }

  /// @notice Sets yield state
  /// @param yieldSrc The yield source
  /// @custom:protected onlyRole(DEV_ROLE)
  function setYieldState(
    IYield yieldSrc,
    bool state
  ) external onlyRole(DEV_ROLE) {
    Yield storage yield = _yield[yieldSrc];

    yield.state = state;

    _updateAPR(yieldSrc);

    if (!state) {
      yieldSrc.fullWithdraw();
      yield.lastDeposit = 0;
    }
  }

  /// @notice Sets the performance fee
  /// @param newPerformanceFee The new performance fee
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function setPerformanceFee(
    uint256 newPerformanceFee
  ) external onlyRole(MANAGER_ROLE) {
    performanceFee = newPerformanceFee;

    emit PerformanceFeeSet(newPerformanceFee);
  }

  /// @inheritdoc	IBalancer
  function totalBalance(
    IERC20 asset
  ) public view override returns (uint256 amount) {
    EnumerableSet.AddressSet storage set = _asset[asset].yields;

    amount = IERC20(asset).balanceOf(address(this));

    for (uint256 i = 0; i < set.length(); i++) {
      amount += _totalBalance(IYield(set.at(i)));
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

      IYield yield = IYield(infos[i].yieldSrc);
      uint256 apr = twaa(yield);

      totalAPR += apr;
      arr[i].apr = apr;
      arr[i].yieldSrc = yield;
    }

    if (totalAPR == 0) {
      return (arr, 0, 0);
    }

    uint256 averagePerAPR = (totalBalance(asset) * 1 ether) / totalAPR;

    for (uint256 i = 0; i < infoLength; i++) {
      if (!infos[i].state) {
        arr[i].isPositive = true;
        arr[i].offset = 0;

        continue;
      }

      uint256 yieldBalance = _totalBalance(IYield(infos[i].yieldSrc));
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
  function assetAPR(IERC20 asset) external view returns (uint256 apr) {
    EnumerableSet.AddressSet storage set = _asset[asset].yields;
    uint256 length = set.length();

    if (length == 0) {
      return 0;
    }

    uint256 total = 0;

    for (uint256 i = 0; i < length; i++) {
      IYield yieldSrc = IYield(set.at(i));

      if (!_yield[yieldSrc].state) continue;

      uint256 curTotal = _totalBalance(yieldSrc);

      if (curTotal == 0) continue;

      total += curTotal;
      apr += curTotal * twaa(yieldSrc);
    }

    if (total > 0) {
      apr /= total;
    } else {
      apr = 0;
    }
  }

  /// @inheritdoc	IBalancer
  function twaa(IYield yieldSrc) public view override returns (uint256) {
    Yield storage info = _yield[yieldSrc];

    if (info.start == 0) {
      return 0;
    }

    if ((systemClock.getTime() - info.start) < APR_MIN_TIME) {
      return APR_DEFAULT;
    }

    return _calcAPR(yieldSrc);
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

  function _updateAPR(IYield yieldSrc) internal {
    Yield storage yield = _yield[yieldSrc];

    uint256 time = systemClock.time();
    uint256 total = yieldSrc.totalBalance();
    IERC20 asset = yieldSrc.asset();

    if (total == 0) {
      yield.apr = 0;
      yield.start = time;
      yield.lastUpdate = time;
      yield.lastDeposit = total;

      emit YieldAPRSet(asset, time, yield.apr);

      return;
    }

    yield.apr = _calcAPR(yieldSrc);

    uint256 feefull = _totalBalance(yieldSrc);

    if (total > feefull) {
      Asset storage ast = _asset[asset];
      uint256 fee = total - feefull;

      uint256 shares = ShareLib.calculateShares(
        fee,
        ast.totalShares,
        totalBalance(asset)
      );

      ast.shares[feeAccount] += shares;
      ast.totalShares += shares;
    }

    yield.lastUpdate = time;
    yield.lastDeposit = total;

    emit YieldAPRSet(asset, time, yield.apr);
  }

  function _calcAPR(IYield yieldSrc) internal view returns (uint256) {
    uint256 totalBal = _totalBalance(yieldSrc);
    Yield storage yield = _yield[yieldSrc];

    if (totalBal == 0 || yield.lastDeposit == 0) return 0;

    uint256 time = systemClock.getTime();

    uint256 start = MathLib.max(time - APR_DURATION, yield.start);
    uint256 update = MathLib.max(time - APR_DURATION, yield.lastUpdate);

    if (time == update) return yield.apr;

    uint256 total = time - start;
    uint256 left = update - start;
    uint256 right = time - update;

    if (total == 0 || right == 0) return 0;

    uint256 increase = yield.lastDeposit > totalBal
      ? 0
      : totalBal - yield.lastDeposit;

    uint256 rightAPR = (increase * 365.25 days * 1 ether) /
      (yield.lastDeposit * right);

    return ((left * yield.apr) + (right * rightAPR)) / total;
  }

  function _totalBalance(IYield yieldSrc) internal view returns (uint256) {
    Yield storage yield = _yield[yieldSrc];
    uint256 totalBal = yieldSrc.totalBalance();

    if (yield.lastDeposit > totalBal) return totalBal;

    return
      yield.lastDeposit +
      ((totalBal - yield.lastDeposit) * (1 ether - performanceFee)) /
      1 ether;
  }
}
