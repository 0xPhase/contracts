// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ICometExt} from "./ICometExt.sol";

interface IComet is ICometExt {
  struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
  }

  function absorb(address absorber, address[] memory accounts) external;

  function accrueAccount(address account) external;

  function approveThis(address manager, address asset, uint256 amount) external;

  function buyCollateral(
    address asset,
    uint256 minAmount,
    uint256 baseAmount,
    address recipient
  ) external;

  function initializeStorage() external;

  function pause(
    bool supplyPaused,
    bool transferPaused,
    bool withdrawPaused,
    bool absorbPaused,
    bool buyPaused
  ) external;

  function supply(address asset, uint256 amount) external;

  function supplyFrom(
    address from,
    address dst,
    address asset,
    uint256 amount
  ) external;

  function supplyTo(address dst, address asset, uint256 amount) external;

  function transfer(address dst, uint256 amount) external returns (bool);

  function transferAsset(address dst, address asset, uint256 amount) external;

  function transferAssetFrom(
    address src,
    address dst,
    address asset,
    uint256 amount
  ) external;

  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function withdraw(address asset, uint256 amount) external;

  function withdrawFrom(
    address src,
    address to,
    address asset,
    uint256 amount
  ) external;

  function withdrawReserves(address to, uint256 amount) external;

  function withdrawTo(address to, address asset, uint256 amount) external;

  function balanceOf(address account) external view returns (uint256);

  function baseBorrowMin() external view returns (uint256);

  function baseMinForRewards() external view returns (uint256);

  function baseScale() external view returns (uint256);

  function baseToken() external view returns (address);

  function baseTokenPriceFeed() external view returns (address);

  function baseTrackingBorrowSpeed() external view returns (uint256);

  function baseTrackingSupplySpeed() external view returns (uint256);

  function borrowBalanceOf(address account) external view returns (uint256);

  function borrowKink() external view returns (uint256);

  function borrowPerSecondInterestRateBase() external view returns (uint256);

  function borrowPerSecondInterestRateSlopeHigh()
    external
    view
    returns (uint256);

  function borrowPerSecondInterestRateSlopeLow()
    external
    view
    returns (uint256);

  function decimals() external view returns (uint8);

  function extensionDelegate() external view returns (address);

  function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

  function getAssetInfoByAddress(
    address asset
  ) external view returns (AssetInfo memory);

  function getBorrowRate(uint256 utilization) external view returns (uint64);

  function getCollateralReserves(address asset) external view returns (uint256);

  function getPrice(address priceFeed) external view returns (uint256);

  function getReserves() external view returns (int256);

  function getSupplyRate(uint256 utilization) external view returns (uint64);

  function getUtilization() external view returns (uint256);

  function governor() external view returns (address);

  function hasPermission(
    address owner,
    address manager
  ) external view returns (bool);

  function isAbsorbPaused() external view returns (bool);

  function isAllowed(address, address) external view returns (bool);

  function isBorrowCollateralized(address account) external view returns (bool);

  function isBuyPaused() external view returns (bool);

  function isLiquidatable(address account) external view returns (bool);

  function isSupplyPaused() external view returns (bool);

  function isTransferPaused() external view returns (bool);

  function isWithdrawPaused() external view returns (bool);

  function liquidatorPoints(
    address
  )
    external
    view
    returns (
      uint32 numAbsorbs,
      uint64 numAbsorbed,
      uint128 approxSpend,
      uint32 _reserved
    );

  function numAssets() external view returns (uint8);

  function pauseGuardian() external view returns (address);

  function quoteCollateral(
    address asset,
    uint256 baseAmount
  ) external view returns (uint256);

  function storeFrontPriceFactor() external view returns (uint256);

  function supplyKink() external view returns (uint256);

  function supplyPerSecondInterestRateBase() external view returns (uint256);

  function supplyPerSecondInterestRateSlopeHigh()
    external
    view
    returns (uint256);

  function supplyPerSecondInterestRateSlopeLow()
    external
    view
    returns (uint256);

  function targetReserves() external view returns (uint256);

  function totalBorrow() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalsCollateral(
    address
  ) external view returns (uint128 totalSupplyAsset, uint128 _reserved);

  function trackingIndexScale() external view returns (uint256);

  function userBasic(
    address
  )
    external
    view
    returns (
      int104 principal,
      uint64 baseTrackingIndex,
      uint64 baseTrackingAccrued,
      uint16 assetsIn,
      uint8 _reserved
    );

  function userCollateral(
    address,
    address
  ) external view returns (uint128 balance, uint128 _reserved);

  function userNonce(address) external view returns (uint256);
}
