// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {SignatureChecker} from "@matterlabs/signature-checker/contracts/SignatureChecker.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// solhint-disable-next-line contract-name-camelcase
contract zkWETH is ERC20, ERC20Burnable, EIP712 {
  using Counters for Counters.Counter;

  mapping(address => Counters.Counter) private _nonces;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private constant _PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  event Deposit(address indexed src, address indexed to, uint256 wad);

  event Withdrawal(address indexed src, address indexed to, uint256 wad);

  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20("Wrapped ETH", "WETH") EIP712("Wrapped ETH", "1") {}

  function deposit() external payable {
    _mint(msg.sender, msg.value);
    emit Deposit(msg.sender, msg.sender, msg.value);
  }

  function depositTo(address to) external payable {
    _mint(to, msg.value);
    emit Deposit(msg.sender, to, msg.value);
  }

  function withdraw(uint256 amount) public {
    _burn(msg.sender, amount);

    emit Withdrawal(msg.sender, msg.sender, amount);

    Address.functionCallWithValue(msg.sender, "", amount);
  }

  function withdrawTo(uint256 amount, address to) public {
    _burn(msg.sender, amount);

    emit Withdrawal(msg.sender, to, amount);

    Address.functionCallWithValue(to, "", amount);
  }

  function withdrawFrom(uint256 amount, address from) public {
    _spendAllowance(from, msg.sender, amount);

    _burn(from, amount);

    emit Withdrawal(from, msg.sender, amount);

    Address.functionCallWithValue(msg.sender, "", amount);
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    bytes memory sig
  ) public virtual {
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

    bytes32 structHash = keccak256(
      abi.encode(
        _PERMIT_TYPEHASH,
        owner,
        spender,
        value,
        _useNonce(owner),
        deadline
      )
    );

    bytes32 hash = _hashTypedDataV4(structHash);

    bool success = SignatureChecker.isValidSignatureNow(owner, hash, sig);

    require(success, "zkWETH: invalid signature");

    _approve(owner, spender, value);
  }

  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner].current();
  }

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    return _domainSeparatorV4();
  }

  function _useNonce(address owner) internal virtual returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }
}
