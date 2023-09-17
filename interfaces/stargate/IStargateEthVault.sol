// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IStargateEthVault {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function balanceOf(address guy) external view returns (uint256);
}
