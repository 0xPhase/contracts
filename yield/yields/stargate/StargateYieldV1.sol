// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {StargateYieldV1Storage} from "./IStargateYield.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";
import {ShareLib} from "../../../lib/ShareLib.sol";
import {MathLib} from "../../../lib/MathLib.sol";
import {YieldBase} from "../base/YieldBase.sol";
import {IYield} from "../../IYield.sol";

contract StargateYieldV1 is StargateYieldV1Storage {
  using SafeERC20 for IERC20;
  using ShareLib for uint256;

  modifier wrapETH() {
    uint256 nativeBalance = address(this).balance;

    if (nativeBalance > 0) {
      IWETH(address(asset)).deposit{value: nativeBalance}();
    }

    _;
  }

  /// @inheritdoc	IYield
  function totalBalance() public view override returns (uint256) {
    uint256 poolAmount = _beefyToAsset(beefyVault.balanceOf(address(this))) +
      pool.balanceOf(address(this));

    uint256 underlyingAmount = _poolToAsset(poolAmount);
    uint256 totalAmount = underlyingAmount + asset.balanceOf(address(this));

    if (isETH) {
      totalAmount += address(this).balance;
    }

    return totalAmount;
  }

  /// @inheritdoc	YieldBase
  function _onDeposit(uint256) internal override {
    _deposit(0);
  }

  /// @inheritdoc	YieldBase
  function _onWithdraw(uint256 amount) internal override {
    uint256 balance = asset.balanceOf(address(this));

    if (balance > amount) {
      unchecked {
        _deposit(balance - amount);
      }
    } else if (amount > balance) {
      uint256 difference;

      unchecked {
        difference = amount - balance;
      }

      if (difference == 0) return;

      /// `_assetToPool(difference) * 2` to make sure that the Balancer
      /// receives full `amount` due to inefficiencies in divisions

      uint256 neededPool = _assetToPool(difference) * 2;
      uint256 neededBeefy = _assetToBeefy(neededPool);

      uint256 withdrawFromBeefy = MathLib.min(
        neededBeefy,
        beefyVault.balanceOf(address(this))
      );

      beefyVault.withdraw(withdrawFromBeefy);

      uint256 poolBalance = pool.balanceOf(address(this));

      stargateRouter.instantRedeemLocal(
        uint16(poolId),
        poolBalance,
        address(this)
      );

      if (isETH) {
        uint256 vaultBalance = stargateEthVault.balanceOf(address(this));

        stargateEthVault.withdraw(vaultBalance);

        uint256 nativeBalance = address(this).balance;

        IWETH(address(asset)).deposit{value: nativeBalance}();
      }

      _deposit(amount);
    }
  }

  /// @inheritdoc	YieldBase
  function _onFullWithdraw() internal override {
    _onWithdraw(totalBalance() * 10);
  }

  function _deposit(uint256 offset) internal {
    uint256 amount = asset.balanceOf(address(this)) - offset;

    if (amount > 0) {
      if (isETH) {
        IWETH(address(asset)).withdraw(amount);

        uint256 nativeBalance = address(this).balance;

        stargateEthVault.deposit{value: nativeBalance}();
        stargateEthVault.approve(address(stargateRouter), nativeBalance);
      } else {
        asset.safeApprove(address(stargateRouter), amount);
      }

      stargateRouter.addLiquidity(poolId, amount, address(this));

      uint256 poolAmount = pool.balanceOf(address(this));

      pool.approve(address(beefyVault), amount);
      beefyVault.deposit(poolAmount);
    }
  }

  function _beefyToAsset(uint256 shares) internal view returns (uint256) {
    return
      shares.calculateAmount(beefyVault.totalSupply(), beefyVault.balance());
  }

  function _assetToBeefy(uint256 balance) internal view returns (uint256) {
    return
      balance.calculateShares(beefyVault.totalSupply(), beefyVault.balance());
  }

  function _poolToAsset(uint256 shares) internal view returns (uint256) {
    return shares.calculateAmount(pool.totalSupply(), pool.totalLiquidity());
  }

  function _assetToPool(uint256 balance) internal view returns (uint256) {
    return balance.calculateShares(pool.totalSupply(), pool.totalLiquidity());
  }
}
