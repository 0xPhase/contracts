// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControlBase} from "../diamond/AccessControl/AccessControlBase.sol";
import {OwnableBase} from "../diamond/Ownable/OwnableBase.sol";
import {ERC20Base} from "../diamond/ERC20/ERC20Base.sol";
import {ClockBase} from "../diamond/Clock/ClockBase.sol";
import {BondStorage} from "./IBond.sol";

abstract contract BondBase is
  AccessControlBase,
  OwnableBase,
  ERC20Base,
  ClockBase
{
  uint256 internal constant _ETH_PRECISION = 10**18;
  uint256 internal constant _POWER = 2;
  uint256 internal constant _POWER_PRECISION = _ETH_PRECISION**(_POWER - 1);
  uint256 internal constant _BASE_VALUE = 0.5 ether;
  uint256 internal constant _MAX_VALUE = 0.95 ether;
  uint256 internal constant _REMAINING_VALUE = _ETH_PRECISION - _BASE_VALUE;

  bytes32 internal constant _MANAGER_ROLE = keccak256("MANAGER_ROLE");

  BondStorage internal _s;

  event BondDurationSet(uint256 indexed duration);

  modifier ownerCheck(uint256 tokenId, address sender) {
    require(
      sender == IERC721(address(_s.creditAccount)).ownerOf(tokenId),
      "BondBase: Not owner of token"
    );

    _;
  }

  function _totalBalance() internal view returns (uint256) {
    return IERC20(address(_s.cash)).balanceOf(address(this));
  }

  function _curve(uint256 x) internal pure returns (uint256 y) {
    if (x == 0) return _BASE_VALUE;
    if (x > _ETH_PRECISION) revert("BondBase: Argument x out of bounds");

    uint256 curve = _ETH_PRECISION -
      ((_ETH_PRECISION - x)**_POWER) /
      _POWER_PRECISION;

    uint256 result = (curve * _REMAINING_VALUE) / _ETH_PRECISION;

    uint256 maxed = ((result * _MAX_VALUE) / _ETH_PRECISION);

    return _BASE_VALUE + maxed;

    // y = 0.5+((1-(1-x)^(2))/(2))*0.95
  }
}
