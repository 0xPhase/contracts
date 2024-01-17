// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20SnapshotUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ERC20PermitUpgradeable} from "../lib/token/ERC20/ERC20PermitUpgradeable.sol";
import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {ISystemClock} from "../clock/ISystemClock.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {ILiquidity} from "./ILiquidity.sol";
import {IDB} from "../db/IDB.sol";

abstract contract LiquidityV1Storage is
  ILiquidity,
  Initializable,
  ProxyInitializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  ERC20SnapshotUpgradeable,
  ERC20PermitUpgradeable,
  AccessControl
{
  IPegToken public cash;
  IERC20 public underlying;

  uint256[2] public balances;

  ISystemClock internal _clock;

  /// @notice Disables initialization on the target contract
  constructor() initializer {
    _disableInitialization();
  }

  function initializeLiquidityV1(
    IDB db_,
    IPegToken cash_,
    IERC20 underlying_
  ) external initialize("v1") initializer {
    require(
      address(cash_) != address(0),
      "LiquidityStorageV1: cash_ cannot be zero address"
    );

    require(
      address(underlying_) != address(0),
      "LiquidityStorageV1: underlying_ cannot be zero address"
    );

    ERC20 _cash = ERC20(address(cash_));
    ERC20 _underlying = ERC20(address(underlying_));

    string memory fullName = string.concat(
      "Phase ",
      _cash.symbol(),
      "/",
      _underlying.symbol(),
      " Liquidity"
    );

    string memory fullSymbol = string.concat(
      "PLP-",
      _cash.symbol(),
      "-",
      _underlying.symbol()
    );

    __ERC20_init(fullName, fullSymbol);
    __ERC20Burnable_init();
    __ERC20Snapshot_init();
    __ERC20Permit_init(fullName, db_);

    _initializeElement(db_);

    cash = cash_;
    underlying = underlying_;

    _clock = ISystemClock(db_.getAddress("SYSTEM_CLOCK"));
  }

  // The following functions are overrides required by Solidity.

  /// @inheritdoc	ERC20Upgradeable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
