// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {UserInfo, IVaultYield} from "../IVault.sol";
import {IYield} from "../../yield/IYield.sol";
import {VaultBase} from "./VaultBase.sol";

contract VaultYieldFacet is VaultBase, IVaultYield {
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  /// @notice Checks if yield source exists and possibly if it's enabled
  /// @param yieldSource The yield source
  /// @param allowDisabled If allows disabled sources
  modifier yieldCheck(address yieldSource, bool allowDisabled) {
    if (allowDisabled) {
      require(
        _s.yieldSources.contains(yieldSource),
        "VaultYieldFacet: Yield source does not exist"
      );
    } else {
      require(
        _s.yieldInfo[yieldSource].enabled,
        "VaultYieldFacet: Yield source not enabled"
      );
    }

    _;
  }

  /// @inheritdoc	IVaultYield
  function depositYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  )
    external
    override
    yieldCheck(yieldSource, false)
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    UserInfo storage info = _s.userInfo[user];

    require(info.deposit >= amount, "VaultYieldFacet: Not enough deposit");

    info.deposit -= amount;

    _s.asset.safeApprove(yieldSource, amount);
    IYield(yieldSource).receiveDeposit(user, amount);

    require(
      _isSolvent(user),
      "VaultYieldFacet: User not solvent after yield deposit"
    );

    _s.userYield[user].yieldSources.add(yieldSource);
  }

  /// @inheritdoc	IVaultYield
  function withdrawYield(
    uint256 user,
    address yieldSource,
    uint256 amount
  )
    external
    override
    yieldCheck(yieldSource, true)
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    IYield source = IYield(yieldSource);

    require(
      source.balance(user) >= amount,
      "VaultYieldFacet: Withdrawing too much from yield source"
    );

    uint256 result = source.receiveWithdraw(user, amount);

    _s.userInfo[user].deposit += result;

    if (source.balance(user) == 0) {
      _s.userYield[user].yieldSources.remove(yieldSource);
    }
  }

  /// @inheritdoc	IVaultYield
  function withdrawFullYield(
    uint256 user,
    address yieldSource
  )
    external
    override
    yieldCheck(yieldSource, true)
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    IYield source = IYield(yieldSource);

    require(
      _s.userYield[user].yieldSources.remove(yieldSource),
      "VaultYieldFacet: User not invested in yield source"
    );

    uint256 result = source.receiveFullWithdraw(user);

    _s.userInfo[user].deposit += result;
  }

  /// @inheritdoc	IVaultYield
  function withdrawEverythingYield(
    uint256 user
  )
    external
    override
    ownerCheck(user, msg.sender)
    updateUser(user)
    freezeCheck
    updateDebt
  {
    _withdrawEverythingYield(user);
  }
}
