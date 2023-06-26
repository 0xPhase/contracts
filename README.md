# Phase Cash

## Audits

### Omniscia - Core - 2023

- Link: (to be released)
- Updates after audit:
  - Balancer deposits to the first yield if `totalNegative` is 0, indicating no funds deposited or all yields are balanced already.
  - Fixed `expect()` messages in `BalancerAccountingFacet` containing the wrong contract name as the thrower.
  - Added a `Default` state for yields which indicates that they are neither positive nor negative but still active.
  - Changed `total` to `yield.lastDeposit` to fix issues with Vaults that might be accruing yield from booster points etc
