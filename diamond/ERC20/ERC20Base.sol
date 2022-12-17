// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC20Storage} from "./IERC20.sol";

abstract contract ERC20Base {
  bytes32 internal constant _ERC20_STORAGE_SLOT =
    bytes32(uint256(keccak256("access.control.storage")) - 1);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _initializeERC20(string memory name, string memory symbol) internal {
    ERC20Storage storage erc20s = _erc20s();

    erc20s.name = name;
    erc20s.symbol = symbol;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "BaseERC20: transfer from the zero address");
    require(to != address(0), "BaseERC20: transfer to the zero address");

    ERC20Storage storage erc20s = _erc20s();

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = erc20s.balances[from];

    require(
      fromBalance >= amount,
      "BaseERC20: transfer amount exceeds balance"
    );

    unchecked {
      erc20s.balances[from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      erc20s.balances[to] += amount;
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "BaseERC20: mint to the zero address");

    ERC20Storage storage erc20s = _erc20s();

    _beforeTokenTransfer(address(0), account, amount);

    erc20s.totalSupply += amount;

    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      erc20s.balances[account] += amount;
    }

    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "BaseERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    ERC20Storage storage erc20s = _erc20s();

    uint256 accountBalance = erc20s.balances[account];

    require(accountBalance >= amount, "BaseERC20: burn amount exceeds balance");

    unchecked {
      erc20s.balances[account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      erc20s.totalSupply -= amount;
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "BaseERC20: approve from the zero address");
    require(spender != address(0), "BaseERC20: approve to the zero address");

    _erc20s().allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = _allowance(owner, spender);

    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "BaseERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount // solhint-disable-next-line no-empty-blocks
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount // solhint-disable-next-line no-empty-blocks
  ) internal virtual {}

  function _name() internal view virtual returns (string memory) {
    return _erc20s().name;
  }

  function _symbol() internal view virtual returns (string memory) {
    return _erc20s().symbol;
  }

  function _decimals() internal view virtual returns (uint8) {
    return 18;
  }

  function _totalSupply() internal view virtual returns (uint256) {
    return _erc20s().totalSupply;
  }

  function _balanceOf(address account) internal view virtual returns (uint256) {
    return _erc20s().balances[account];
  }

  function _allowance(address owner, address spender)
    internal
    view
    virtual
    returns (uint256)
  {
    return _erc20s().allowances[owner][spender];
  }

  function _erc20s() internal pure returns (ERC20Storage storage s) {
    bytes32 slot = _ERC20_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
