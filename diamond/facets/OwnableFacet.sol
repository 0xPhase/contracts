// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct OwnableStorage {
  address owner;
}

interface IOwnable {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function renounceOwnership() external;

  function transferOwnership(address newOwner) external;

  function owner() external view returns (address);
}

contract OwnableFacet is IOwnable {
  bytes32 public constant OWNABLE_STORAGE_SLOT =
    bytes32(uint256(keccak256("ownable.storage")) - 1);

  function transferOwnership(address newOwner) public virtual {
    checkOwner();

    require(newOwner != address(0), "Ownable: new owner is the zero address");

    _transferOwnership(newOwner);
  }

  function renounceOwnership() public virtual {
    checkOwner();
    _transferOwnership(address(0));
  }

  function owner() public view virtual returns (address) {
    return _storage().owner;
  }

  function checkOwner() public view virtual {
    require(owner() == msg.sender, "OwnableFacet: Caller is not the owner");
  }

  function _transferOwnership(address newOwner) internal virtual {
    OwnableStorage storage s = _storage();
    address oldOwner = s.owner;

    s.owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _storage() internal pure returns (OwnableStorage storage s) {
    bytes32 slot = OWNABLE_STORAGE_SLOT;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      s.slot := slot
    }
  }
}
