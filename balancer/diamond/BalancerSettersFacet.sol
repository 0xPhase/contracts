// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerSetters} from "../interfaces/IBalancerSetters.sol";
import {Asset, Yield, BalancerStorage} from "../IBalancer.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {IYield} from "../../yield/IYield.sol";

contract BalancerSettersFacet is BalancerBase, IBalancerSetters {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc IBalancerSetters
  /// @custom:protected onlyRole(BalancerConstants.MANAGER_ROLE)
  function addYield(
    IYield yieldSrc
  ) external override onlyRole(BalancerConstants.MANAGER_ROLE) {
    BalancerStorage storage s = _s();
    Yield storage yield = s.yield[yieldSrc];
    IERC20 asset = yieldSrc.asset();
    Asset storage ast = s.asset[asset];

    require(
      ast.yields.add(address(yieldSrc)),
      "BalancerSettersFacet: Yield already exists"
    );

    s.assets.add(address(asset));
    s.yields.add(address(yieldSrc));

    yield.yieldSrc = yieldSrc;
    yield.start = _time();
    yield.lastUpdate = yield.start;
    yield.state = true;

    emit YieldAdded(asset, yieldSrc);
  }

  /// @inheritdoc IBalancerSetters
  /// @custom:protected onlyRole(BalancerConstants.DEV_ROLE)
  function setYieldState(
    IYield yieldSrc,
    bool state
  ) external override onlyRole(BalancerConstants.DEV_ROLE) {
    Yield storage yield = _s().yield[yieldSrc];

    yield.state = state;

    if (!state) {
      yieldSrc.fullWithdraw();
      yield.lastDeposit = 0;
    }

    _updateAPR(yieldSrc);

    emit YieldStateSet(yieldSrc.asset(), yieldSrc, state);
  }

  /// @inheritdoc IBalancerSetters
  /// @custom:protected onlyRole(BalancerConstants.MANAGER_ROLE)
  function setPerformanceFee(
    uint256 newPerformanceFee
  ) external override onlyRole(BalancerConstants.MANAGER_ROLE) {
    _s().performanceFee = newPerformanceFee;

    emit PerformanceFeeSet(newPerformanceFee);
  }
}
