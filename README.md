# Phase Cash

## Audits

### Omniscia - Core - 2023

Links:

- Core: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/
- Balancer: https://omniscia.io/reports/0xphase-balancer-implementation-645cb15ec7eedb00140139f7/

Updates after audit:

- Balancer deposits to the first yield if `totalNegative` is 0, indicating no funds deposited or all yields are balanced already.
- Fixed `expect()` messages in `BalancerAccountingFacet` containing the wrong contract name as the thrower.
- Added a `Default` state for yields which indicates that they are neither positive nor negative but still active.
- Changed `total` to `yield.lastDeposit` to fix issues with Vaults that might be accruing yield from booster points etc.
- Fixed `twaa()` to give default APR on yield sources where `start` or `lastDeposit` is 0.
- Changed so that withdrawing 0 shares from Balancer just returns 0 instead of reverting
