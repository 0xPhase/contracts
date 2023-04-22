// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControlBase} from "../diamond/AccessControl/AccessControlBase.sol";
import {ClockBase} from "../diamond/Clock/ClockBase.sol";
import {ERC20Base} from "../diamond/ERC20/ERC20Base.sol";
import {BondStorage, BondState} from "./IBond.sol";

abstract contract BondBase is AccessControlBase, ERC20Base, ClockBase {
  uint256 internal constant _ETH_PRECISION = 10 ** 18;
  uint256 internal constant _POWER = 2;
  uint256 internal constant _POWER_PRECISION = _ETH_PRECISION ** (_POWER - 1);
  uint256 internal constant _BASE_VALUE = 0.5 ether;
  uint256 internal constant _MAX_VALUE = 0.95 ether;
  uint256 internal constant _REMAINING_VALUE = _ETH_PRECISION - _BASE_VALUE;

  bytes32 internal constant _MANAGER_ROLE = keccak256("MANAGER_ROLE");

  BondStorage internal _s;

  /// @notice Event emitted when a bond is created
  /// @param user The user id
  /// @param index The index of the created bond
  /// @param amount The amount of CASH bonded
  /// @param shares The amount of shares reserved
  event BondCreated(
    uint256 indexed user,
    uint256 index,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when a bond is exited
  /// @param user The user id
  /// @param early If the bond was excited before maturity
  /// @param index The index of the bond
  /// @param amount The amount of CASH gotten
  /// @param shares The amount of bond shares gotten
  event BondExited(
    uint256 indexed user,
    bool indexed early,
    uint256 index,
    uint256 amount,
    uint256 shares
  );

  /// @notice Event emitted when bond tokens are unwrapped
  /// @param user The user address
  /// @param amount The amount of underlying tokens given
  /// @param shares The amount of bond tokens burned
  event BondUnwrapped(address indexed user, uint256 amount, uint256 shares);

  /// @notice Event emitted when the bond duration is set
  /// @param duration The new bond duration
  event BondDurationSet(uint256 indexed duration);

  /// @notice Event emitted when the protocol exit portion is set
  /// @param newProtocolExitPortion The new protocol exit portion
  event ProtocolExitPortionSet(uint256 indexed newProtocolExitPortion);

  /// @notice Gets the total balance
  /// @return The total balance
  function _totalBalance() internal view returns (uint256) {
    return IERC20(address(_s.cash)).balanceOf(address(this));
  }

  /// @notice A curve function
  /// @param x The x position on the curve
  /// @return y The y position on the curve
  function _curve(uint256 x) internal pure returns (uint256 y) {
    if (x == 0) return _BASE_VALUE;
    if (x > _ETH_PRECISION) revert("BondBase: Argument x out of bounds");

    uint256 curve = _ETH_PRECISION -
      ((_ETH_PRECISION - x) ** _POWER) /
      _POWER_PRECISION;

    uint256 result = (curve * _REMAINING_VALUE) / _ETH_PRECISION;

    uint256 maxed = ((result * _MAX_VALUE) / _ETH_PRECISION);

    return _BASE_VALUE + maxed;

    // y = 0.5+((1-(1-x)^(2))/(2))*0.95
  }
}
