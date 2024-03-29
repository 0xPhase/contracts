// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {SignatureChecker} from "@matterlabs/signature-checker/contracts/SignatureChecker.sol";

import {IVotesUpgradeable} from "../../governance/IVotesUpgradeable.sol";
import {ERC20PermitUpgradeable} from "./ERC20PermitUpgradeable.sol";

abstract contract ERC20VotesUpgradeable is
  Initializable,
  IVotesUpgradeable,
  ERC20PermitUpgradeable
{
  struct Checkpoint {
    uint32 fromBlock;
    uint224 votes;
  }

  bytes32 private constant _DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  mapping(address => address) private _delegates;
  mapping(address => Checkpoint[]) private _checkpoints;
  Checkpoint[] private _totalSupplyCheckpoints;

  /**
   * @dev Delegate votes from the sender to `delegatee`.
   */
  function delegate(address delegatee) public virtual override {
    _delegate(_msgSender(), delegatee);
  }

  /**
   * @dev Delegates votes from signer to `delegatee`
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    require(
      block.timestamp <= expiry,
      "ERC20VotesUpgradeable: signature expired"
    );

    address signer = ECDSAUpgradeable.recover(
      _hashTypedDataV4(
        keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))
      ),
      v,
      r,
      s
    );

    require(nonce == _useNonce(signer), "ERC20VotesUpgradeable: invalid nonce");

    _delegate(signer, delegatee);
  }

  /**
   * @dev Delegates votes from signer to `delegatee`
   */
  function delegateBySig2(
    address delegator,
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    bytes calldata sig
  ) public virtual override {
    require(
      _systemClock.time() <= expiry,
      "ERC20VotesUpgradeable: signature expired"
    );

    bytes32 hash = _hashTypedDataV4(
      keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))
    );

    require(
      SignatureChecker.isValidSignatureNow(delegator, hash, sig),
      "ERC20VotesUpgradeable: invalid signature"
    );

    require(
      nonce == _useNonce(delegator),
      "ERC20VotesUpgradeable: invalid nonce"
    );

    _delegate(delegator, delegatee);
  }

  /**
   * @dev Get the `pos`-th checkpoint for `account`.
   */
  function checkpoints(
    address account,
    uint32 pos
  ) public view virtual returns (Checkpoint memory) {
    return _checkpoints[account][pos];
  }

  /**
   * @dev Get number of checkpoints for `account`.
   */
  function numCheckpoints(
    address account
  ) public view virtual returns (uint32) {
    return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
  }

  /**
   * @dev Get the address `account` is currently delegating to.
   */
  function delegates(
    address account
  ) public view virtual override returns (address) {
    return _delegates[account];
  }

  /**
   * @dev Gets the current votes balance for `account`
   */
  function getVotes(
    address account
  ) public view virtual override returns (uint256) {
    unchecked {
      uint256 pos = _checkpoints[account].length;
      return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }
  }

  /**
   * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastVotes(
    address account,
    uint256 blockNumber
  ) public view virtual override returns (uint256) {
    require(
      blockNumber < block.number,
      "ERC20VotesUpgradeable: block not yet mined"
    );
    return _checkpointsLookup(_checkpoints[account], blockNumber);
  }

  /**
   * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
   * It is NOT the sum of all the delegated votes!
   *
   * Requirements:
   *
   * - `blockNumber` must have been already mined
   */
  function getPastTotalSupply(
    uint256 blockNumber
  ) public view virtual override returns (uint256) {
    require(
      blockNumber < block.number,
      "ERC20VotesUpgradeable: block not yet mined"
    );
    return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
  }

  // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
  function __ERC20Votes_init() internal onlyInitializing {}

  // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
  function __ERC20Votes_init_unchained() internal onlyInitializing {}

  /**
   * @dev Snapshots the totalSupply after it has been increased.
   */
  function _mint(address account, uint256 amount) internal virtual override {
    super._mint(account, amount);

    require(
      totalSupply() <= _maxSupply(),
      "ERC20VotesUpgradeable: total supply risks overflowing votes"
    );

    _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
  }

  /**
   * @dev Snapshots the totalSupply after it has been decreased.
   */
  function _burn(address account, uint256 amount) internal virtual override {
    super._burn(account, amount);

    _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
  }

  /**
   * @dev Move voting power when tokens are transferred.
   *
   * Emits a {IVotes-DelegateVotesChanged} event.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._afterTokenTransfer(from, to, amount);

    _moveVotingPower(delegates(from), delegates(to), amount);
  }

  /**
   * @dev Change delegation for `delegator` to `delegatee`.
   *
   * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
   */
  function _delegate(address delegator, address delegatee) internal virtual {
    address currentDelegate = delegates(delegator);
    uint256 delegatorBalance = balanceOf(delegator);
    _delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
  }

  /**
   * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
   */
  function _maxSupply() internal view virtual returns (uint224) {
    return type(uint224).max;
  }

  function _moveVotingPower(address src, address dst, uint256 amount) private {
    if (src != dst && amount > 0) {
      if (src != address(0)) {
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
          _checkpoints[src],
          _subtract,
          amount
        );
        emit DelegateVotesChanged(src, oldWeight, newWeight);
      }

      if (dst != address(0)) {
        (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
          _checkpoints[dst],
          _add,
          amount
        );
        emit DelegateVotesChanged(dst, oldWeight, newWeight);
      }
    }
  }

  function _writeCheckpoint(
    Checkpoint[] storage ckpts,
    function(uint256, uint256) view returns (uint256) op,
    uint256 delta
  ) private returns (uint256 oldWeight, uint256 newWeight) {
    uint256 pos = ckpts.length;

    unchecked {
      oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
    }

    newWeight = op(oldWeight, delta);

    unchecked {
      if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
        ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        return (oldWeight, newWeight);
      }
    }

    ckpts.push(
      Checkpoint({
        fromBlock: SafeCastUpgradeable.toUint32(block.number),
        votes: SafeCastUpgradeable.toUint224(newWeight)
      })
    );
  }

  /**
   * @dev Lookup a value in a list of (sorted) checkpoints.
   */
  function _checkpointsLookup(
    Checkpoint[] storage ckpts,
    uint256 blockNumber
  ) private view returns (uint256) {
    // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
    //
    // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
    // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
    // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
    // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
    // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
    // out of bounds (in which case we're looking too far in the past and the result is 0).
    // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
    // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
    // the same.
    uint256 high = ckpts.length;
    uint256 low = 0;

    while (low < high) {
      uint256 mid = MathUpgradeable.average(low, high);
      if (ckpts[mid].fromBlock > blockNumber) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    unchecked {
      return high == 0 ? 0 : ckpts[high - 1].votes;
    }
  }

  function _add(uint256 a, uint256 b) private pure returns (uint256) {
    return a + b;
  }

  function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
    return a - b;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  // solhint-disable-next-line ordering
  uint256[47] private __gap;
}
