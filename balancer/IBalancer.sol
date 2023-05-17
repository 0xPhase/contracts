// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBalancerCalculations} from "./interfaces/IBalancerCalculations.sol";
import {IBalancerAccounting} from "./interfaces/IBalancerAccounting.sol";
import {IBalancerGetters} from "./interfaces/IBalancerGetters.sol";
import {IBalancerSetters} from "./interfaces/IBalancerSetters.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {ITreasury} from "../treasury/ITreasury.sol";
import {IYield} from "../yield/IYield.sol";

struct Asset {
  EnumerableSet.AddressSet yields;
  mapping(uint256 => uint256) shares;
  uint256 totalShares;
}

struct Yield {
  IYield yieldSrc;
  uint256 start;
  uint256 apr;
  uint256 lastUpdate;
  uint256 lastDeposit;
  bool state;
}

enum OffsetState {
  None,
  Positive,
  Negative
}

struct Offset {
  IYield yieldSrc;
  uint256 apr;
  uint256 offset;
  OffsetState state;
}

struct BalancerStorage {
  mapping(IYield => Yield) yield;
  mapping(IERC20 => Asset) asset;
  EnumerableSet.AddressSet assets;
  EnumerableSet.AddressSet yields;
  ITreasury treasury;
  uint256 performanceFee;
  uint256 feeAccount;
}

// solhint-disable-next-line no-empty-blocks
interface IBalancer is
  IBalancerAccounting,
  IBalancerCalculations,
  IBalancerGetters,
  IBalancerSetters
{

}
