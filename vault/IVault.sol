// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC20SnapshotUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {CreditAccountV1} from "../account/versions/CreditAccountV1.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {ITreasury} from "../treasury/ITreasury.sol";
import {StringLib} from "../lib/StringLib.sol";
import {ILiquidator} from "./ILiquidator.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {ShareLib} from "../lib/ShareLib.sol";
import {Storage} from "../misc/Storage.sol";
import {Manager} from "../core/Manager.sol";
import {IInterest} from "./IInterest.sol";
import {ICash} from "../core/ICash.sol";
import {IDB} from "../db/IDB.sol";

interface IVault {
  struct LiquidationInfo {
    // Liquidation info
    bool solvent;
    uint256 borrowChange;
    uint256 assetReward;
    uint256 protocolFee;
    uint256 rebate;
  }

  struct UserInfo {
    // User info
    uint256 version;
    uint256 deposit;
    uint256 debtShares;
    uint256 healthTarget;
  }

  struct UserYield {
    // User yield
    EnumerableSet.AddressSet yieldSources;
  }

  struct YieldInfo {
    // Yield info
    bool enabled;
  }

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

  event NewPriceOracle(address indexed setter, IOracle newPriceOracle);

  event NewInterest(address indexed setter, IInterest newInterest);

  event NewMaxCollateralRatio(
    address indexed setter,
    uint256 newMaxCollateralRatio
  );

  event NewBorrowFee(address indexed setter, uint256 newBorrowFee);

  event NewLiquidationFee(address indexed setter, uint256 newLiquidationFee);

  event NewHealthTargetMinimum(
    address indexed setter,
    uint256 newHealthTargetMinimum
  );

  event NewHealthTargetMaximum(
    address indexed setter,
    uint256 newHealthTargetMaximum
  );

  event NewMarketState(address indexed setter, bool newState);

  event MaxMintIncreased(
    address indexed setter,
    uint256 newMax,
    uint256 increase
  );

  function addCollateral(uint256 user, uint256 amount) external;

  function removeCollateral(uint256 user, uint256 amount) external;

  function mintUSD(uint256 user, uint256 amount) external;

  function mintUSD(
    uint256 user,
    uint256 amount,
    bool useMax
  ) external;

  function repayUSD(uint256 user, uint256 shares) external;

  function repayUSD(
    uint256 user,
    uint256 shares,
    bool useMax
  ) external;

  function depositYield(
    uint256 user,
    address yield,
    uint256 amount
  ) external;

  function withdrawYield(
    uint256 user,
    address yield,
    uint256 amount
  ) external;

  function withdrawFullYield(uint256 user, address yield) external;

  function withdrawEverythingYield(uint256 user) external;

  function setHealthTarget(uint256 user, uint256 healthTarget) external;

  function liquidateUser(uint256 user) external;

  function isSolvent(uint256 user) external view returns (bool);

  function debtValue(uint256 user) external view returns (uint256);

  function depositValue(uint256 shares) external view returns (uint256);

  function deposit(uint256 user) external view returns (uint256);

  function yieldDeposit(uint256 user) external view returns (uint256);

  function pureDeposit(uint256 user) external view returns (uint256);

  function yieldSources(uint256 user) external view returns (address[] memory);

  function price() external view returns (uint256);

  function collectiveCollateral() external view returns (uint256);

  function liquidationInfo(uint256 user)
    external
    view
    returns (LiquidationInfo memory);

  function allYieldSources() external view returns (address[] memory);

  function userInfo(uint256 user)
    external
    view
    returns (
      uint256 version,
      uint256 deposit,
      uint256 debtShares,
      uint256 healthTarget
    );

  function yieldInfo(address user) external view returns (bool enabled);

  function manager() external view returns (Manager);

  function cash() external view returns (ICash);

  function treasury() external view returns (ITreasury);

  function varStorage() external view returns (Storage);

  function asset() external view returns (IERC20);

  function priceOracle() external view returns (IOracle);

  function maxMint() external view returns (uint256);

  function interest() external view returns (IInterest);

  function maxCollateralRatio() external view returns (uint256);

  function borrowFee() external view returns (uint256);

  function liquidationFee() external view returns (uint256);

  function healthTargetMinimum() external view returns (uint256);

  function healthTargetMaximum() external view returns (uint256);

  function collectiveDebt() external view returns (uint256);

  function totalDebtShares() external view returns (uint256);

  function lastDebtUpdate() external view returns (uint256);

  function contextLocked() external view returns (bool);

  function marketsLocked() external view returns (bool);
}

abstract contract VaultV1Storage is
  AccessControl,
  Initializable,
  ProxyInitializable,
  Multicall,
  IVault
{
  bytes32 public constant REBATE_CAUSE = keccak256("REBATE_CAUSE");
  bytes32 public constant PROTOCOL_CAUSE = keccak256("PROTOCOL_CAUSE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  bytes32 public constant TREASURY_FEE_PORTION =
    keccak256("TREASURY_FEE_PORTION");
  bytes32 public constant TREASURY_LIQUIDATION_PORTION =
    keccak256("TREASURY_LIQUIDATION_PORTION");
  bytes32 public constant STEP_MIN_DEPOSIT = keccak256("STEP_MIN_DEPOSIT");

  mapping(uint256 => UserInfo) public userInfo;
  mapping(uint256 => UserYield) internal _userYield;
  EnumerableSet.AddressSet internal _yieldSources;
  mapping(address => YieldInfo) public yieldInfo;

  Manager public manager;
  CreditAccountV1 public creditAccount;
  ICash public cash;
  ITreasury public treasury;
  Storage public varStorage;
  IInterest public interest;
  IERC20 public asset;

  IOracle public priceOracle;
  uint256 public maxMint;
  uint256 public maxCollateralRatio;
  uint256 public borrowFee;
  uint256 public liquidationFee;
  uint256 public healthTargetMinimum;
  uint256 public healthTargetMaximum;

  uint256 public collectiveDebt;
  uint256 public totalDebtShares;
  uint256 public lastDebtUpdate;

  bool public contextLocked;
  bool public marketsLocked;

  function initializeVaultV1(
    IDB db_,
    Storage varStorage_,
    IERC20 asset_,
    IOracle priceOracle_,
    IInterest interest_,
    uint256 initialMaxMint_,
    uint256 initialMaxCollateralRatio_,
    uint256 initialBorrowFee_,
    uint256 initialLiquidationFee_,
    uint256 initialHealthTargetMinimum_,
    uint256 initialHealthTargetMaximum_
  ) external initialize("v1") initializer {
    _setDB(db_);

    address managerAddress = db_.getAddress("MANAGER");

    manager = Manager(managerAddress);
    creditAccount = CreditAccountV1(db_.getAddress("CREDIT_ACCOUNT"));
    cash = ICash(db_.getAddress("CASH"));
    treasury = ITreasury(db_.getAddress("TREASURY"));

    varStorage = varStorage_;
    asset = asset_;
    priceOracle = priceOracle_;
    interest = interest_;

    maxMint = initialMaxMint_;
    maxCollateralRatio = initialMaxCollateralRatio_;
    borrowFee = initialBorrowFee_;
    liquidationFee = initialLiquidationFee_;
    healthTargetMinimum = initialHealthTargetMinimum_;
    healthTargetMaximum = initialHealthTargetMaximum_;

    lastDebtUpdate = block.timestamp;

    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));

    emit NewPriceOracle(managerAddress, priceOracle_);
    emit NewInterest(managerAddress, interest_);
    emit NewMaxCollateralRatio(managerAddress, initialMaxCollateralRatio_);
    emit NewBorrowFee(managerAddress, initialBorrowFee_);
    emit NewLiquidationFee(managerAddress, initialLiquidationFee_);
    emit NewHealthTargetMinimum(managerAddress, initialHealthTargetMinimum_);
    emit NewHealthTargetMaximum(managerAddress, initialHealthTargetMaximum_);
  }

  // The following functions are overrides required by Solidity.
}
