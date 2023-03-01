// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ElementBase} from "./ElementBase.sol";
import {IElement} from "./IElement.sol";
import {IDB} from "../../db/IDB.sol";

contract ElementFacet is ElementBase, IElement {
  /// @inheritdoc IElement
  function db() external view returns (IDB) {
    return _db();
  }
}
