# Phase Cash

## Audits

### Omniscia - Core - 2023

- Link: (to be released)
- Updates after audit:
  - Balancer deposits to the first yield if `totalNegative` is 0, indicating no funds deposited or all yields are balanced already.
  - Fixed `expect()` messages in `BalancerAccountingFacet` containing the wrong contract name as the thrower.
