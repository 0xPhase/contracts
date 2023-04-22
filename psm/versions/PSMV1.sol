// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPSM, PSMV1Storage} from "../IPSM.sol";
import {MathLib} from "../../lib/MathLib.sol";

contract PSMV1 is PSMV1Storage {
  using SafeERC20 for IERC20;

  /// @notice Mints the yield for the contract
  modifier mintYield() {
    uint256 total = totalBalance();

    if (total > _lastUnderlyingBalance) {
      cash.mintManager(bondAddress, total - _lastUnderlyingBalance);
      _lastUnderlyingBalance = total;
    }

    _;
  }

  /// @inheritdoc	IPSM
  function buyCash(uint256 amount) external override mintYield {
    require(amount > 0, "PSMV1: Cannot buy 0 CASH");

    underlying.safeTransferFrom(msg.sender, address(this), amount);

    uint256 fullAmount = MathLib.scaleAmount(amount, _underlyingDecimals, 18);
    uint256 fee = (fullAmount * buyFee) / 1 ether;

    require(buyFee == 0 || fee > 0, "PSMV1: Fee cannot round down to 0");

    uint256 userAmount = fullAmount - fee;

    cash.mintManager(msg.sender, userAmount);

    if (fee > 0) {
      cash.mintManager(bondAddress, fee);
    }

    underlying.safeIncreaseAllowance(address(vault), amount);
    vault.addCollateral(amount, "");

    totalTraded += fullAmount;
    totalFees += fee;

    emit CashBought(msg.sender, fee, userAmount, fullAmount);
  }

  /// @inheritdoc	IPSM
  function sellCash(uint256 amount) external override mintYield {
    require(amount > 0, "PSMV1: Cannot sell 0 CASH");

    uint256 fullAmount = MathLib.scaleAmount(amount, _underlyingDecimals, 18);
    uint256 fee = (amount * sellFee) / 1 ether;

    require(sellFee == 0 || fee > 0, "PSMV1: Fee cannot round down to 0");

    uint256 fullFee = MathLib.scaleAmount(fee, _underlyingDecimals, 18);
    uint256 fullUserAmount = fullAmount - fullFee;

    cash.burnManager(msg.sender, fullAmount);

    if (fullFee > 0) {
      cash.mintManager(bondAddress, fullFee);
    }

    vault.removeCollateral(amount - fee, "");
    underlying.safeTransfer(msg.sender, amount - fee);

    totalTraded += fullAmount;
    totalFees += fullFee;

    emit CashSold(msg.sender, fee, fullAmount, fullUserAmount);
  }

  /// @notice Sets the buy fee
  /// @param fee The buy fee
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function setBuyFee(uint256 fee) external onlyRole(MANAGER_ROLE) {
    buyFee = fee;
    emit BuyFeeSet(fee);
  }

  /// @notice Sets the sell fee
  /// @param fee The sell fee
  /// @custom:protected onlyRole(MANAGER_ROLE)
  function setSellFee(uint256 fee) external onlyRole(MANAGER_ROLE) {
    sellFee = fee;
    emit SellFeeSet(fee);
  }

  /// @inheritdoc	IPSM
  function totalBalance() public view override returns (uint256) {
    return vault.deposit(creditAccount);
  }
}
