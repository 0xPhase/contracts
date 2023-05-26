// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {ProxyInitializable} from "../proxy/utils/ProxyInitializable.sol";
import {ICreditAccount} from "../account/ICreditAccount.sol";
import {AccessControl} from "../core/AccessControl.sol";
import {IPegToken} from "../peg/IPegToken.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {Manager} from "../core/Manager.sol";
import {IVault} from "../vault/IVault.sol";
import {IDB} from "../db/IDB.sol";
import {IPSM} from "./IPSM.sol";

abstract contract PSMV1Storage is AccessControl, ProxyInitializable, IPSM {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  IPegToken public cash;
  IVault public vault;
  IERC20 public underlying;
  uint256 public creditAccount;
  address public bondAddress;
  uint256 public buyFee;
  uint256 public sellFee;
  uint256 public totalTraded;
  uint256 public totalFees;

  uint8 internal _underlyingDecimals;
  uint256 internal _lastUnderlyingBalance;

  // Constructor for the PSMV1Storage contract
  constructor() {
    _disableInitialization();
  }

  /// @notice Initializes the PSM cotnract
  /// @param db_ The DB contract address
  /// @param vault_ The underlying vault
  /// @param buyFee_ The initial buy fee
  /// @param sellFee_ The initial sell fee
  function initializePSMV1(
    IDB db_,
    IVault vault_,
    uint256 buyFee_,
    uint256 sellFee_
  ) external initialize("v1") {
    require(
      address(db_) != address(0),
      "PSMV1Storage: db_ cannot be zero address"
    );

    require(
      address(vault_) != address(0),
      "PSMV1Storage: vault_ cannot be zero address"
    );

    _initializeElement(db_);

    cash = IPegToken(db_.getAddress("CASH"));
    vault = vault_;
    underlying = vault_.asset();
    bondAddress = db_.getAddress("BOND");
    buyFee = buyFee_;
    sellFee = sellFee_;

    creditAccount = ICreditAccount(db_.getAddress("CREDIT_ACCOUNT")).getAccount(
      address(this)
    );

    _underlyingDecimals = ERC20(address(underlying)).decimals();

    _grantRoleKey(DEFAULT_ADMIN_ROLE, keccak256("MANAGER"));
    _grantRoleKey(MANAGER_ROLE, keccak256("MANAGER"));

    emit BuyFeeSet(buyFee_);
    emit SellFeeSet(sellFee_);
  }
}
