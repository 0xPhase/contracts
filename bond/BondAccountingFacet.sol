// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBondAccounting, Bond, BondState, BondStorage} from "./IBond.sol";
import {ShareLib} from "../lib/ShareLib.sol";
import {BondBase} from "./BondBase.sol";

contract BondAccountingFacet is BondBase, IBondAccounting {
  using SafeERC20 for IERC20;

  /// @inheritdoc	IBondAccounting
  function bond(address user, uint256 amount) public override {
    bond(_s().creditAccount.getAccount(user), amount);
  }

  /// @inheritdoc	IBondAccounting
  function bond(uint256 user, uint256 amount) public override {
    BondStorage storage s = _s();

    uint256 time = _time();
    uint256 shares = ShareLib.calculateShares(
      amount,
      _totalSupply(),
      _totalBalance()
    );

    s.cash.transferManager(msg.sender, address(this), amount);

    _mint(address(this), shares);

    s.bonds[user].push(
      Bond({
        state: BondState.Active,
        amount: amount,
        shares: shares,
        start: time,
        end: 0
      })
    );

    emit BondCreated(user, s.bonds[user].length - 1, amount, shares);
  }

  /// @inheritdoc	IBondAccounting
  function exit(uint256 index) external {
    BondStorage storage s = _s();
    uint256 user = s.creditAccount.getAccount(msg.sender);
    Bond[] storage bonds = s.bonds[user];

    require(bonds.length > index, "BondAccountingFacet: Index out of bounds");

    Bond storage curBond = bonds[index];
    uint256 curtime = _time();

    require(
      curBond.state == BondState.Active,
      "BondAccountingFacet: Bond not active"
    );

    uint256 difference;

    unchecked {
      // Current time can never go back before start
      difference = curtime - curBond.start;
    }

    if (difference >= s.bondDuration) {
      _transfer(address(this), msg.sender, curBond.shares);

      curBond.state = BondState.Exited;

      emit BondExited(
        user,
        false,
        index,
        ShareLib.calculateAmount(
          curBond.shares,
          _totalSupply(),
          _totalBalance()
        ),
        curBond.shares
      );
    } else {
      uint256 x = (difference * 1 ether) / s.bondDuration;
      uint256 fx = _curve(x);
      uint256 shares = curBond.shares;

      uint256 remaining = shares - ((shares * fx) / 1 ether);
      uint256 protocolShares = (remaining * s.protocolExitPortion) / 1 ether;
      uint256 amount = (curBond.amount * fx) / 1 ether;

      IERC20(address(s.cash)).safeTransfer(msg.sender, amount);
      _burn(address(this), shares);
      _mint(address(s.manager), protocolShares);

      curBond.state = BondState.BackedOut;

      emit BondExited(user, true, index, amount, 0);
    }

    curBond.end = curtime;
  }

  /// @inheritdoc	IBondAccounting
  function unwrap(uint256 amount) public override returns (uint256) {
    require(amount > 0, "BondAccountingFacet: Cannot unwrap 0 tokens");

    uint256 underlying = ShareLib.calculateAmount(
      amount,
      _totalSupply(),
      _totalBalance()
    );

    _burn(msg.sender, amount);
    IERC20(address(_s().cash)).safeTransfer(msg.sender, underlying);

    emit BondUnwrapped(msg.sender, underlying, amount);

    return underlying;
  }
}
