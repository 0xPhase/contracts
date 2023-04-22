// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVault, LiquidationInfo} from "../vault/IVault.sol";
import {ILiquidator} from "../vault/ILiquidator.sol";
import {User} from "../misc/User.sol";

contract SimpleLiquidator is Ownable, User, ILiquidator {
  address internal _vault;

  function liquidateUser(uint256 user, address vault) external onlyOwner {
    _vault = vault;
    IVault(vault).liquidateUser(user);
  }

  function receiveLiquidation(
    uint256,
    LiquidationInfo calldata
  ) external view override returns (bytes4) {
    require(msg.sender == _vault, "SimpleLiquidator: Not correct vault");
    return ILiquidator.receiveLiquidation.selector;
  }
}
