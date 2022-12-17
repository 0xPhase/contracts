// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControl} from "../../core/AccessControl.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {Manager} from "../../core/Manager.sol";
import {IVault} from "../../vault/IVault.sol";
import {IDB} from "../../db/IDB.sol";
import {IYield} from "../IYield.sol";

abstract contract BaseYield is AccessControl, IYield {
  using SafeERC20 for IERC20;

  bytes32 public constant CREDITOR_ROLE = keccak256("CREDITOR_ROLE");

  mapping(uint256 => uint256) public shares;
  IVault public vault;
  IERC20 public asset;

  uint256 internal _totalShares;

  modifier onlyVault() {
    require(msg.sender == address(vault), "BaseYield: Caller is not vault");
    _;
  }

  function receiveDeposit(uint256 user, uint256 amount)
    external
    override
    onlyVault
  {
    _preDeposit(user, amount);

    uint256 currentBalance = totalBalance();

    asset.safeTransferFrom(address(vault), address(this), amount);
    _onDeposit(user, amount);

    uint256 balanceChange = totalBalance() - currentBalance;

    uint256 share = _totalShares == 0
      ? balanceChange
      : ShareLib.calculateShares(balanceChange, _totalShares, currentBalance);

    shares[user] += share;
    _totalShares += share;

    emit Deposit(user, amount, share);
  }

  function receiveWithdraw(uint256 user, uint256 amount)
    external
    override
    onlyVault
    returns (uint256)
  {
    require(_totalShares > 0, "BaseYield: No shares exist");

    uint256 share = ShareLib.calculateShares(amount, _totalShares, amount);

    require(shares[user] >= share, "BaseYield: Not enough shares");

    _preWithdraw(user, amount);

    uint256 currentBalance = asset.balanceOf(address(this));

    _onWithdraw(user, amount);

    uint256 balanceChange = asset.balanceOf(address(this)) - currentBalance;

    asset.safeTransfer(address(vault), balanceChange);

    shares[user] -= share;
    _totalShares -= share;

    emit Withdraw(user, amount, share);

    return balanceChange;
  }

  function receiveFullWithdraw(uint256 user)
    external
    override
    onlyVault
    returns (uint256)
  {
    uint256 share = shares[user];

    if (share == 0) return 0;

    uint256 amount = ShareLib.calculateAmount(
      share,
      _totalShares,
      totalBalance()
    );

    _preWithdraw(user, amount);

    uint256 currentBalance = asset.balanceOf(address(this));

    _onWithdraw(user, amount);

    uint256 balanceChange = asset.balanceOf(address(this)) - currentBalance;

    asset.safeTransfer(address(vault), balanceChange);

    shares[user] -= share;
    _totalShares -= share;

    emit Withdraw(user, amount, share);

    return balanceChange;
  }

  function balance(uint256 user) external view virtual returns (uint256) {
    return ShareLib.calculateAmount(shares[user], _totalShares, totalBalance());
  }

  function totalBalance() public view virtual returns (uint256);

  function _initializeSimpleYield(IDB db_, IVault vault_) internal {
    _setDB(db_);

    vault = vault_;
    asset = vault_.asset();
  }

  // solhint-disable-next-line no-empty-blocks
  function _preDeposit(uint256 user, uint256 amount) internal virtual {}

  // solhint-disable-next-line no-empty-blocks
  function _preWithdraw(uint256 user, uint256 amount) internal virtual {}

  // solhint-disable-next-line no-empty-blocks
  function _onDeposit(uint256 user, uint256 amount) internal virtual {}

  // solhint-disable-next-line no-empty-blocks
  function _onWithdraw(uint256 user, uint256 amount) internal virtual {}
}
