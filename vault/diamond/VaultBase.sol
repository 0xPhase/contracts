// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AccessControlBase} from "../../diamond/AccessControl/AccessControlBase.sol";
import {VaultStorage, UserInfo, UserYield, IVault} from "../IVault.sol";
import {OwnableBase} from "../../diamond/Ownable/OwnableBase.sol";
import {ITreasury} from "../../treasury/ITreasury.sol";
import {VaultConstants} from "./VaultConstants.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {IYield} from "../../yield/IYield.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {ICash} from "../../core/ICash.sol";
import {IInterest} from "../IInterest.sol";
import {IAdapter} from "../IAdapter.sol";

abstract contract VaultBase is OwnableBase, AccessControlBase {
  using EnumerableSet for EnumerableSet.AddressSet;

  VaultStorage internal _s;

  /// @notice Event emitted when collateral is added
  /// @param user The user id
  /// @param amount The collateral amount
  event CollateralAdded(uint256 indexed user, uint256 amount);

  /// @notice Event emitted when collateral is removed
  /// @param user The user id
  /// @param amount The collateral amount
  event CollateralRemoved(uint256 indexed user, uint256 amount);

  /// @notice Event emitted when CASH is minted
  /// @param user The user id
  /// @param amount The amount minted
  /// @param fee The fee taken
  event USDMinted(uint256 indexed user, uint256 amount, uint256 fee);

  /// @notice Event emitted when CASH is repaid and burned
  /// @param user The user id
  /// @param shares The amount of shares
  /// @param amount The amount of CASH
  event USDRepaid(uint256 indexed user, uint256 shares, uint256 amount);

  /// @notice Event emitted when the health target is set
  /// @param user The user id
  /// @param healthTarget The health target
  event HealthTargetSet(uint256 indexed user, uint256 healthTarget);

  /// @notice Event emitted when the user is liquidated
  /// @param user The user id
  /// @param liquidator The liquidator address
  /// @param borrowChange The amount the borrow changed
  /// @param assetReward The amount of underlying asset rewarded
  /// @param protocolFee The amount the protocol took as a fee
  /// @param rebate The amount of rebate given for possibly underwater debt
  event UserLiquidated(
    uint256 indexed user,
    address indexed liquidator,
    uint256 borrowChange,
    uint256 assetReward,
    uint256 protocolFee,
    uint256 rebate
  );

  /// @notice Event emitted when the price oracle contract is set
  /// @param newPriceOracle The new price oracle contract
  event PriceOracleSet(IOracle newPriceOracle);

  /// @notice Event emitted when the interest contract is set
  /// @param newInterest the new interest contract
  event InterestSet(IInterest newInterest);

  /// @notice Event emitted when the max collateral ratio is set
  /// @param newMaxCollateralRatio The new max collateral ratio
  event MaxCollateralRatioSet(uint256 newMaxCollateralRatio);

  /// @notice Event emitted when the borrow fee is set
  /// @param newBorrowFee The new borrow fee
  event BorrowFeeSet(uint256 newBorrowFee);

  /// @notice Event emitted when the liquidation fee is set
  /// @param newLiquidationFee The new liquidation fee
  event LiquidationFeeSet(uint256 newLiquidationFee);

  /// @notice Event emitted when the health target minimum is set
  /// @param newHealthTargetMinimum The new health target minimum
  event HealthTargetMinimumSet(uint256 newHealthTargetMinimum);

  /// @notice Event emitted when the health target maximum is set
  /// @param newHealthTargetMaximum The new health target maximum
  event HealthTargetMaximumSet(uint256 newHealthTargetMaximum);

  /// @notice Event emitted when the adapter address is set
  /// @param adapter The new adapter address
  event AdapterSet(address adapter);

  /// @notice Event emitted when the adapter data is set
  /// @param adapterData The new adapter data
  event AdapterDataSet(bytes adapterData);

  /// @notice Event emitted when the market state is set
  /// @param newState The new market state
  event MarketStateSet(bool newState);

  /// @notice Event emitted when the maximum amount of mintable CASH is increased
  /// @param newMax The new total max
  /// @param increase The increased amount
  event MintIncreasedSet(uint256 newMax, uint256 increase);

  /// @notice Updates the current total debt
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

  /// @notice Checks if the context or markets are locked and locks context until function is done
  modifier freezeCheck() {
    require(!_s.contextLocked, "VaultBase: Context locked");
    require(!_s.marketsLocked, "VaultBase: Markets locked");

    _s.contextLocked = true;
    _;
    _s.contextLocked = false;
  }

  /// @notice Updates the user info
  /// @param user The user id
  modifier updateUser(uint256 user) {
    UserInfo storage info = _s.userInfo[user];

    if (info.version == 0) {
      info.healthTarget = _s.healthTargetMinimum;
      info.version++;
    }

    _;
  }

  /// @notice Checks if the credit account id is owned by sender
  /// @param tokenId The account id to check
  /// @param sender The user to check against
  modifier ownerCheck(uint256 tokenId, address sender) {
    require(
      sender == IERC721(address(_s.creditAccount)).ownerOf(tokenId),
      "VaultBase: Not owner of token"
    );

    _;
  }

  // Shared functions

  /// @notice Withdraws all collateral from all yield sources for the user
  /// @param user The user id
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

  /// @notice Processes fees based on the fees collected
  /// @param value The fees collected
  /// @return If fees were minted
  function _mintFees(uint256 value) internal returns (bool) {
    uint256 treasuryPortion = _treasuryFee();
    uint256 rebatePortion = _rebateFee();

    uint256 treasuryAmount = (value * treasuryPortion) / 1 ether;
    uint256 rebateAmount = (value * rebatePortion) / 1 ether;
    uint256 bondAmount = value - treasuryAmount - rebateAmount;

    if (treasuryAmount == 0 || rebateAmount == 0 || bondAmount == 0)
      return false;

    ICash cash = _s.cash;
    ITreasury treasury = _s.treasury;
    uint256 totalTreasury = treasuryAmount + rebateAmount;

    cash.mintManager(address(treasury), totalTreasury);
    cash.mintManager(address(_s.bond), bondAmount);

    treasury.increaseUnsafe(
      VaultConstants.PROTOCOL_CAUSE,
      address(cash),
      treasuryAmount
    );

    treasury.increaseUnsafe(
      VaultConstants.REBATE_CAUSE,
      address(cash),
      rebateAmount
    );

    return true;
  }

  /// @notice Returns how much debt has increased
  /// @return The amount debt has increased
  function _debtIncrease() internal view returns (uint256) {
    uint256 lastDebtUpdate = _s.lastDebtUpdate;

    if (block.timestamp > lastDebtUpdate) {
      uint256 difference = block.timestamp - lastDebtUpdate;

      uint256 increase = (_s.collectiveDebt * difference * _interest()) /
        (365.25 days * 1 ether);

      return increase;
    }

    return 0;
  }

  /// @notice Returns if the user is solvent
  /// @param user The user id
  /// @return If the user is solvent
  function _isSolvent(uint256 user) internal view returns (bool) {
    return _depositValueUser(user) >= _debtValueUser(user);
  }

  /// @notice Returns the user's deposit value in dollars
  /// @param user The user id
  /// @return The deposit value
  function _depositValueUser(uint256 user) internal view returns (uint256) {
    return _depositValue(_deposit(user));
  }

  /// @notice Returns the deposit value of the amount in dollars
  /// @param amount The collateral amount
  /// @return The deposit value
  function _depositValue(uint256 amount) internal view returns (uint256) {
    if (amount == 0) return 0;

    return
      _scaleFromAsset(_price() * amount * _s.maxCollateralRatio) /
      (1 ether * 1 ether);
  }

  /// @notice Returns the user's debt value in dollars
  /// @param user The user id
  /// @return The debt value
  function _debtValueUser(uint256 user) internal view returns (uint256) {
    return _debtValue(_s.userInfo[user].debtShares);
  }

  /// @notice Returns the debt value of the shares in dollars
  /// @param shares The share count
  /// @return The debt value
  function _debtValue(uint256 shares) internal view returns (uint256) {
    uint256 totalDebtShares = _s.totalDebtShares;
    uint256 collectiveDebt = _s.collectiveDebt;

    if (shares == 0 || totalDebtShares == 0 || collectiveDebt == 0) return 0;

    return
      ShareLib.calculateAmount(
        shares,
        totalDebtShares,
        collectiveDebt + _debtIncrease()
      );
  }

  /// @notice Returns the user's total deposit in token amount
  /// @param user The user id
  /// @return The total deposit
  function _deposit(uint256 user) internal view returns (uint256) {
    return _yieldDeposit(user) + _pureDeposit(user);
  }

  /// @notice Returns the user's yield deposit in token amount
  /// @param user The user id
  /// @return result The yield deposit
  function _yieldDeposit(uint256 user) internal view returns (uint256 result) {
    UserYield storage yield = _s.userYield[user];
    uint256 length = yield.yieldSources.length();

    for (uint256 i = 0; i < length; i++) {
      result += IYield(yield.yieldSources.at(i)).balance(user);
    }
  }

  /// @notice Returns the user's vault deposit in token amount
  /// @param user The user id
  /// @return The vault deposit
  function _pureDeposit(uint256 user) internal view returns (uint256) {
    return _s.userInfo[user].deposit;
  }

  /// @notice Returns the price of the underlying asset from the oracle
  /// @return The underlying asset price
  function _price() internal view returns (uint256) {
    return _s.priceOracle.getPrice(address(_s.asset));
  }

  /// @notice Returns the interest rate for the vault
  /// @return The interest rate
  function _interest() internal view returns (uint256) {
    return _s.interest.getInterest(IVault(address(this)));
  }

  /// @notice Returns the treasury fee
  /// @return The treasury fee
  function _treasuryFee() internal view returns (uint256) {
    return
      MathLib.min(
        _s.varStorage.readUint256(VaultConstants.TREASURY_FEE),
        0.49 ether
      );
  }

  /// @notice Returns the rebate fee
  /// @return The rebate fee
  function _rebateFee() internal view returns (uint256) {
    return
      MathLib.min(
        _s.varStorage.readUint256(VaultConstants.REBATE_FEE),
        0.49 ether
      );
  }

  /// @notice Returns the step min deposit
  /// @return The step min deposit
  function _stepMinDeposit() internal view returns (uint256) {
    return _s.varStorage.readUint256(VaultConstants.STEP_MIN_DEPOSIT);
  }

  /// @notice Scales the amount from asset's decimals to 18 decimals
  /// @param amount The amount to scale
  /// @return The scaled amount
  function _scaleFromAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, ERC20(address(_s.asset)).decimals(), 18);
  }

  /// @notice Scales the amount from 18 decimals to asset's decimals
  /// @param amount The amount to scale
  /// @return The scaled amount
  function _scaleToAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, 18, ERC20(address(_s.asset)).decimals());
  }
}
