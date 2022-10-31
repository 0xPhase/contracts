// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IOracle} from "../../oracle/IOracle.sol";
import {MathLib} from "../../lib/MathLib.sol";
import {PSMV1Storage} from "../IPSM.sol";

contract PSMV1 is PSMV1Storage {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  function buyCash(uint256 amount, address asset)
    external
    override
    returns (uint256)
  {
    uint256 price = assetPrice(asset);
    uint256 decimals = ERC20(asset).decimals();
    uint256 fee = assetInfo[asset].buyFee;

    uint256 rawTokens = MathLib.scaleAmount(
      (amount * (fee + 1 ether) * 1 ether) / (price * 1 ether),
      uint8(18),
      uint8(decimals)
    );

    IERC20(asset).safeTransferFrom(msg.sender, address(this), rawTokens);
    cash.mintManager(msg.sender, amount);

    emit CashBought(msg.sender, asset, amount, rawTokens, fee);

    return rawTokens;
  }

  function sellCash(uint256 amount, address asset)
    external
    override
    returns (uint256)
  {
    uint256 price = assetPrice(asset);
    uint256 decimals = ERC20(asset).decimals();
    uint256 fee = assetInfo[asset].sellFee;

    uint256 rawTokens = MathLib.scaleAmount(
      (amount * 1 ether * 1 ether) / (price * (fee + 1 ether) * 1 ether),
      uint8(18),
      uint8(decimals)
    );

    cash.burnManager(msg.sender, amount);
    IERC20(asset).safeTransferFrom(msg.sender, address(this), rawTokens);

    emit CashSold(msg.sender, asset, amount, rawTokens, fee);

    return rawTokens;
  }

  function setAsset(
    address asset,
    uint256 buyFee,
    uint256 sellFee,
    IOracle oracle
  ) external onlyOwner {
    require(buyFee >= 0 && buyFee <= 1 ether, "PSMV1: Buy fee out of bounds");

    require(
      sellFee >= 0 && sellFee <= 1 ether,
      "PSMV1: Sell fee out of bounds"
    );

    assetInfo[asset] = AssetInfo(true, buyFee, sellFee, oracle);

    emit AssetSet(asset, buyFee, sellFee, oracle);
  }

  function removeAsset(address asset) external onlyOwner {
    delete assetInfo[asset];

    emit AssetRemoved(asset);
  }

  function assetList() external view override returns (address[] memory list) {
    uint256 length = _assetList.length();
    list = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      list[i] = _assetList.at(i);
    }
  }

  function assetPrice(address asset) public view override returns (uint256) {
    require(assetInfo[asset].enabled, "PSMV1: Asset not enabled");
    return assetInfo[asset].oracle.getPrice(asset);
  }
}
