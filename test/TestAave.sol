// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {TestUSDC} from "./TestUSDC.sol";

struct ReserveConfigurationMap {
  uint256 data;
}

struct ReserveData {
  ReserveConfigurationMap configuration;
  uint128 liquidityIndex;
  uint128 currentLiquidityRate;
  uint128 variableBorrowIndex;
  uint128 currentVariableBorrowRate;
  uint128 currentStableBorrowRate;
  uint40 lastUpdateTimestamp;
  uint16 id;
  address aTokenAddress;
  address stableDebtTokenAddress;
  address variableDebtTokenAddress;
  address interestRateStrategyAddress;
  uint128 accruedToTreasury;
  uint128 unbacked;
  uint128 isolationModeTotalDebt;
}

contract AToken is ERC20, Ownable {
  TestAave internal immutable _aave;
  uint8 internal immutable _decimals;

  constructor(
    TestAave aave_,
    uint8 decimals_
  ) ERC20("Aave Test USDC", "atUSDC") {
    _aave = aave_;
    _decimals = decimals_;
  }

  /// @custom:protected onlyOwner
  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  /// @custom:protected onlyOwner
  function burn(address from, uint256 amount) public onlyOwner {
    _burn(from, amount);
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function balanceOf(address who) public view override returns (uint256) {
    (uint256 amount, ) = _aave.userInfo(who);
    return amount + _aave.increase(who);
  }
}

contract TestAave {
  using SafeERC20 for TestUSDC;

  struct UserInfo {
    uint256 amount;
    uint256 last;
  }

  uint256 public constant INTEREST = 2 ether;

  mapping(address => UserInfo) public userInfo;
  TestUSDC public testUSDC;
  AToken public atoken;

  modifier mintInterest(address user) {
    UserInfo storage info = userInfo[user];

    if (info.amount == 0) {
      info.last = block.timestamp;
    } else {
      testUSDC.mintAny(address(this), increase(user));

      info.last = block.timestamp;
    }

    _;
  }

  constructor(TestUSDC testUSDC_) {
    testUSDC = testUSDC_;
    atoken = new AToken(this, testUSDC_.decimals());
  }

  function deposit(
    address,
    uint256 amount,
    address,
    uint16
  ) external mintInterest(msg.sender) {
    testUSDC.safeTransferFrom(msg.sender, address(this), amount);

    userInfo[msg.sender].amount += amount;
  }

  function withdraw(
    address,
    uint256 amount,
    address
  ) external mintInterest(msg.sender) returns (uint256) {
    require(
      userInfo[msg.sender].amount >= amount,
      "TestAave: Not enough tokens"
    );

    userInfo[msg.sender].amount -= amount;

    testUSDC.safeTransfer(msg.sender, amount);

    return amount;
  }

  function getReserveData(address) external view returns (ReserveData memory) {
    return
      ReserveData(
        ReserveConfigurationMap(0),
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        address(atoken),
        address(0),
        address(0),
        address(0),
        0,
        0,
        0
      );
  }

  function increase(address user) public view returns (uint256 amount) {
    UserInfo storage info = userInfo[user];

    uint256 diff = block.timestamp - info.last;

    amount = (info.amount * diff * INTEREST) / (365.25 days * 1 ether);
  }
}
