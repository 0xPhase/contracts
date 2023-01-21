// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBondAccounting, Bond, BondState} from "./IBond.sol";
import {ShareLib} from "../lib/ShareLib.sol";
import {BondBase} from "./BondBase.sol";

contract BondAccountingFacet is BondBase, IBondAccounting {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IBondAccounting
  function bond(
    uint256 user,
    uint256 amount
  ) external override updateTime ownerCheck(user, msg.sender) {
    IERC20(address(_s.cash)).safeTransferFrom(
      msg.sender,
      address(this),
      amount
    );

    uint256 totalShares = _totalSupply();
    uint256 shares = totalShares == 0
      ? amount
      : ShareLib.calculateShares(amount, totalShares, _totalBalance());

    _mint(address(this), shares);

    _s.bonds[user].push(Bond(BondState.Active, amount, shares, _time()));
  }

  /// @inheritdoc	IBondAccounting
  function exit(
    uint256 user,
    uint256 index
  ) external override ownerCheck(user, msg.sender) {
    Bond[] storage bonds = _s.bonds[user];

    require(
      bonds.length >= index + 1,
      "BondAccountingFacet: Index out of bounds"
    );

    Bond storage curBond = bonds[index];
    uint256 curtime = _time();

    require(
      curBond.state == BondState.Active,
      "BondAccountingFacet: Bond not active"
    );

    uint256 difference = curtime - curBond.start;

    if (difference >= _s.bondDuration) {
      _transfer(address(this), msg.sender, curBond.shares);

      curBond.state = BondState.Exited;
    } else {
      uint256 x = (difference * 1 ether) / _s.bondDuration;
      uint256 fx = _curve(x);
      uint256 amount = (curBond.amount * fx) / 1 ether;

      IERC20 cash = IERC20(address(_s.cash));

      cash.safeTransfer(msg.sender, amount);
      _burn(address(this), curBond.shares);

      curBond.state = BondState.BackedOut;
    }
  }
}
