# Handover Report: Test Framework Limitation - Container Isolation Blocking Shared Modules

**Date:** 2026-01-11 13:09
**Project:** configuration-aws-vpc
**Issue:** `up test run` framework limitation preventing shared test utilities

---

## Current Problem

**Cannot implement shared helper utilities for test refactoring due to `up test run` container isolation.**

The Crossplane `up test run` command executes tests in isolated containers that do not support external module dependencies outside the test directory. This blocks the planned P1 refactoring approach (shared helpers) that would have eliminated 80-90% of code duplication across 70+ composition tests.

---

## What We Tried (That Didn't Work)

### Attempt 1: Shared Helper Module with Path-Based Import

**What we created:**

```
tests/
├── shared/
│   ├── helpers.k          (22,372 bytes - comprehensive builder functions)
│   ├── kcl.mod
│   └── model -> ../../.up/kcl/models
├── test-vpc-simple/
│   ├── main.k
│   ├── kcl.mod            (added: helpers = { path = "../shared" })
│   └── model -> ../../.up/kcl/models
└── test-vpc-nat-single/
    ├── main.k
    ├── kcl.mod            (added: helpers = { path = "../shared" })
    └── model -> ../../.up/kcl/models
```

**Changes to test files:**

1. **tests/shared/kcl.mod:**
```toml
[package]
name = "test-shared"
version = "0.0.1"

[dependencies]
models = { path = "./model" }
```

2. **tests/test-vpc-simple/kcl.mod:**
```toml
[package]
name = "test-vpc-simple"
version = "0.0.1"

[dependencies]
models = { path = "./model" }
helpers = { path = "../shared" }    # Added this line
```

3. **tests/test-vpc-simple/main.k:**
```kcl
import helpers  # Added import

# Used helpers in test spec
spec: {
    **helpers.buildCompositionTestSpec("vpc")
    xr: { ... }
    assertResources: [
        helpers.buildVPC(...),
        helpers.buildSubnet(...),
        ...
    ]
}
```

**Commands executed:**

```bash
# Updated dependencies
cd tests/test-vpc-simple && kcl mod update
cd tests/test-vpc-nat-single && kcl mod update

# Attempted to run tests
cd /Users/tobiaskasser/up/configuration-aws-vpc
up test run tests/test-vpc-simple tests/test-vpc-nat-single
```

**Exact error output:**

```
up: error: failed to generate test files: failed to run test in "/test-vpc-simple":
failed to execute KCL manifest generation: container exited with non-zero status: 1, logs:

error[E2F04]: CannotFindModule
 --> /data/input/main.k:20:1
   |
20 | import helpers
   | ^ pkgpath helpers not found in the program
   |

suggestion: try 'kcl mod add helpers' to download the missing package
suggestion: browse more packages at 'https://artifacthub.io'

error[E2F04]: CannotFindModule
 --> /data/input/main.k:20:1
   |
20 | import helpers
   | ^ Cannot find the module helpers from /data/input/helpers
   |

error[E2G22]: TypeError
 --> /data/input/main.k:28:15
   |
28 |             **helpers.buildCompositionTestSpec("vpc")
   |               ^ attribute 'buildCompositionTestSpec' not found in 'module 'helpers''
   |

error[E2G22]: TypeError
 --> /data/input/main.k:58:17
   |
58 |                 helpers.buildVPC(
   |                 ^ attribute 'buildVPC' not found in 'module 'helpers''
   |

[Additional similar errors for buildSubnet, buildEIP, buildNATGateway, etc.]
```

**Key observation from error:**
- Path in error: `/data/input/main.k` (container filesystem)
- Error states: "Cannot find the module helpers from `/data/input/helpers`"
- This is NOT the host filesystem path (`/Users/tobiaskasser/up/configuration-aws-vpc/tests/`)

### Technical Analysis: Container Isolation

**Evidence of containerization:**

1. **Host filesystem path:**
   ```
   /Users/tobiaskasser/up/configuration-aws-vpc/tests/test-vpc-simple/main.k
   ```

2. **Container filesystem path (from error):**
   ```
   /data/input/main.k
   ```

**What this reveals:**

The `up test run` command:
1. Creates an isolated container for each test
2. Copies only the specific test directory into `/data/input/` in the container
3. Does NOT copy sibling directories (like `../shared`)
4. Mounts model directory via symlink resolution
5. Executes KCL compilation inside container with limited filesystem scope

**Directory structure in container (inferred):**
```
/data/input/
├── main.k               (copied from tests/test-vpc-simple/main.k)
├── kcl.mod              (copied from tests/test-vpc-simple/kcl.mod)
└── model/               (resolved from symlink)
    └── [models...]

# NOT PRESENT:
# ../shared/  ← This directory is NOT copied into container
```

**Why the import fails:**

When `kcl.mod` references `helpers = { path = "../shared" }`, KCL looks for:
```
/data/input/../shared/  → /data/shared/
```

But this directory does not exist in the container because `up test run` only copied `/test-vpc-simple/` not `/shared/`.

---

## Framework Behavior: What Works vs What Doesn't

### ✅ What WORKS (Evidence-Based)

1. **Local symlinks to project directories:**
   ```
   model -> ../../.up/kcl/models  ✅ Works
   ```
   The framework resolves symlinks and copies the target content into container.

2. **Dependencies within test directory:**
   ```
   tests/test-vpc-simple/
   ├── main.k
   ├── helpers.k          ✅ Would work (in same directory)
   └── kcl.mod
   ```

3. **External packages from registries:**
   ```toml
   [dependencies]
   models = { oci = "...", version = "..." }  ✅ Works
   ```

### ❌ What DOESN'T WORK (Confirmed)

1. **Path-based dependencies to sibling directories:**
   ```toml
   helpers = { path = "../shared" }  ❌ Fails
   ```

2. **Path-based dependencies to parent/ancestor directories:**
   ```toml
   common = { path = "../../common" }  ❌ Would fail
   ```

3. **Any module outside the test directory:**
   ```toml
   utils = { path = "/absolute/path" }  ❌ Would fail
   ```

---

## Verification: Tests Without Shared Helpers

**After reverting changes:**

```bash
git checkout tests/test-vpc-simple/main.k \
            tests/test-vpc-simple/kcl.mod \
            tests/test-vpc-nat-single/main.k \
            tests/test-vpc-nat-single/kcl.mod

up test run tests/test-vpc-simple tests/test-vpc-nat-single
```

**Result:**
```
✓ Parsing tests
✓ Collecting resources
✓ Generating language schemas
✓ Checking dependencies
✓ Building functions
✓ Building configuration package
✓ Pushing embedded functions to local daemon
✓ Assert test-vpc-simple
✓ Assert test-vpc-nat-single

SUCCESS: Total Tests Executed: 2
SUCCESS: Passed tests:         2
SUCCESS: Failed tests:         0
```

**Conclusion:** Original tests (without shared helpers) work perfectly. The limitation is specifically with external module dependencies.

---

## Impact on Refactoring Plan

### Original Plan (P1-P2): ❌ BLOCKED

**P1: Shared helper utilities**
- Goal: Create `tests/shared/helpers.k` with builder functions
- Expected benefit: 80-90% code reduction across 70 tests
- Status: **NOT FEASIBLE** due to container isolation

**P2: Shared test fixtures**
- Goal: Create `tests/shared/fixtures.k` with common test data
- Expected benefit: 60-70% code reduction
- Status: **NOT FEASIBLE** due to same limitation

### Alternative Approaches

**Option A: Copy helpers into each test directory**
```
tests/test-vpc-simple/
├── main.k
├── helpers.k          ← Copy of shared helpers
└── kcl.mod

tests/test-vpc-nat-single/
├── main.k
├── helpers.k          ← Duplicate copy
└── kcl.mod
```
- ✅ Would work (helpers in same directory)
- ❌ Defeats DRY principle
- ❌ 70 copies of helpers.k to maintain

**Option B: Parameterized test matrices (RECOMMENDED)**
```kcl
// Consolidate 6 NAT test directories into 1 file
_natVariants = [
    { name: "disabled", enableNatGateway: False },
    { name: "single", singleNatGateway: True },
    { name: "per-az", oneNatGatewayPerAz: True },
    // ... more variants
]

items = [buildNatTest(v) for v in _natVariants]
```
- ✅ No external dependencies
- ✅ 70-80% code reduction (similar to helpers)
- ✅ Single file to maintain
- ✅ Works within container constraints

**Option C: Template-based code generation**
- Generate test files from templates (outside `up test` framework)
- Use build-time code generation
- Requires tooling setup

**Option D: Request framework enhancement**
- Submit feature request to Upbound
- Ask for shared test utilities support
- Long-term solution

---

## Files Created (Kept for Reference)

The shared helpers were fully implemented before discovering the limitation:

**tests/shared/helpers.k** (22,372 bytes):
- `buildProviderConfigRef()` - Standard providerConfigRef
- `buildManagedResource()` - Generic resource builder
- `buildCompositionTestSpec()` - Base test spec
- `buildVPC()` - VPC resource
- `buildSubnet()` - Subnet resource
- `buildInternetGateway()` - IGW resource
- `buildNATGateway()` - NAT Gateway resource
- `buildEIP()` - Elastic IP resource
- `buildRouteTable()` - Route table resource
- `buildRoute()` - Route resource
- `buildRouteTableAssociation()` - Route table association
- `buildVPCEndpoint()` - VPC endpoint resource
- `buildSecurityGroup()` - Security group resource
- `buildNetworkACL()` - Network ACL resource
- `buildVPCDHCPOptions()` - DHCP options resource
- `buildVPCDHCPOptionsAssociation()` - DHCP options association
- `buildCustomerGateway()` - Customer gateway resource
- `buildVPNGateway()` - VPN gateway resource
- `buildFlowLog()` - Flow log resource
- `buildEgressOnlyInternetGateway()` - Egress-only IGW resource

These helpers remain in the repository but cannot be used due to framework limitation.

---

## Next Steps

**Immediate action:**
1. Update refactoring plan to mark P1/P2 as BLOCKED
2. Pivot to P3-P5 (test consolidation via parameterized matrices)
3. Start with P3: Consolidate NAT Gateway tests (6 directories → 1 file)

**Refactoring plan updated:**
- `thoughts/tasks/REFACTOR_TESTS.md` has been updated with:
  - P1: Marked as BLOCKED with detailed explanation
  - P2: Marked as BLOCKED with same limitation
  - Phase 1: Marked as skipped
  - Phase 2: Marked as recommended starting point
  - Completed section: Added P1/P2 evaluation results

**No code changes required:**
- All test modifications were reverted
- Tests are passing (2/2 composition tests verified)
- Project is in clean state

---

## Additional Technical Details

### Container Runtime Investigation

**Command that triggers containerization:**
```bash
up test run tests/test-vpc-simple
```

**Inferred container setup:**
1. Build phase creates package: `_output/configuration-aws-vpc.uppkg`
2. Test phase creates temporary container per test directory
3. Container filesystem setup:
   - Mount test directory at `/data/input/`
   - Resolve and copy symlinked models
   - Copy kcl.mod dependencies (if resolvable)
   - Execute KCL compilation
   - Run assertions

**Why symlinks to models work:**
```
tests/test-vpc-simple/model -> ../../.up/kcl/models
```
- Framework detects symlink during container setup
- Resolves symlink to actual directory: `.up/kcl/models/`
- Copies resolved content into container
- Models available at `/data/input/model/` in container

**Why path dependencies don't work:**
```toml
helpers = { path = "../shared" }
```
- KCL module resolution happens INSIDE container
- At runtime, KCL looks for `/data/input/../shared/` → `/data/shared/`
- Framework did NOT copy `tests/shared/` into container (outside test directory)
- Module resolution fails

### Framework Design Intent

The container isolation appears intentional:
- **Reproducibility:** Each test runs in identical, isolated environment
- **Parallelization:** Tests can run concurrently without interference
- **Portability:** Tests are self-contained (could run on CI without full repo)
- **Security:** Limited filesystem access prevents tests from affecting host

This design benefits production use but constrains code reuse strategies.
