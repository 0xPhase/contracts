// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IPool {
  struct CreditObj {
    uint256 credits;
    uint256 idealBalance;
  }

  struct SwapObj {
    uint256 amount;
    uint256 eqFee;
    uint256 eqReward;
    uint256 lpFee;
    uint256 protocolFee;
    uint256 lkbRemove;
  }

  struct ChainPath {
    bool ready;
    uint16 dstChainId;
    uint256 dstPoolId;
    uint256 weight;
    uint256 balance;
    uint256 lkb;
    uint256 credits;
    uint256 idealBalance;
  }

  function activateChainPath(uint16 _dstChainId, uint256 _dstPoolId) external;

  function approve(address spender, uint256 value) external returns (bool);

  function callDelta(bool _fullMode) external;

  function createChainPath(
    uint16 _dstChainId,
    uint256 _dstPoolId,
    uint256 _weight
  ) external;

  function creditChainPath(
    uint16 _dstChainId,
    uint256 _dstPoolId,
    CreditObj memory _c
  ) external;

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) external returns (bool);

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) external returns (bool);

  function instantRedeemLocal(
    address _from,
    uint256 _amountLP,
    address _to
  ) external returns (uint256 amountSD);

  function mint(address _to, uint256 _amountLD) external returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function redeemLocal(
    address _from,
    uint256 _amountLP,
    uint16 _dstChainId,
    uint256 _dstPoolId,
    bytes memory _to
  ) external returns (uint256 amountSD);

  function redeemLocalCallback(
    uint16 _srcChainId,
    uint256 _srcPoolId,
    address _to,
    uint256 _amountSD,
    uint256 _amountToMintSD
  ) external;

  function redeemLocalCheckOnRemote(
    uint16 _srcChainId,
    uint256 _srcPoolId,
    uint256 _amountSD
  ) external returns (uint256 swapAmount, uint256 mintAmount);

  function redeemRemote(
    uint16 _dstChainId,
    uint256 _dstPoolId,
    address _from,
    uint256 _amountLP
  ) external;

  function sendCredits(
    uint16 _dstChainId,
    uint256 _dstPoolId
  ) external returns (CreditObj memory c);

  function setDeltaParam(
    bool _batched,
    uint256 _swapDeltaBP,
    uint256 _lpDeltaBP,
    bool _defaultSwapMode,
    bool _defaultLPMode
  ) external;

  function setFee(uint256 _mintFeeBP) external;

  function setFeeLibrary(address _feeLibraryAddr) external;

  function setSwapStop(bool _swapStop) external;

  function setWeightForChainPath(
    uint16 _dstChainId,
    uint256 _dstPoolId,
    uint16 _weight
  ) external;

  function swap(
    uint16 _dstChainId,
    uint256 _dstPoolId,
    address _from,
    uint256 _amountLD,
    uint256 _minAmountLD,
    bool newLiquidity
  ) external returns (SwapObj memory);

  function swapRemote(
    uint16 _srcChainId,
    uint256 _srcPoolId,
    address _to,
    SwapObj memory _s
  ) external returns (uint256 amountLD);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function withdrawMintFeeBalance(address _to) external;

  function withdrawProtocolFeeBalance(address _to) external;

  function BP_DENOMINATOR() external view returns (uint256);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function allowance(address, address) external view returns (uint256);

  function amountLPtoLD(uint256 _amountLP) external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function batched() external view returns (bool);

  function chainPathIndexLookup(
    uint16,
    uint256
  ) external view returns (uint256);

  function chainPaths(
    uint256
  )
    external
    view
    returns (
      bool ready,
      uint16 dstChainId,
      uint256 dstPoolId,
      uint256 weight,
      uint256 balance,
      uint256 lkb,
      uint256 credits,
      uint256 idealBalance
    );

  function convertRate() external view returns (uint256);

  function decimals() external view returns (uint256);

  function defaultLPMode() external view returns (bool);

  function defaultSwapMode() external view returns (bool);

  function deltaCredit() external view returns (uint256);

  function eqFeePool() external view returns (uint256);

  function feeLibrary() external view returns (address);

  function getChainPath(
    uint16 _dstChainId,
    uint256 _dstPoolId
  ) external view returns (ChainPath memory);

  function getChainPathsLength() external view returns (uint256);

  function localDecimals() external view returns (uint256);

  function lpDeltaBP() external view returns (uint256);

  function mintFeeBP() external view returns (uint256);

  function mintFeeBalance() external view returns (uint256);

  function name() external view returns (string memory);

  function nonces(address) external view returns (uint256);

  function poolId() external view returns (uint256);

  function protocolFeeBalance() external view returns (uint256);

  function router() external view returns (address);

  function sharedDecimals() external view returns (uint256);

  function stopSwap() external view returns (bool);

  function swapDeltaBP() external view returns (uint256);

  function symbol() external view returns (string memory);

  function token() external view returns (address);

  function totalLiquidity() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalWeight() external view returns (uint256);
}
