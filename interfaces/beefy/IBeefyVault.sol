// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IBeefyVault {
  function approve(address spender, uint256 amount) external returns (bool);

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) external returns (bool);

  function deposit(uint256 _amount) external;

  function depositAll() external;

  function earn() external;

  function inCaseTokensGetStuck(address _token) external;

  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) external returns (bool);

  function initialize(
    address _strategy,
    string memory _name,
    string memory _symbol,
    uint256 _approvalDelay
  ) external;

  function proposeStrat(address _implementation) external;

  function renounceOwnership() external;

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function transferOwnership(address newOwner) external;

  function upgradeStrat() external;

  function withdraw(uint256 _shares) external;

  function withdrawAll() external;

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approvalDelay() external view returns (uint256);

  function available() external view returns (uint256);

  function balance() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function decimals() external view returns (uint8);

  function getPricePerFullShare() external view returns (uint256);

  function name() external view returns (string memory);

  function owner() external view returns (address);

  function stratCandidate()
    external
    view
    returns (address implementation, uint256 proposedTime);

  function strategy() external view returns (address);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function want() external view returns (address);
}
