// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface ICometExt {
  struct TotalsBasic {
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
  }

  function allow(address manager, bool isAllowed_) external;

  function allowBySig(
    address owner,
    address manager,
    bool isAllowed_,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function approve(address spender, uint256 amount) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function baseTrackingAccrued(address account) external view returns (uint64);

  function collateralBalanceOf(
    address account,
    address asset
  ) external view returns (uint128);

  function hasPermission(
    address owner,
    address manager
  ) external view returns (bool);

  function isAllowed(address, address) external view returns (bool);

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

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function totalsBasic() external view returns (TotalsBasic memory);

  function totalsCollateral(
    address
  ) external view returns (uint128 totalSupplyAsset, uint128 _reserved);

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

  function version() external view returns (string memory);

  function baseAccrualScale() external pure returns (uint64);

  function baseIndexScale() external pure returns (uint64);

  function factorScale() external pure returns (uint64);

  function maxAssets() external pure returns (uint8);

  function priceScale() external pure returns (uint64);
}
