// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerCalculations} from "../interfaces/IBalancerCalculations.sol";
import {Offset, Yield, Asset, BalancerStorage} from "../IBalancer.sol";
import {IBalancerGetters} from "../interfaces/IBalancerGetters.sol";
import {BalancerConstants} from "./BalancerConstants.sol";
import {BalancerBase} from "./BalancerBase.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {IYield} from "../../yield/IYield.sol";

contract BalancerCalculationsFacet is BalancerBase, IBalancerCalculations {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc	IBalancerCalculations
  function offsets(
    IERC20 asset
  )
    external
    view
    override
    returns (Offset[] memory arr, uint256 totalNegative, uint256 totalPositive)
  {
    IBalancerGetters getters = _getters();
    Yield[] memory infos = getters.yields(asset);
    uint256 infoLength = infos.length;

    if (infoLength == 0) {
      return (arr, 0, 0);
    }

    arr = new Offset[](infoLength);

    uint256 totalAPR = 0;

    for (uint256 i = 0; i < infoLength; ) {
      IYield yield = IYield(infos[i].yieldSrc);

      arr[i].yieldSrc = yield;

      if (!infos[i].state) {
        unchecked {
          i++;
        }

        continue;
      }

      uint256 apr = twaa(yield);

      totalAPR += apr;
      arr[i].apr = apr;

      unchecked {
        i++;
      }
    }

    if (totalAPR == 0) {
      return (arr, 0, 0);
    }

    uint256 averagePerAPR = (getters.totalBalance(asset) * 1 ether) / totalAPR;

    for (uint256 i = 0; i < infoLength; ) {
      if (!infos[i].state) {
        arr[i].isPositive = false;
        arr[i].offset = 0;

        unchecked {
          i++;
        }

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

      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc	IBalancerCalculations
  function assetAPR(IERC20 asset) external view override returns (uint256 apr) {
    BalancerStorage storage s = _s();
    EnumerableSet.AddressSet storage set = s.asset[asset].yields;
    uint256 length = set.length();

    if (length == 0) {
      return 0;
    }

    uint256 total = 0;

    for (uint256 i = 0; i < length; ) {
      IYield yieldSrc = IYield(set.at(i));

      if (!s.yield[yieldSrc].state) {
        unchecked {
          i++;
        }

        continue;
      }

      uint256 curTotal = _totalBalance(yieldSrc);

      if (curTotal == 0) {
        unchecked {
          i++;
        }

        continue;
      }

      total += curTotal;
      apr += curTotal * twaa(yieldSrc);

      unchecked {
        i++;
      }
    }

    if (total > 0) {
      apr /= total;
    } else {
      apr = 0;
    }
  }

  /// @inheritdoc	IBalancerCalculations
  function twaa(IYield yieldSrc) public view override returns (uint256) {
    Yield storage info = _s().yield[yieldSrc];

    if (info.start == 0) {
      return 0;
    }

    if ((_getTime() - info.start) < BalancerConstants.APR_MIN_TIME) {
      return BalancerConstants.APR_DEFAULT;
    }

    return _calcAPR(yieldSrc);
  }
}
