// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerGetters} from "../interfaces/IBalancerGetters.sol";
import {Yield, Asset, BalancerStorage} from "../IBalancer.sol";
import {ISystemClock} from "../../clock/ISystemClock.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {IYield} from "../../yield/IYield.sol";

contract BalancerGettersFacet is BalancerBase, IBalancerGetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc	IBalancerGetters
  function totalBalance(
    IERC20 asset
  ) public view override returns (uint256 amount) {
    EnumerableSet.AddressSet storage set = _s().asset[asset].yields;

    amount = IERC20(asset).balanceOf(address(this));

    for (uint256 i = 0; i < set.length(); ) {
      amount += _totalBalance(IYield(set.at(i)));

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc	IBalancerGetters
  function balanceOf(
    IERC20 asset,
    uint256 user
  ) external view override returns (uint256) {
    Asset storage ast = _s().asset[asset];

    return
      ShareLib.calculateAmount(
        ast.shares[user],
        ast.totalShares,
        totalBalance(asset)
      );
  }

  /// @inheritdoc	IBalancerGetters
  function yields(
    IERC20 asset
  ) external view override returns (Yield[] memory arr) {
    BalancerStorage storage s = _s();
    EnumerableSet.AddressSet storage set = s.asset[asset].yields;
    uint256 length = set.length();

    if (length == 0) {
      return arr;
    }

    arr = new Yield[](length);

    for (uint256 i = 0; i < length; ) {
      arr[i] = s.yield[IYield(set.at(i))];

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc	IBalancerGetters
  function allYields() external view override returns (address[] memory arr) {
    BalancerStorage storage s = _s();
    uint256 length = s.yields.length();

    if (length == 0) {
      return arr;
    }

    arr = new address[](length);

    for (uint256 i = 0; i < length; ) {
      arr[i] = s.yields.at(i);

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc	IBalancerGetters
  function treasury() external view override returns (ITreasury) {
    return _s().treasury;
  }

  /// @inheritdoc	IBalancerGetters
  function performanceFee() external view override returns (uint256) {
    return _s().performanceFee;
  }

  /// @inheritdoc	IBalancerGetters
  function feeAccount() external view override returns (uint256) {
    return _s().feeAccount;
  }
}
