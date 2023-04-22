# Static Analysis

## Minor

### AUP-02S: Inexistent Sanitization of Input Addresses

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/AdminUpgradeableProxy-AUP#AUP-02S
- [x] Fixed

### COE-01S: Inexistent Sanitization of Input Addresses

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/CashOracle-COE#COE-01S
- [x] Fixed

### CDD-01S: Inexistent Sanitization of Input Addresses

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/CloneDiamond-CDD#CDD-01S
- [x] Fixed

### ETN-01S: Inexistent Sanitization of Input Address

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/Element-ETN#ETN-01S
- [x] Fixed

### EBE-01S: Inexistent Sanitization of Input Address

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/ElementBase-EBE#EBE-01S
- [x] Fixed

### ICA-01S: Inexistent Sanitization of Input Address

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/ICreditAccount-ICA#ICA-01S
- [x] Fixed

### SUP-02S: Inexistent Sanitization of Input Addresses

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/StorageUpgradeableProxy-SUP#SUP-02S
- [x] Fixed

### VIR-01S: Inexistent Sanitization of Input Addresses

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/VaultInitializer-VIR#VIR-01S
- Notes: Also fixed the issue for the `initializeVaultOwner()` function. Didn't do a sanitation check for `adapter_` as it can be a 0 address indicating no adapter.
- [x] Fixed

## Informational

### AUP-01S: Data Location Optimizations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/AdminUpgradeableProxy-AUP#AUP-01S
- [x] Fixed

### DBV-01S: Data Location Optimizations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/DBV1-DBV#DBV-01S
- [x] Fixed

### SUP-01S: Data Location Optimizations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/static-analysis/StorageUpgradeableProxy-SUP#SUP-01S
- [x] Fixed

# Manual Review

## Major

### AUP-01M: Incorrect Implementation of Initialization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/AdminUpgradeableProxy-AUP#span-idaup-01maup-01m-incorrect-implementation-of-initializationspan
- [x] Fixed

### COE-01M: Insecure Calculation of Share Amount

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/CashOracle-COE#span-idcoe-01mcoe-01m-insecure-calculation-of-share-amountspan
- [x] Fixed

### CAV-01M: Abnormal Credit Account Behaviour

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/CreditAccountV1-CAV#CAV-01M
- Notes: Fixed by implementing a transfer system where the user has to first initiate a transfer to another user which after the target user has to accept it with a transaction. A maximum transfer time is also implemented to automatically invalidate old transfers. A good UI/UX will be implemented for this to also ensure that users don't accidentally accept fraudulent transfers.
- [x] Fixed

### DBV-04M: Incorrect Arithmetic Operator Methodology

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#DBV-04M
- [x] Fixed

### DBV-05M: Incorrect Logical Operator Methodology

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#span-iddbv-05mdbv-05m-incorrect-logical-operator-methodologyspan
- [x] Fixed

### DBV-06M: Incorrect Removal of Value

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#DBV-06M
- [x] Fixed

### SPY-01M: Incorrect Implementation of Initialization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/SimpleProxy-SPY#SPY-01M
- [x] Fixed

### SUP-01M: Incorrect Implementation of Initialization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/StorageUpgradeableProxy-SUP#SUP-01M
- [x] Fixed

### TV1-03M: Incorrect Setting Mechanism

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/TreasuryV1-TV1#TV1-03M
- Notes: Fixed via adding AddressSet to be able to safely add and remove
- [x] Fixed

### VBE-03M: Incorrect Definition of Diamond Storage

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultBase-VBE#VBE-03M
- [x] Fixed

### VLF-04M: Incorrect Rebate Calculation Mechanism

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultLiquidationFacet-VLF#VLF-04M
- [x] Fixed

## Medium

### COV-01M: Improper Integration of Chainlink Oracles

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/ChainlinkOracleV1-COV#COV-01M
- Notes: Fixed by implementing a `heartbeat` in which the Oracle feed must have been updated or the getter reverts.
- [x] Fixed

### DBV-03M: Discrepant Behaviour of NAND Operator

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#DBV-03M
- [x] Fixed

### ERP-01M: Significant Deviation of Standard

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/ERC20PermitUpgradeable-ERP#ERP-01M
- Notes: Fixed by renaming `permit` to `permit2` and implementing the standard `permit`
- [x] Fixed

### ERV-01M: Significant Deviation of Standard

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/ERC20VotesUpgradeable-ERV#ERV-01M
- Notes: Fixed by renaming `delegateBySig` to `delegateBySig2` and implementing the standard `delegateBySig`
- [x] Fixed

### TV1-02M: Incorrect Order of Execution

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/TreasuryV1-TV1#TV1-02M
- Notes: Even if only the `MANAGER_ROLE` can call, still a good precaution
- [x] Fixed

### VBE-02M: Dangerous Order of Mathematical Operations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultBase-VBE#VBE-02M
- [x] Fixed

### VLF-02M: Accuracy-Loss Prone Convoluted Mathematical Operations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultLiquidationFacet-VLF#VLF-02M
- Notes: The previous implementation worked correctly but indeed contained numbers that got close to the `type(uin256).max`. The formula to calculate the borrow change was restructured using a CAS calculator and hand math to contain smaller numbers and provide better accuracy. The new formala allows for another `18` zeros at the end of debt/collateral values. The formula takes into account the fee and max collateral ratio due to the fact that this borrow change in combination with a fee included collateral value change would put the user at exactly the health ratio they set.
- [x] Fixed

### VLF-03M: Loss of Arithmetic Accuracy

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultLiquidationFacet-VLF#VLF-03M
- Notes: Fixed with rework of the liquidation math
- [x] Fixed

## Minor

### CLB-01M: Weak Validation of Call Result

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/CallLib-CLB#CLB-01M
- Notes: Will fix once fix is found (currently a TODO in `CallLib::isContract`)
- [ ] Fixed

### DBV-01M: Incorrect Addition of Value

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#DBV-01M
- Notes: Fixed by requiring 1 or more keys
- [x] Fixed

### DBV-02M: Unsafe Type Casting

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DBV1-DBV#DBV-02M
- Notes: Fixed by checking if last 12 bytes of `bytes32` are all 0
- [x] Fixed

### DLI-01M: Inexistent Requirement of Code

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/DiamondLib-DLI#DLI-01M
- Notes: Fixed by using the CallLib implementation of `isContract`
- [x] Fixed

### ICA-01M: Improper Disable of Initializers

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/ICreditAccount-ICA#ICA-01M
- [x] Fixed

### IPT-01M: Improper Disable of Initializers

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/IPegToken-IPT#IPT-01M
- [x] Fixed

### MRE-01M: Unsafe Length Cast

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/Manager-MRE#MRE-01M
- [x] Fixed

### TV1-01M: Inexistent Prevention of Accidental Transfers

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/TreasuryV1-TV1#TV1-01M
- [x] Fixed

### VAF-03M: Improper Emergency Mode Checks

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultAccountingFacet-VAF#VAF-03M
- Notes: Thought problem on my part, only minting should be disallowed in emergency mode
- [x] Fixed

### VSF-01M: Inexistent Sanitization of Variables

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultSettersFacet-VSF#VSF-01M
- [x] Fixed

## Informational

### SLB-01M: Improper Checked Arithmetic

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/SlotLib-SLB#SLB-01M
- [x] Fixed

### VAF-01M: Improper Relay of Message Value

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultAccountingFacet-VAF#VAF-01M
- [x] Fixed

### VAF-02M: Non-Standard Application of Fee

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultAccountingFacet-VAF#VAF-02M
- [x] Fixed

## Unknown

### ACB-01M: Inexistent Initialization of Access Control

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/AccessControlBase-ACB#ACB-01M
- [x] Fixed

### FOE-01M: Improper Implementation of Oracle

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/FixedOracle-FOE#FOE-01M
- [x] Fixed

### Inexistent Initialization of Ownership

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/OwnableBase-OBE#OBE-01M
- [x] Fixed

### PTV-01M: Inexistent Validation of Allowances

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/PegTokenV1-PTV#PTV-01M
- Notes: Only system modules (and the timelock) are able to access these `MANAGER_ROLE` protected functions. More might be added in the future and this the DB keys are managed by the timelock. These are used to provide a smoother UX (protocol modules don't need permits to burn/transfer funds), but are indeed dangerous.
- [x] Aknowledged

### VBE-01M: Unknown Integration Points

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultBase-VBE#VBE-01M
- Notes: To be fixed and replaced in the extra audit
- [x] Aknowledged

### VIR-01M: Improper Initializer Definition

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultInitializer-VIR#VIR-01M
- Notes: To save on gas costs and to simplify vaults, there is a single target Diamond on which the `initializeVaultOwner()` is invoked on. Every Vault then copies this Diamond with the `CloneDiamond` and is initialized with the `initializeVaultV1()` function. This ensures that all the Vaults get updated at the same time, with the downside being that every Vault has to initialized with the new version in the same transaction as well. Due to the manager of the protocol only being able to do batch calls, this is not hard, but still a side-effect to keep in mind. Though, if you deem it better to have every Vault as their own Diamond, that is possible as well.
- [x] Aknowledged

### VLF-01M: Unknown Integration Point

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/manual-review/VaultLiquidationFacet-VLF#VLF-01M
- Notes: To be fixed and replaced in the extra audit
- [x] Aknowledged

# Code Style

## Informational

### ACL-01C: Inefficient mapping Lookups

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControl-ACL#ACL-01C
- [x] Fixed

### ACL-02C: Loop Iterator Optimization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControl-ACL#ACL-02C
- [x] Fixed

### ACL-03C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControl-ACL#ACL-03C
- [x] Fixed

### ACL-04C: Redundant Repetitive Invocations of Getter Function

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControl-ACL#ACL-04C
- [x] Fixed

### ACB-01C: Inefficient mapping Lookups

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControlBase-ACB#ACB-01C
- [x] Fixed

### ACB-02C: Loop Iterator Optimization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControlBase-ACB#ACB-02C
- [x] Fixed

### ACB-03C: Redundant Repetitive Invocations of Getter Function

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/AccessControlBase-ACB#ACB-03C
- [x] Fixed

### COE-01C: Variable Mutability Specifiers (Immutable)

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/CashOracle-COE#COE-01C
- [x] Fixed

### DBV-01C: Inefficient Assignments of State

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DBV1-DBV#DBV-01C
- [x] Fixed

### DBV-02C: Inefficient Iteration of Expected Results

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DBV1-DBV#DBV-02C
- [x] Fixed

### DBV-03C: Loop Iterator Optimizations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DBV1-DBV#DBV-03C
- [x] Fixed

### DBV-04C: Redundant Instantiations of Arrays

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DBV1-DBV#DBV-04C
- [x] Fixed

### DLI-01C: Inefficient mapping Lookups

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DiamondLib-DLI#DLI-01C
- [x] Fixed

### DLF-01C: Loop Iterator Optimization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/DiamondLoupeFacet-DLF#DLF-01C
- [x] Fixed

### ERP-01C: Redundant In-Memory Variable

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ERC20PermitUpgradeable-ERP#ERP-01C
- [x] Fixed

### ERV-01C: Ineffectual Usage of Safe Arithmetics

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ERC20VotesUpgradeable-ERV#ERV-01C
- [x] Fixed

### ERV-02C: Redundant In-Memory Variable

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ERC20VotesUpgradeable-ERV#ERV-02C
- [x] Fixed

### ETN-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/Element-ETN#ETN-01C
- [x] Fixed

### FRI-01C: Redundant Duplicate Getter Definition

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/FixedRateInterest-FRI#FRI-01C
- [x] Fixed

### ICO-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/IChainlinkOracle-ICO#ICO-01C
- [x] Fixed

### ICA-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ICreditAccount-ICA#ICA-01C
- [x] Fixed

### IDB-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/IDB-IDB#IDB-01C
- [x] Fixed

### IPT-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/IPegToken-IPT#IPT-01C
- [x] Fixed

### ISC-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ISystemClock-ISC#ISC-01C
- [x] Fixed

### ITY-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/ITreasury-ITY#ITY-01C
- [x] Fixed

### IVT-01C: Multiple Top-Level Declarations

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/IVault-IVT#IVT-01C
- [ ] Fixed

### MRE-01C: Repetitive Value Literals

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/Manager-MRE#MRE-01C
- [x] Fixed

### MOE-01C: Loop Iterator Optimization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/MasterOracle-MOE#MOE-01C
- [x] Fixed

### MLB-01C: Ineffectual Usage of Safe Arithmetics

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/MathLib-MLB#MLB-01C
- [x] Fixed

### MFT-01C: Loop Iterator Optimization

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/MulticallFacet-MFT#MFT-01C
- [x] Fixed

### MFT-02C: Potentially Dangerous Multicall Paradigm

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/MulticallFacet-MFT#MFT-02C
- [x] Fixed

### SCV-01C: Inefficient Variable Usage

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/SystemClockV1-SCV#SCV-01C
- [x] Fixed

### SCV-02C: Potentially Redundant Evaluation of Time

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/SystemClockV1-SCV#SCV-02C
- Notes: To my knowledge the sequencer or the L1 node can lie about the current time to a maximum of 15 minutes. To ensure that time doesn't go backwards, we only set it when the current time is higher, as the counterparty can first lie 10 minutes ahead and then at the current time. As a sidenote, this contract was created due to zkSync Era devs saying that in the future they will have a better way to get current time than `block.timestamp`.
- [x] Fixed

### TV1-01C: Redundant Duplicate Application of Access Control

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/TreasuryV1-TV1#TV1-01C
- [x] Fixed

### VAF-01C: Ineffectual Usage of Safe Arithmetics

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/VaultAccountingFacet-VAF#VAF-01C
- [x] Fixed

### VBE-01C: Ineffectual Usage of Safe Arithmetics

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/VaultBase-VBE#VBE-01C
- [x] Fixed

### VLF-01C: Suboptimal Struct Declaration Styles

- Link: https://omniscia.io/reports/0xphase-core-protocol-643d1d1f88c1770014f3a77b/code-style/VaultLiquidationFacet-VLF#VLF-01C
- [x] Fixed
