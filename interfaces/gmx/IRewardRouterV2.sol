// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IRewardRouterV2 {
  function withdrawToken(
    address _token,
    address _account,
    uint256 _amount
  ) external;

  function batchStakeGmxForAccount(
    address[] memory _accounts,
    uint256[] memory _amounts
  ) external;

  function stakeGmxForAccount(address _account, uint256 _amount) external;

  function stakeGmx(uint256 _amount) external;

  function stakeEsGmx(uint256 _amount) external;

  function unstakeGmx(uint256 _amount) external;

  function unstakeEsGmx(uint256 _amount) external;

  function mintAndStakeGlp(
    address _token,
    uint256 _amount,
    uint256 _minUsdg,
    uint256 _minGlp
  ) external;

  function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external;

  function unstakeAndRedeemGlp(
    address _tokenOut,
    uint256 _glpAmount,
    uint256 _minOut,
    address _receiver
  ) external;

  function unstakeAndRedeemGlpETH(
    uint256 _glpAmount,
    uint256 _minOut,
    address payable _receiver
  ) external;

  function compoundForAccount(address _account) external;

  function batchCompoundForAccounts(address[] memory _accounts) external;

  function signalTransfer(address _receiver) external;

  function acceptTransfer(address _sender) external;
}
