// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ITreasury} from "../../treasury/ITreasury.sol";
import {StringLib} from "../../lib/StringLib.sol";
import {IOracle} from "../../oracle/IOracle.sol";
import {ShareLib} from "../../lib/ShareLib.sol";
import {ILiquidator} from "../ILiquidator.sol";
import {Storage} from "../../misc/Storage.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {VaultV1Storage} from "../IVault.sol";
import {IInterest} from "../IInterest.sol";

contract VaultV1 is VaultV1Storage {
  using SafeERC20 for IERC20;
  using StringLib for string;
  using ShareLib for uint256;

  modifier updateDebt() {
    if (collectiveDebt == 0) {
      lastDebtUpdate = block.timestamp;
    }

    uint256 increase = _debtIncrease();

    if (_mintFees(increase)) {
      collectiveDebt += increase;
      lastDebtUpdate = block.timestamp;
    }

    _;
  }

  modifier freezeCheck() {
    require(!contextLocked, "VaultV1: Context locked");
    require(!marketsLocked, "VaultV1: Markets locked");

    contextLocked = true;
    _;
    contextLocked = false;
  }

  modifier updateUser(uint256 user) {
    UserInfo storage info = userInfo[user];

    if (info.version < 1) {
      if (info.version == 0) {
        info.healthTarget = healthTargetMinimum;
        info.version++;
      }
    }

    _;
  }

  modifier ownerCheck(uint256 tokenId, address sender) {
    require(
      sender == creditAccount.ownerOf(tokenId),
      "VaultV1: Not owner of token"
    );

    _;
  }

  function addCollateral(uint256 user, uint256 amount)
    external
    override
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(amount > 0, "VaultV1: Cannot add 0 collateral");

    asset.safeTransferFrom(msg.sender, address(this), amount);

    userInfo[user].deposit += amount;

    emit CollateralAdded(user, amount);
  }

  function removeCollateral(uint256 user, uint256 amount)
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(deposit(user) >= amount, "VaultV1: Removing too much collateral");

    uint256 value = depositValue(user);
    uint256 debt = debtValue(user);
    uint256 newValue = value - _depositValue(amount);

    require(newValue >= debt, "VaultV1: Not enough collateral to support debt");

    userInfo[user].deposit -= amount;
    asset.safeTransfer(msg.sender, amount);

    emit CollateralRemoved(user, amount);
  }

  function mintUSD(uint256 user, uint256 amount)
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    contextLocked = false;
    mintUSD(user, amount, false);
  }

  function mintUSD(
    uint256 user,
    uint256 amount,
    bool useMax
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(amount > 0, "VaultV1: Cannot mint 0 CASH");

    uint256 value = depositValue(user);
    uint256 debt = debtValue(user);
    uint256 fee = (amount * borrowFee) / 1 ether;
    uint256 borrow = amount + fee;

    if (value < debt + borrow) {
      if (useMax && value > debt) {
        contextLocked = false;

        mintUSD(
          user,
          ((value - debt) * 1 ether) / (1 ether + borrowFee),
          false
        );
      } else {
        revert("VaultV1: Minting too much");
      }
    }

    _mintFees(fee);

    uint256 shares = totalDebtShares == 0
      ? borrow
      : borrow.calculateShares(totalDebtShares, collectiveDebt);

    collectiveDebt += borrow;
    userInfo[user].debtShares += shares;
    totalDebtShares += shares;

    cash.mintManager(msg.sender, amount);

    emit USDMinted(user, amount, fee);
  }

  function repayUSD(uint256 user, uint256 shares)
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    contextLocked = false;
    repayUSD(user, shares, false);
  }

  function repayUSD(
    uint256 user,
    uint256 shares,
    bool useMax
  )
    public
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(shares > 0, "VaultV1: Cannot repay 0 shares");

    require(
      userInfo[user].debtShares >= shares,
      "VaultV1: Repaying too many shares"
    );

    uint256 toRepay = _debtValue(shares);
    uint256 userBalance = IERC20(address(cash)).balanceOf(msg.sender);

    if (toRepay > userBalance) {
      if (useMax) {
        contextLocked = false;

        repayUSD(
          user,
          userBalance.calculateShares(totalDebtShares, collectiveDebt) - 1,
          false
        );

        return;
      } else {
        revert("Vault V1: Not enough balance");
      }
    }

    collectiveDebt -= toRepay;
    userInfo[user].debtShares -= shares;
    totalDebtShares -= shares;

    cash.burnManager(msg.sender, toRepay);

    emit USDRepaid(user, shares, toRepay);
  }

  function setHealthTarget(uint256 user, uint256 healthTarget)
    external
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    require(
      healthTarget >= healthTargetMinimum,
      "VaultV1: Health target too low"
    );
    require(
      healthTarget <= healthTargetMaximum,
      "VaultV1: Health target too high"
    );

    userInfo[user].healthTarget = healthTarget;

    emit HealthTargetSet(user, healthTarget);
  }

  function liquidateUser(uint256 user)
    external
    override
    freezeCheck
    updateDebt
  {
    LiquidationInfo memory info = liquidationInfo(user);

    require(!info.solvent, "VaultV1: User is solvent");

    if (info.rebate > 0) {
      treasury.spend(REBATE_CAUSE, address(cash), info.rebate, msg.sender);
    }

    uint256 debtShares = info.borrowChange.calculateShares(
      totalDebtShares,
      collectiveDebt
    );

    userInfo[user].deposit -= info.assetReward;
    userInfo[user].debtShares -= debtShares;

    totalDebtShares -= debtShares;
    collectiveDebt -= info.borrowChange;

    asset.transfer(address(treasury), info.protocolFee);
    treasury.increaseUnsafe(PROTOCOL_CAUSE, address(asset), info.protocolFee);

    asset.safeTransfer(msg.sender, info.assetReward - info.protocolFee);
    _checkLiquidator(msg.sender, user, info);
    cash.burnManager(msg.sender, info.borrowChange);

    emit UserLiquidated(
      user,
      msg.sender,
      info.borrowChange,
      info.assetReward,
      info.protocolFee,
      info.rebate
    );
  }

  function setPriceOracle(IOracle newPriceOracle)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceOracle = newPriceOracle;

    emit NewPriceOracle(msg.sender, newPriceOracle);
  }

  function setInterest(IInterest newInterest)
    external
    updateDebt
    onlyRole(MANAGER_ROLE)
  {
    interest = newInterest;

    emit NewInterest(msg.sender, newInterest);
  }

  function setMaxCollateralRatio(uint256 newMaxCollateralRatio)
    external
    onlyRole(MANAGER_ROLE)
  {
    maxCollateralRatio = newMaxCollateralRatio;

    emit NewMaxCollateralRatio(msg.sender, newMaxCollateralRatio);
  }

  function setBorrowFee(uint256 newBorrowFee) external onlyRole(MANAGER_ROLE) {
    borrowFee = newBorrowFee;

    emit NewBorrowFee(msg.sender, newBorrowFee);
  }

  function setLiquidationFee(uint256 newLiquidationFee)
    external
    onlyRole(MANAGER_ROLE)
  {
    liquidationFee = newLiquidationFee;

    emit NewLiquidationFee(msg.sender, newLiquidationFee);
  }

  function setMarketState(bool newState) external onlyRole(MANAGER_ROLE) {
    marketsLocked = !newState;

    emit NewMarketState(msg.sender, newState);
  }

  function increaseMaxMint(uint256 increase) external onlyRole(MANAGER_ROLE) {
    maxMint += increase;

    emit MaxMintIncreased(msg.sender, maxMint, increase);
  }

  function isSolvent(uint256 user) public view returns (bool) {
    return depositValue(user) >= debtValue(user);
  }

  function debtValue(uint256 user) public view returns (uint256) {
    return _debtValue(userInfo[user].debtShares);
  }

  function depositValue(uint256 user) public view returns (uint256) {
    return _depositValue(userInfo[user].deposit);
  }

  function deposit(uint256 user) public view returns (uint256) {
    return userInfo[user].deposit;
  }

  function price() public view override returns (uint256) {
    return priceOracle.getPrice(address(asset));
  }

  function collectiveCollateral() public view override returns (uint256) {
    return asset.balanceOf(address(this));
  }

  function liquidationInfo(uint256 user)
    public
    view
    override
    returns (LiquidationInfo memory)
  {
    if (isSolvent(user)) {
      return LiquidationInfo(true, 0, 0, 0, 0);
    }

    (uint256 borrowChange, uint256 collateralChange) = _liquidationAmount(user);

    if (borrowChange == 0 || collateralChange == 0) {
      return LiquidationInfo(true, 0, 0, 0, 0);
    }

    uint256 tPrice = price();
    uint256 collateralValue = _scaleFromAsset(
      userInfo[user].deposit * price()
    ) / 1 ether;
    uint256 cappedChange = Math.min(collateralValue, collateralChange);
    uint256 pureChange = _withoutFee(cappedChange);
    uint256 totalFee = cappedChange - pureChange;
    uint256 protocolFee = _scaleToAsset(
      (totalFee * _treasuryLiquidationPortion()) / 1 ether
    );

    // Non important safeguard!
    uint256 realTokens = Math.min(
      deposit(user),
      _scaleToAsset((cappedChange * 1 ether) / (tPrice))
    );

    uint256 rebate = 0;

    if (pureChange > collateralValue) {
      rebate = Math.min(
        treasury.tokenBalance(REBATE_CAUSE, address(cash)),
        pureChange - collateralValue
      );
    }

    return
      LiquidationInfo(false, borrowChange, realTokens, protocolFee, rebate);
  }

  function getInterest() public view returns (uint256) {
    return interest.getInterest(this);
  }

  function _checkLiquidator(
    address liquidator,
    uint256 to,
    LiquidationInfo memory info
  ) internal {
    bool result = true;

    try ILiquidator(liquidator).receiveLiquidation(to, info) returns (
      bytes4 retval
    ) {
      result = retval == ILiquidator.receiveLiquidation.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert("VaultV1: Not an ILiquidator contract :: ZL");
      } else {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }

    require(result, "VaultV1: Not an ILiquidator contract :: Result");
  }

  function _mintFees(uint256 increase) internal returns (bool) {
    uint256 treasuryPortion = _treasuryFeePortion();

    uint256 rebateAmount = (increase * treasuryPortion) / 1 ether;
    uint256 protocolAmount = increase - rebateAmount;

    if (rebateAmount == 0 || protocolAmount == 0) return false;

    cash.mintManager(address(treasury), increase);

    treasury.increaseUnsafe(REBATE_CAUSE, address(cash), rebateAmount);
    treasury.increaseUnsafe(PROTOCOL_CAUSE, address(cash), protocolAmount);

    return true;
  }

  function _debtIncrease() internal view returns (uint256) {
    if (block.timestamp > lastDebtUpdate) {
      uint256 difference = block.timestamp - lastDebtUpdate;

      uint256 increase = (collectiveDebt * difference * getInterest()) /
        (365.25 days * 1 ether);

      return increase;
    }

    return 0;
  }

  function _depositValue(uint256 amount) internal view returns (uint256) {
    if (amount == 0) return 0;

    return
      _scaleFromAsset(price() * amount * maxCollateralRatio) /
      (1 ether * 1 ether);
  }

  function _debtValue(uint256 shares) internal view returns (uint256) {
    if (shares == 0 || totalDebtShares == 0 || collectiveDebt == 0) return 0;

    return
      shares.calculateAmount(totalDebtShares, collectiveDebt + _debtIncrease());
  }

  function _liquidationAmount(uint256 user)
    internal
    view
    returns (uint256 debtChange, uint256 collateralChange)
  {
    UserInfo storage info = userInfo[user];
    uint256 collateral = _scaleFromAsset(info.deposit * price()) / 1 ether;
    uint256 debt = debtValue(user);

    if (collateral == 0 || debt == 0) return (0, 0);

    uint256 feefullDebt = _withFee(debt);

    if (
      collateral <= varStorage.readUint256(STEP_MIN_DEPOSIT) ||
      feefullDebt >= collateral
    ) {
      return (debt, feefullDebt);
    }

    uint256 targetHealth = info.healthTarget;

    debtChange = ((1 ether *
      (debt *
        1 ether**uint256(2) -
        (collateral * targetHealth * maxCollateralRatio))) /
      (1 ether**uint256(3) -
        (targetHealth * maxCollateralRatio * 1 ether) -
        (liquidationFee * targetHealth * maxCollateralRatio)));

    collateralChange = _withFee(debtChange);

    // ((y*(debt_*y^(2)-collat_*health_*mcr_))/(y^(3)-health_*mcr_*y-fee_*health_*mcr_))
  }

  function _withFee(uint256 amount) internal view returns (uint256) {
    return amount + ((amount * liquidationFee) / (1 ether));

    // w_=x_+((x_*fee_)/(y))
  }

  function _withoutFee(uint256 amount) internal view returns (uint256) {
    return ((amount * 1 ether) / (1 ether + liquidationFee));

    // x_=((w_*y)/(y+fee_))
  }

  function _treasuryFeePortion() internal view returns (uint256) {
    return Math.min(varStorage.readUint256(TREASURY_FEE_PORTION), 0.5 ether);
  }

  function _treasuryLiquidationPortion() internal view returns (uint256) {
    return
      Math.min(varStorage.readUint256(TREASURY_LIQUIDATION_PORTION), 0.5 ether);
  }

  function _scaleFromAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, ERC20(address(asset)).decimals(), 18);
  }

  function _scaleToAsset(uint256 amount) internal view returns (uint256) {
    return MathLib.scaleAmount(amount, 18, ERC20(address(asset)).decimals());
  }
}
