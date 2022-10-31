// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ProxyOwnable} from "../proxy/utils/ProxyOwnable.sol";
import {IOracle} from "../oracle/IOracle.sol";
import {Manager} from "../core/Manager.sol";
import {ICash} from "../core/ICash.sol";

interface IPSM {
  struct AssetInfo {
    bool enabled;
    uint256 buyFee;
    uint256 sellFee;
    IOracle oracle;
  }

  event CashBought(
    address indexed buyer,
    address asset,
    uint256 amount,
    uint256 rawTokens,
    uint256 indexed fee
  );

  event CashSold(
    address indexed seller,
    address asset,
    uint256 amount,
    uint256 rawTokens,
    uint256 indexed fee
  );

  event AssetSet(
    address indexed asset,
    uint256 buyFee,
    uint256 sellFee,
    IOracle indexed oracle
  );

  event AssetRemoved(address indexed asset);

  function buyCash(uint256 amount, address asset) external returns (uint256);

  function sellCash(uint256 amount, address asset) external returns (uint256);

  function assetInfo(address asset)
    external
    view
    returns (
      bool enabled,
      uint256 buyFee,
      uint256 sellFee,
      IOracle oracle
    );

  function assetList() external view returns (address[] memory);

  function assetPrice(address asset) external view returns (uint256);
}

abstract contract PSMV1Storage is ProxyOwnable, IPSM {
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => AssetInfo) public assetInfo;
  Manager public manager;
  ICash public cash;

  EnumerableSet.AddressSet internal _assetList;

  function initializePSMV1(Manager manager_) external initialize("v1") {
    manager = manager_;

    cash = ICash(manager_.getContract("CASH"));
  }
}
