// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AccessControl} from "../../core/AccessControl.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {Manager} from "../../core/Manager.sol";
import {MathLib} from "../../lib/MathLib.sol";
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

  /// @notice Runs the function only if caller is the vault
  modifier onlyVault() {
    require(msg.sender == address(vault), "BaseYield: Caller is not vault");
    _;
  }

  /// @inheritdoc	IYield
  function receiveDeposit(
    uint256 user,
    uint256 amount
  ) external override onlyVault {
    _preDeposit(user, amount);

    asset.safeTransferFrom(address(vault), address(this), amount);

    uint256 share = _totalShares == 0
      ? amount
      : ShareLib.calculateShares(amount, _totalShares, totalBalance());

    _onDeposit(user, amount, share);

    shares[user] += share;
    _totalShares += share;

    emit Deposit(user, amount, share);
  }

  /// @inheritdoc	IYield
  function receiveWithdraw(
    uint256 user,
    uint256 amount
  ) external override onlyVault returns (uint256) {
    require(_totalShares > 0, "BaseYield: No shares exist");

    _preWithdraw(user, amount);

    uint256 share = ShareLib.calculateShares(
      amount,
      _totalShares,
      totalBalance()
    );

    require(shares[user] >= share, "BaseYield: Not enough shares");

    _onWithdraw(user, amount, share);

    asset.safeTransfer(address(vault), amount);

    shares[user] -= share;
    _totalShares -= share;

    emit Withdraw(user, amount, share);

    return amount;
  }

  /// @inheritdoc	IYield
  function receiveFullWithdraw(
    uint256 user
  ) external override onlyVault returns (uint256) {
    uint256 share = shares[user];

    if (share == 0) return 0;

    _preWithdraw(user, 0);

    uint256 rawAmount = ShareLib.calculateAmount(
      share,
      _totalShares,
      totalBalance()
    );

    uint256 amount = MathLib.min(rawAmount, asset.balanceOf(address(this)));

    _onWithdraw(user, amount, share);

    asset.safeTransfer(address(vault), amount);

    shares[user] -= share;
    _totalShares -= share;

    emit Withdraw(user, amount, share);

    return amount;
  }

  /// @inheritdoc	IYield
  function balance(uint256 user) external view virtual returns (uint256) {
    return ShareLib.calculateAmount(shares[user], _totalShares, totalBalance());
  }

  /// @inheritdoc	IYield
  function totalBalance() public view virtual returns (uint256);

  /// @notice Initializer for the BaseYield contract
  /// @param db_ The DB contract address
  /// @param vault_ The Vault contract address
  function _initializeSimpleYield(IDB db_, IVault vault_) internal {
    _initializeDB(db_);

    vault = vault_;
    asset = vault_.asset();
  }

  // solhint-disable no-empty-blocks
  /// @notice Ran before the deposit is made
  /// @param user The user id
  /// @param amount The deposit amount
  function _preDeposit(uint256 user, uint256 amount) internal virtual {}

  /// @notice Ran before the withdraw is made
  /// @param user The user id
  /// @param amount The withdraw amount
  function _preWithdraw(uint256 user, uint256 amount) internal virtual {}

  /// @notice Ran after the deposit is made
  /// @param user The user id
  /// @param amount The deposit amount
  /// @param share The deposit shares
  function _onDeposit(
    uint256 user,
    uint256 amount,
    uint256 share
  ) internal virtual {}

  /// @notice Ran after the deposit is made
  /// @param user The user id
  /// @param amount The withdraw amount
  /// @param share The withdraw shares
  function _onWithdraw(
    uint256 user,
    uint256 amount,
    uint256 share
  ) internal virtual {}
  // solhint-enable no-empty-blocks
}
