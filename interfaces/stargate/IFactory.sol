// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IFactory {
  function createPool(
    uint256 _poolId,
    address _token,
    uint8 _sharedDecimals,
    uint8 _localDecimals,
    string memory _name,
    string memory _symbol
  ) external returns (address poolAddress);

  function renounceOwnership() external;

  function setDefaultFeeLibrary(address _defaultFeeLibrary) external;

  function transferOwnership(address newOwner) external;

  function allPools(uint256) external view returns (address);

  function allPoolsLength() external view returns (uint256);

  function defaultFeeLibrary() external view returns (address);

  function getPool(uint256) external view returns (address);

  function owner() external view returns (address);

  function router() external view returns (address);
}
