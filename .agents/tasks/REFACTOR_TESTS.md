# Test Refactoring Plan

Last updated: 2026-01-11 (All phases completed: P1-P18)

## Overview

This plan addresses test organization and code duplication across 88 composition tests. Current issues:
- **88 test directories** with significant duplication
- **Minimal code reuse** (only 4 tests use `_baseSpec`)
- **Related tests scattered** across separate directories
- **Naming inconsistencies** (4 tests have `test-test-` prefix)

**Expected impact**: Reduce test directories by ~40-50%, eliminate 70-80% code duplication, improve maintainability.

---

## High Priority

(All high priority items completed)

---

## Medium Priority

### P7: Consolidate route tests (11 total across 2 patterns)
**Phase 7a: Consolidate test-vpc-routes-\* (5 → 1)**
- `test-vpc-routes-database-nat`
- `test-vpc-routes-isolated`
- `test-vpc-routes-private-per-az`
- `test-vpc-routes-private-single-nat`
- `test-vpc-routes-public`

**Target:** `tests/test-vpc-routes/main.k`

**Phase 7b: Consolidate test-routes-\* (6 → 1)**
- `test-routes-database-igw`
- `test-routes-elasticache-nat`
- `test-routes-intra-per-az`
- `test-routes-public-per-az`
- `test-routes-redshift-nat`
- `test-routes-redshift-public`

**Target:** `tests/test-routes-subnet-specific/main.k`

**Approach:** Two bundles with parameterized variants.

**Impact:** Reduces 11 directories to 2 (~82% reduction).

**Rationale:** Routes are complex; keep main routes separate from subnet-specific routes.

---

### P8: Consolidate Flow Logs tests (3 → 1)
**Directories to merge:**
- `test-vpc-flowlogs-disabled`
- `test-vpc-flowlogs-cloudwatch`
- `test-vpc-flowlogs-s3`

**Target:** `tests/test-vpc-flowlogs/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 3 test variants.

**Impact:** Reduces 3 directories to 1 (~67% reduction).

**Rationale:** Test Flow Logs with different destinations. Clear consolidation opportunity.

---

### P9: Consolidate DHCP tests (2 → 1)
**Directories to merge:**
- `test-vpc-dhcp-disabled`
- `test-vpc-dhcp-custom`

**Target:** `tests/test-vpc-dhcp/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 2 test variants.

**Impact:** Reduces 2 directories to 1 (~50% reduction).

**Rationale:** Simple enabled/disabled pattern. Easy consolidation.

---

### P10: Consolidate gateway endpoint tests (3 → 1)
**Directories to merge:**
- `test-vpc-endpoints-disabled`
- `test-vpc-endpoints-dynamodb-gateway`
- `test-vpc-endpoints-s3-gateway`

**Target:** `tests/test-vpc-endpoints-gateway/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 3 test variants.

**Impact:** Reduces 3 directories to 1 (~67% reduction).

**Rationale:** Gateway endpoints with different service configurations.

---

### P11: Consolidate subnet group tests using parameterization (3 → 1)
**Directories to merge:**
- `test-subnetgroup-db`
- `test-subnetgroup-elasticache`
- `test-subnetgroup-redshift`

**Target:** `tests/test-subnetgroup/main.k`

**Approach:** Parameterized test matrix with service type variants.

**Impact:** Reduces 3 directories to 1 (~67% reduction).

**Rationale:** Identical pattern across three database services. Perfect for parameterization.

---

### P12: Consolidate IGW tests (2 → 1)
**Directories to merge:**
- `test-vpc-igw-disabled`
- `test-vpc-igw-enabled`

**Target:** `tests/test-vpc-igw/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 2 test variants.

**Impact:** Reduces 2 directories to 1 (~50% reduction).

**Rationale:** Simple enabled/disabled pattern.

---

### P13: Consolidate default resource tests (4 → 1)
**Directories to merge:**
- `test-vpc-default-nacl-managed`
- `test-vpc-default-rt-managed`
- `test-vpc-default-sg-disabled`
- `test-vpc-default-sg-managed`

**Target:** `tests/test-vpc-default-resources/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 4 test variants.

**Impact:** Reduces 4 directories to 1 (~75% reduction).

**Rationale:** All test default resource management. Related feature domain.

---

### P14: Consolidate remaining NACL tests (2 → 1 with P5)
**Directories to merge with P5 result:**
- `test-nacl-disabled`
- `test-nacl-public-dedicated`

**Target:** Merge into `tests/test-vpc-nacl-subnet-types/main.k` (from P5)

**Approach:** Add 2 additional variants to P5 bundle.

**Impact:** Further reduces by 2 directories.

**Rationale:** Complete NACL testing consolidation.

---

## Low Priority

### P15: Fix double-prefixed test names (4 tests)
**Directories to rename:**
- `test-test-customer-gateway-multiple` → `test-customer-gateway-multiple`
- `test-test-customer-gateway-single` → `test-customer-gateway-single`
- `test-test-vpc-ipam-ipv4` → `test-vpc-ipam-ipv4`
- `test-test-vpc-ipam-ipv6` → `test-vpc-ipam-ipv6`

**Approach:** Rename directories and update test metadata names.

**Impact:** Fixes naming consistency issue.

**Rationale:** Likely generated with incorrect prefix. Quick fix for consistency.

---

### P16: Consolidate Customer Gateway tests (2 → 1)
**Directories to merge (after P15):**
- `test-customer-gateway-single`
- `test-customer-gateway-multiple`

**Target:** `tests/test-customer-gateway/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 2 test variants.

**Impact:** Reduces 2 directories to 1 (~50% reduction).

**Rationale:** Both test Customer Gateway with different quantities.

---

### P17: Consolidate IPAM tests (2 → 1)
**Directories to merge (after P15):**
- `test-vpc-ipam-ipv4`
- `test-vpc-ipam-ipv6`

**Target:** `tests/test-vpc-ipam/main.k`

**Approach:** Resource-focused bundle with `_baseSpec` and 2 test variants.

**Impact:** Reduces 2 directories to 1 (~50% reduction).

**Rationale:** Both test IPAM with different IP versions.

---

### P18: Add shared test directory (new)
**Create:** `tests/shared/`

**Contents:**
- `shared/conditions.k` - Standard ready conditions for sequential tests
- `shared/builders.k` - Common resource builder functions
- `shared/base_specs.k` - Shared base specifications

**Approach:** Extract common patterns into importable modules.

**Impact:** Enables code reuse across test directories.

**Rationale:** DRY principle for cross-test utilities.

**NOTE:** KCL imports work within same directory; shared modules need careful evaluation for cross-directory usage.

---

## Execution Strategy

### Phase 1: High Priority (P1-P6)
- **Impact:** Reduces ~31 directories to 6 (~84% reduction)
- **Order:** P1 → P2 → P3 → P4 → P5 → P6
- **Duration:** One item per execution, verify tests after each

### Phase 2: Medium Priority (P7-P14)
- **Impact:** Reduces ~35 directories to 8 (~77% reduction)
- **Order:** P7 → P8 → P9 → P10 → P11 → P12 → P13 → P14
- **Duration:** One item per execution, verify tests after each

### Phase 3: Low Priority (P15-P18)
- **Impact:** Fixes naming, adds shared utilities
- **Order:** P15 → P16 → P17 → P18
- **Duration:** Quick fixes and infrastructure improvements

---

## Overall Impact Summary

**Before refactoring:**
- 88 test directories
- Minimal code reuse (4 tests use `_baseSpec`)
- Scattered related tests
- High duplication (~80% boilerplate)

**After refactoring (all phases):**
- ~22-25 test directories (~72% reduction)
- Consistent `_baseSpec` usage throughout
- Logical feature grouping
- Minimal duplication (~10-15% boilerplate)

**Maintenance benefits:**
- Add new variants in 2-3 minutes
- Update patterns once, apply everywhere
- Easy to find and modify related tests
- Guaranteed consistency across variants

---

## Completed

- [x] **P0: Initial analysis** - Identified refactoring opportunities (2026-01-11)
- [x] **P1: Consolidate NAT Gateway tests (6 → 1)** - Merged 6 test directories into `tests/test-vpc-nat/main.k` using `_baseSpec` pattern. Reduced code duplication by ~85%, consolidated all 6 NAT variants (disabled, single, per-az, per-subnet, custom-cidr, reuse-eips) into single maintainable file. All 6 tests pass. (2026-01-11)
- [x] **P2: Consolidate subnet tests (6 → 1)** - Merged 6 test directories into `tests/test-vpc-subnets/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 6 subnet types (database, elasticache, intra, private, public, redshift) into single maintainable file with shared specification. All 6 tests pass. (2026-01-11)
- [x] **P3: Consolidate IPv6 tests (6 → 1)** - Merged 6 test directories into `tests/test-vpc-ipv6/main.k` using `_baseSpec` pattern. Reduced code duplication by ~85%, consolidated all 6 IPv6 variants (disabled, dual-stack, egress-only, ipam, native, routing) into single maintainable file. Centralizes IPv6 testing with comprehensive coverage. All 6 tests pass. (2026-01-11)
- [x] **P4: Consolidate interface endpoint tests (5 → 1)** - Merged 5 test directories into `tests/test-vpc-interface-endpoints/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 5 interface endpoint variants (disabled, single, multiple, no-private-dns, minimal) into single maintainable file. Centralizes interface endpoint testing with comprehensive coverage. All 5 tests pass. (2026-01-11)
- [x] **P5: Consolidate NACL subnet type tests (4 → 1)** - Merged 4 test directories into `tests/test-vpc-nacl-subnet-types/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated all 4 NACL subnet variants (database, elasticache, intra, redshift) into single maintainable file. Centralizes dedicated Network ACL testing with comprehensive coverage. All 4 tests pass. (2026-01-11)
- [x] **P6: Consolidate VPN tests (4 → 1)** - Merged 4 test directories into `tests/test-vpc-vpn/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 4 VPN Gateway variants (disabled, enabled, custom-asn, selective-propagation) into single maintainable file. Centralizes VPN Gateway testing with comprehensive coverage. All 4 tests pass. (2026-01-11)
- [x] **P7a: Consolidate VPC route tests (5 → 1)** - Merged 5 test directories into `tests/test-vpc-routes/main.k` using `_baseSpec` pattern. Reduced code duplication by ~85%, consolidated all 5 main VPC routing patterns (public, private-single-nat, private-per-az, database-nat, isolated) into single maintainable file. All 5 tests pass. (2026-01-11)
- [x] **P7b: Consolidate subnet-specific route tests (6 → 1)** - Merged 6 test directories into `tests/test-routes-subnet-specific/main.k` using `_baseSpec` pattern. Reduced code duplication by ~85%, consolidated all 6 subnet-specific routing variants (database-igw, elasticache-nat, redshift-nat, redshift-public, intra-per-az, public-per-az) into single maintainable file. All 6 tests pass. Fixed NAT Gateway selectors to use AZ labels and corrected redshift-public resource naming. (2026-01-11)
- [x] **P8: Consolidate Flow Logs tests (3 → 1)** - Merged 3 test directories into `tests/test-vpc-flowlogs/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 3 Flow Logs variants (disabled, cloudwatch, s3) into single maintainable file. Validates Task 3.4 (VPC Flow Logs) with comprehensive coverage for both CloudWatch and S3 destinations. All 3 tests pass. (2026-01-11)
- [x] **P9: Consolidate DHCP tests (2 → 1)** - Merged 2 test directories into `tests/test-vpc-dhcp/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated both DHCP variants (disabled, custom) into single maintainable file. Validates DHCP Options support with custom domain name, DNS, NTP, and NetBIOS configuration. All 2 tests pass. (2026-01-11)
- [x] **P10: Consolidate gateway endpoint tests (3 → 1)** - Merged 3 test directories into `tests/test-vpc-endpoints-gateway/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 3 gateway endpoint variants (disabled, dynamodb-gateway, s3-gateway) into single maintainable file. Validates Task 3.1 (VPC Gateway Endpoints) with S3 and DynamoDB gateway endpoints. All 3 tests pass. (2026-01-11)
- [x] **P11: Consolidate subnet group tests (3 → 1)** - Merged 3 test directories into `tests/test-subnetgroup/main.k` using `_baseSpec` pattern. Reduced code duplication by ~80%, consolidated all 3 subnet group variants (db, elasticache, redshift) into single maintainable file. Validates Task 3.5 (Subnet Group resources) with RDS, ElastiCache, and Redshift subnet groups. All 3 tests pass. (2026-01-11)
- [x] **P12: Consolidate IGW tests (2 → 1)** - Merged 2 test directories into `tests/test-vpc-igw/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated both IGW variants (disabled, enabled) into single maintainable file. Validates Internet Gateway creation and VPC attachment with `createIgw` flag. All 2 tests pass. Fixed Name tag values to match actual resource metadata names. (2026-01-11)
- [x] **P13: Consolidate default resource tests (4 → 1)** - Merged 4 test directories into `tests/test-vpc-default-resources/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated all 4 default resource variants (nacl-managed, rt-managed, sg-disabled, sg-managed) into single maintainable file. Validates Task 4.8 (Default resource management) with comprehensive coverage for default Network ACL, Route Table, and Security Group management. All 4 tests pass on first try. (2026-01-11)
- [x] **P14: Consolidate remaining NACL tests (2 → P5 result)** - Added 2 additional test variants (disabled, public-dedicated) to existing `tests/test-vpc-nacl-subnet-types/main.k` from P5. Now includes 6 comprehensive NACL variants (disabled, public, database, elasticache, intra, redshift) in single maintainable file. Completes NACL testing consolidation with full coverage for all subnet types and disabled state. Reduced 2 additional directories, bringing total NACL consolidation to 6 original directories → 1 file. All 6 tests pass on first try. (2026-01-11)
- [x] **P15: Fix double-prefixed test names (4 tests)** - Renamed 4 test directories to remove incorrect double "test-test-" prefix: test-test-customer-gateway-multiple → test-customer-gateway-multiple, test-test-customer-gateway-single → test-customer-gateway-single, test-test-vpc-ipam-ipv4 → test-vpc-ipam-ipv4, test-test-vpc-ipam-ipv6 → test-vpc-ipam-ipv6. Test names inside files were already correct. All 4 tests pass after rename. Fixes naming consistency issue. (2026-01-11)
- [x] **P16: Consolidate Customer Gateway tests (2 → 1)** - Merged 2 test directories into `tests/test-customer-gateway/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated both Customer Gateway variants (single, multiple) into single maintainable file. Validates Task 4.2 (Customer Gateway support) with single gateway (standard BGP ASN) and multiple gateways (standard and extended BGP ASN, certificate ARN). All 2 tests pass on first try. (2026-01-11)
- [x] **P17: Consolidate IPAM tests (2 → 1)** - Merged 2 test directories into `tests/test-vpc-ipam/main.k` using `_baseSpec` pattern. Reduced code duplication by ~75%, consolidated both IPAM variants (ipv4, ipv6) into single maintainable file. Validates Task 3.7 (IPAM Integration), Task 10.2 (IPAM IPv4 Late-Binding), and Task 10.3 (IPAM IPv6 Late-Binding). Tests validate VPC creation with IPAM pool configuration for dynamic CIDR allocation, supporting both IPv4 and IPv6 address allocation with late-binding subnet creation pattern. All 2 tests pass on first try. (2026-01-11)
- [x] **P18: Add shared test directory** - Created comprehensive `tests/shared/` directory with reusable test utilities. Added `conditions.k` (ready conditions for sequential tests), `base_specs.k` (common base specifications), `builders.k` (resource builder functions), and comprehensive README.md with usage documentation. Directory already contained `helpers.k` with extensive resource builder functions for VPC, subnets, gateways, endpoints, security resources, DHCP options, VPN resources, flow logs, and IPv6 resources. Shared utilities serve as reference templates and enable code reuse across test directories. Cross-directory import limitations documented with recommended local usage patterns. Provides standard patterns for DRY principle, consistency, and maintainability across all tests. (2026-01-11)
