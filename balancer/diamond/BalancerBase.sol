// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControlBase} from "../../diamond/AccessControl/AccessControlBase.sol";
import {IBalancerCalculations} from "../interfaces/IBalancerCalculations.sol";
import {IBalancerGetters} from "../interfaces/IBalancerGetters.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {BalancerStorage, Yield, Asset} from "../IBalancer.sol";
import {ClockBase} from "../../diamond/Clock/ClockBase.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {IYield} from "../../yield/IYield.sol";

abstract contract BalancerBase is AccessControlBase, ClockBase {
  /// @notice Event emitted when a deposit is made
  /// @param asset The deposit asset
  /// @param user The user id
  /// @param amount The amount deposited
  /// @param shares The amount of shares given
  event Deposit(
    IERC20 indexed asset,
    uint256 indexed user,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when a withdraw is made
  /// @param asset The withdrawn asset
  /// @param user The user id
  /// @param amount The amount withdrawn
  /// @param shares The amount of shares taken
  event Withdraw(
    IERC20 indexed asset,
    uint256 indexed user,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when yield apr is set
  /// @param asset The asset
  /// @param apr The apr
  event YieldAPRSet(IERC20 indexed asset, uint256 apr);

  /// @notice Event emitted when a new yield source is added
  /// @param asset The asset
  /// @param yieldSrc The yield source
  event YieldAdded(IERC20 indexed asset, IYield indexed yieldSrc);

  /// @notice Event emitted when the yield state is set
  /// @param asset The asset
  /// @param yieldSrc The yield source
  /// @param state The yield state
  event YieldStateSet(
    IERC20 indexed asset,
    IYield indexed yieldSrc,
    bool state
  );

  /// @notice Event emitted when the performance fee is set
  /// @param fee The performance fee
  event PerformanceFeeSet(uint256 fee);

  function _updateAPR(IYield yieldSrc) internal {
    BalancerStorage storage s = _s();
    Yield storage yield = s.yield[yieldSrc];

    uint256 time = _time();
    uint256 total = yieldSrc.totalBalance();
    IERC20 asset = yieldSrc.asset();

    if (total == 0) {
      yield.apr = 0;
      yield.start = time;
      yield.lastUpdate = time;
      yield.lastDeposit = total;

      emit YieldAPRSet(asset, yield.apr);

      return;
    }

    yield.apr = _calcAPR(yieldSrc);

    uint256 feefull = _totalBalance(yieldSrc);

    if (total > feefull) {
      Asset storage ast = s.asset[asset];
      uint256 fee = total - feefull;

      uint256 shares = ShareLib.calculateShares(
        fee,
        ast.totalShares,
        _getters().totalBalance(asset)
      );

      ast.shares[s.feeAccount] += shares;
      ast.totalShares += shares;
    }

    yield.lastUpdate = time;
    yield.lastDeposit = total;

    emit YieldAPRSet(asset, yield.apr);
  }

  function _calcAPR(IYield yieldSrc) internal view returns (uint256) {
    BalancerStorage storage s = _s();
    uint256 totalBal = _totalBalance(yieldSrc);
    Yield storage yield = s.yield[yieldSrc];

    if (totalBal == 0 || yield.lastDeposit == 0) return 0;

    uint256 time = _getTime();

    uint256 start = MathLib.max(
      time - BalancerConstants.APR_DURATION,
      yield.start
    );

    uint256 update = MathLib.max(
      time - BalancerConstants.APR_DURATION,
      yield.lastUpdate
    );

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
    BalancerStorage storage s = _s();
    Yield storage yield = s.yield[yieldSrc];
    uint256 totalBal = yieldSrc.totalBalance();

    if (yield.lastDeposit > totalBal) return totalBal;

    return
      yield.lastDeposit +
      ((totalBal - yield.lastDeposit) * (1 ether - s.performanceFee)) /
      1 ether;
  }

  /// @notice Returns current address
  /// @return The current address
  function _this() internal view returns (address) {
    return address(this);
  }

  /// @notice Returns self as getters interface
  /// @return The getters interface
  function _getters() internal view returns (IBalancerGetters) {
    return IBalancerGetters(_this());
  }

  /// @notice Returns self as calculations interface
  /// @return The calculations interface
  function _calculations() internal view returns (IBalancerCalculations) {
    return IBalancerCalculations(_this());
  }

  /// @notice Returns the pointer to the balancer storage
  /// @return s Balancer storage pointer
  function _s() internal pure returns (BalancerStorage storage s) {
    bytes32 slot = BalancerConstants.BALANCER_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
