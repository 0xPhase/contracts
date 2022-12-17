// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {MathLib} from "../../lib/MathLib.sol";
import {PSMV1Storage} from "../IPSM.sol";

contract PSMV1 is PSMV1Storage {
  using SafeERC20 for IERC20;

  modifier mintYield() {
    uint256 total = totalBalance();

    if (total > _lastUnderlyingBalance) {
      cash.mintManager(bondAddress, total - _lastUnderlyingBalance);
      _lastUnderlyingBalance = total;
    }

    _;
  }

  function buyCash(uint256 amount) external mintYield {
    require(amount > 0, "PSMV1: Cannot buy 0 CASH");

    underlying.safeTransferFrom(msg.sender, address(this), amount);

    uint256 fullAmount = MathLib.scaleAmount(amount, _underlyingDecimals, 18);
    uint256 fee = (fullAmount * buyFee) / 1 ether;

    require(fee > 0, "PSMV1: Fee cannot round down to 0");

    cash.mintManager(msg.sender, fullAmount - fee);
    cash.mintManager(bondAddress, fee);

    underlying.safeIncreaseAllowance(address(aavePool), amount);

    aavePool.deposit(address(underlying), amount, address(this), 0);

    totalTraded += fullAmount;
    totalFees += fee;
  }

  function sellCash(uint256 amount) external mintYield {
    require(amount > 0, "PSMV1: Cannot sell 0 CASH");

    uint256 fullAmount = MathLib.scaleAmount(amount, _underlyingDecimals, 18);
    uint256 fee = (amount * sellFee) / 1 ether;

    require(fee > 0, "PSMV1: Fee cannot round down to 0");

    uint256 fullFee = MathLib.scaleAmount(fee, _underlyingDecimals, 18);

    cash.burnManager(msg.sender, fullAmount);
    cash.mintManager(bondAddress, fullFee);
    aavePool.withdraw(address(underlying), amount - fee, msg.sender);

    totalTraded += fullAmount;
    totalFees += fee;
  }

  function setBuyFee(uint256 fee) external onlyRole(MANAGER_ROLE) {
    buyFee = fee;
    emit BuyFeeSet(fee);
  }

  function setSellFee(uint256 fee) external onlyRole(MANAGER_ROLE) {
    sellFee = fee;
    emit SellFeeSet(fee);
  }

  function totalBalance() public view returns (uint256) {
    return
      MathLib.scaleAmount(aToken.balanceOf(address(this)), _aTokenDecimals, 18);
  }
}
