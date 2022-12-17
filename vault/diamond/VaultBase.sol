// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AccessControlBase} from "../../diamond/AccessControl/AccessControlBase.sol";
import {VaultStorage, UserInfo, UserYield, IVault} from "../IVault.sol";
import {OwnableBase} from "../../diamond/Ownable/OwnableBase.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {IYield} from "../../yield/IYield.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {IInterest} from "../IInterest.sol";

abstract contract VaultBase is OwnableBase, AccessControlBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 internal constant _MANAGER_ROLE = keccak256("MANAGER_ROLE");

  VaultStorage internal _s;

  event CollateralAdded(uint256 indexed user, uint256 amount);

  event CollateralRemoved(uint256 indexed user, uint256 amount);

  event USDMinted(uint256 indexed user, uint256 amount, uint256 fee);

  event USDRepaid(uint256 indexed user, uint256 shares, uint256 amount);

  event HealthTargetSet(uint256 indexed user, uint256 healthTarget);

  event UserLiquidated(
    uint256 indexed user,
    address indexed liquidator,
    uint256 borrowChange,
    uint256 assetReward,
    uint256 protocolFee,
    uint256 rebate
  );

  event PriceOracleSet(IOracle newPriceOracle);

  event InterestSet(IInterest newInterest);

  event MaxCollateralRatioSet(uint256 newMaxCollateralRatio);

  event BorrowFeeSet(uint256 newBorrowFee);

  event LiquidationFeeSet(uint256 newLiquidationFee);

  event HealthTargetMinimumSet(uint256 newHealthTargetMinimum);

  event HealthTargetMaximumSet(uint256 newHealthTargetMaximum);

  event MarketStateSet(bool newState);

  event MintIncreasedSet(uint256 newMax, uint256 increase);

  modifier updateDebt() {
    if (_s.collectiveDebt == 0) {
      _s.lastDebtUpdate = block.timestamp;
    }

    uint256 increase = _debtIncrease();

    if (_mintFees(increase)) {
      _s.collectiveDebt += increase;
      _s.lastDebtUpdate = block.timestamp;
    }

    _;
  }

  modifier freezeCheck() {
    require(!_s.contextLocked, "VaultBase: Context locked");
    require(!_s.marketsLocked, "VaultBase: Markets locked");

    _s.contextLocked = true;
    _;
    _s.contextLocked = false;
  }

  modifier updateUser(uint256 user) {
    UserInfo storage info = _s.userInfo[user];

    if (info.version < 1) {
      if (info.version == 0) {
        info.healthTarget = _s.healthTargetMinimum;
        info.version++;
      }
    }

    _;
  }

  modifier ownerCheck(uint256 tokenId, address sender) {
    require(
      sender == IERC721(address(_s.creditAccount)).ownerOf(tokenId),
      "VaultBase: Not owner of token"
    );

    _;
  }

  // Shared functions

  function _withdrawEverythingYield(uint256 user) internal {
    UserYield storage yields = _s.userYield[user];
    UserInfo storage info = _s.userInfo[user];

    while (yields.yieldSources.length() > 0) {
      address yield = yields.yieldSources.at(0);
      uint256 amount = IYield(yield).receiveFullWithdraw(user);

      info.deposit += amount;

      yields.yieldSources.remove(yield);
    }
  }

  function _mintFees(uint256 value) internal returns (bool) {
    uint256 treasuryPortion = _treasuryFee();
    uint256 rebatePortion = _rebateFee();

    uint256 treasuryAmount = (value * treasuryPortion) / 1 ether;
    uint256 rebateAmount = (value * rebatePortion) / 1 ether;
    uint256 bondAmount = value - treasuryAmount - rebateAmount;

    if (treasuryAmount == 0 || rebateAmount == 0 || bondAmount == 0)
      return false;

    uint256 totalTreasury = treasuryAmount + rebateAmount;

    _s.cash.mintManager(address(_s.treasury), totalTreasury);
    _s.cash.mintManager(address(_s.bond), bondAmount);

    _s.treasury.increaseUnsafe(
      VaultConstants.PROTOCOL_CAUSE,
      address(_s.cash),
      treasuryAmount
    );

    _s.treasury.increaseUnsafe(
      VaultConstants.REBATE_CAUSE,
      address(_s.cash),
      rebateAmount
    );

    return true;
  }

  function _debtIncrease() internal view returns (uint256) {
    if (block.timestamp > _s.lastDebtUpdate) {
      uint256 difference = block.timestamp - _s.lastDebtUpdate;

      uint256 increase = (_s.collectiveDebt * difference * _interest()) /
        (365.25 days * 1 ether);

      return increase;
    }

    return 0;
  }

  function _isSolvent(uint256 user) internal view returns (bool) {
    return _depositValueUser(user) >= _debtValueUser(user);
  }

  function _depositValueUser(uint256 user) internal view returns (uint256) {
    return _depositValue(_deposit(user));
  }

  function _depositValue(uint256 amount) internal view returns (uint256) {
    if (amount == 0) return 0;

    return
      _scaleFromAsset(_price() * amount * _s.maxCollateralRatio) /
      (1 ether * 1 ether);
  }

  function _debtValueUser(uint256 user) internal view returns (uint256) {
    return _debtValue(_s.userInfo[user].debtShares);
  }

  function _debtValue(uint256 shares) internal view returns (uint256) {
    if (shares == 0 || _s.totalDebtShares == 0 || _s.collectiveDebt == 0)
      return 0;

    return
      ShareLib.calculateAmount(
        shares,
        _s.totalDebtShares,
        _s.collectiveDebt + _debtIncrease()
      );
  }

  function _deposit(uint256 user) internal view returns (uint256) {
    return _yieldDeposit(user) + _pureDeposit(user);
  }

  function _yieldDeposit(uint256 user) internal view returns (uint256 result) {
    UserYield storage yield = _s.userYield[user];
    uint256 length = yield.yieldSources.length();

    for (uint256 i = 0; i < length; i++) {
      result += IYield(yield.yieldSources.at(i)).balance(user);
    }
  }

  function _pureDeposit(uint256 user) internal view returns (uint256) {
    return _s.userInfo[user].deposit;
  }

  function _price() internal view returns (uint256) {
    return _s.priceOracle.getPrice(address(_s.asset));
  }

  function _interest() internal view returns (uint256) {
    return _s.interest.getInterest(IVault(address(this)));
  }

  function _treasuryFee() internal view returns (uint256) {
    return
      MathLib.min(
        _s.varStorage.readUint256(VaultConstants.TREASURY_FEE),
        0.49 ether
      );
  }

  function _rebateFee() internal view returns (uint256) {
    return
      MathLib.min(
        _s.varStorage.readUint256(VaultConstants.REBATE_FEE),
        0.49 ether
      );
  }

  function _stepMinDeposit() internal view returns (uint256) {
    return _s.varStorage.readUint256(VaultConstants.STEP_MIN_DEPOSIT);
  }

  function _scaleFromAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, ERC20(address(_s.asset)).decimals(), 18);
  }

  function _scaleToAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, 18, ERC20(address(_s.asset)).decimals());
  }
}
