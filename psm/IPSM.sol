// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface IPSM {
  /// @notice Event emitted when the buy fee is set
  /// @param fee The buy fee
  event BuyFeeSet(uint256 fee);

  /// @notice Event emitted when the sell fee is set
  /// @param fee The sell fee
  event SellFeeSet(uint256 fee);

  /// @notice Event emitted when CASH is bought
  /// @param buyer The buyer address
  /// @param fee The amount of fee taken
  /// @param cashOut The amount of CASH bought
  /// @param otherIn The amount of other token sold
  event CashBought(
    address indexed buyer,
    uint256 indexed fee,
    uint256 cashOut,
    uint256 otherIn
  );

  /// @notice Event emitted when CASH is sold
  /// @param seller The seller address
  /// @param fee The amount of fee taken
  /// @param cashIn The amount of CASH sold
  /// @param otherOut The amount of other token bought
  event CashSold(
    address indexed seller,
    uint256 indexed fee,
    uint256 cashIn,
    uint256 otherOut
  );

  /// @notice Buys CASH in return for the other token
  /// @param amount Amount of other token to sell
  function buyCash(uint256 amount) external;

  /// @notice Sells CASH in return for the other token
  /// @param amount Amount of other token to buy
  function sellCash(uint256 amount) external;

  /// @notice Returns the total balance of the other token in the reserve
  /// @return The total balance of the other token
  function totalBalance() external view returns (uint256);

  /// @notice Returns the total amount traded in both directions
  /// @return The total amount traded
  function totalTraded() external view returns (uint256);

  /// @notice Returns the total amount of fees collected in both directions
  /// @return The total amount of fees collected
  function totalFees() external view returns (uint256);

  /// @notice Returns the Bond contract address
  /// @return The Bond contract address
  function bondAddress() external view returns (address);

  /// @notice Returns the buy fee
  /// @return The buy fee
  function buyFee() external view returns (uint256);

  /// @notice Returns the sell fee
  /// @return The sell fee
  function sellFee() external view returns (uint256);
}
