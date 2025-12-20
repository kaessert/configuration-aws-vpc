# Comprehensive Testing Guide for Upbound Projects

**Last Updated**: 2025-12-20

This guide provides complete reference documentation for testing Upbound configurations, consolidating all testing knowledge and best practices.

---

## Table of Contents

1. [Overview & Philosophy](#1-overview--philosophy)
2. [Composition Tests (Unit Tests)](#2-composition-tests-unit-tests)
3. [E2E Tests (Integration Tests)](#3-e2e-tests-integration-tests)
4. [Test Organization](#4-test-organization)
5. [CI/CD Integration](#5-cicd-integration)
6. [Common Issues & Solutions](#6-common-issues--solutions)
7. [Quick Reference](#7-quick-reference)

---

## 1. Overview & Philosophy

### Testing Strategy

This project follows **strict Test-Driven Development (TDD)** with mandatory E2E validation:

**The Iron Rule**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

1. **🔴 RED**: Write composition test FIRST (test MUST fail)
2. **🟢 GREEN**: Write minimum code to pass test
3. **🔵 REFACTOR**: Improve code while keeping tests green
4. **🧪 E2E TEST**: Write and pass E2E test (MANDATORY)
5. **✅ COMMIT**: Only commit when ALL tests pass (composition + E2E)

### Test Pyramid

```
        /\
       /E2E\      <- Slow (20-40 min), Expensive, Real Cloud
      /------\
     /Compo- \   <- Fast (< 10 sec), Free, Logic Only
    /  sition \
   /    Tests  \
  /--------------\
```

**Composition Tests** (Majority):
- Fast (< 10 seconds)
- Isolated (no AWS calls)
- 100% feature coverage
- Run: `up test run tests/test-*`

**E2E Tests** (MANDATORY for ALL features):
- Slow (10-30 minutes)
- Real AWS resources
- Validates actual cloud behavior
- Run: `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`

### Key Principles

1. **Write tests for every feature**: Each feature gets at least one composition test
2. **E2E tests are MANDATORY**: A feature is NOT complete without E2E validation
3. **Test early and often**: Composition tests run on every commit
4. **Fix broken tests immediately**: When features change, update tests before proceeding
5. **Use IAM roles**: Never static credentials in E2E tests
6. **Verify cleanup**: Always check AWS Console after E2E tests

---

## 2. Composition Tests (Unit Tests)

### What Are Composition Tests?

**Definition**: Fast unit tests that validate composition function logic without requiring a live control plane or cloud resources.

**Purpose**:
- Validate KCL logic and resource generation
- Test conditional branching and feature flags
- Verify resource specifications match inputs
- Catch syntax and schema errors early

**Speed**: Seconds (typically < 10 seconds per test)

**When to use**:
- Development (fast feedback loop)
- CI on every PR
- Before E2E tests
- Testing all code paths

### Test Structure

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

test = metav1alpha1.CompositionTest {
    # File paths (relative to test directory)
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/simple-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"

    # Test configuration
    timeoutSeconds = 60           # Usually 60s is enough
    validate = True               # Enable schema validation

    # Assert expected resources
    assertResources = [
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "VPC"
            metadata: {
                name = "vpc-test-vpc"  # Must match generated name
            }
            spec = {
                forProvider = {
                    cidrBlock = "10.0.0.0/16"
                    region = "us-west-2"
                    enableDnsHostnames = True
                    enableDnsSupport = True
                }
            }
        }
    ]
}

items = [test]
```

### Key Fields

| Field | Purpose | Required |
|-------|---------|----------|
| `compositionPath` | Path to composition YAML | ✅ YES |
| `xrPath` | Path to example XR | ✅ YES |
| `xrdPath` | Path to XRD definition | ✅ YES |
| `timeoutSeconds` | Max execution time (default: 60) | ❌ Optional |
| `validate` | Enable schema validation | ❌ Optional |
| `assertResources` | Expected resources | ❌ Optional (recommended) |

### assertResources Pattern

**CRITICAL**: `assertResources` expects FULL resource definitions, not partial matches!

**✅ CORRECT**:
```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        metadata = {
            name = "vpc-test-vpc"  # MUST match generated name
        }
        spec = {
            forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                # Include all fields your function generates
            }
        }
    }
]
```

**❌ WRONG**:
```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        assert: {  # This field doesn't exist!
            "spec.forProvider.cidrBlock": "10.0.0.0/16"
        }
    }
]
```

### Finding Resource Names

To find correct resource names for assertions:

```bash
# Render composition to see generated names
up composition render \
  apis/vpc/composition.yaml \
  examples/simple-vpc.yaml \
  --xrd apis/vpc/definition.yaml

# Output shows exact metadata.name values:
# metadata:
#   name: vpc-test-vpc  ← Use this in assertion
```

### Generating Tests

```bash
# Generate KCL composition test
up test generate test-xvpc-basic --language=kcl

# Generate Python composition test
up test generate test-xvpc-complex --language=python

# Generate YAML composition test (default)
up test generate test-xvpc-subnets
```

### Running Tests

```bash
# Run all composition tests
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-basic

# Run with verbose output
up test run tests/test-* --verbose
```

### Test Scenarios to Cover

For each major feature:

1. **Basic scenario**: Minimal required inputs
2. **Complex scenario**: All options enabled
3. **Conditional logic**: Features enabled/disabled
4. **Strategy variations**: Different implementation strategies
5. **Edge cases**: Boundary conditions (single AZ, many AZs)
6. **Multiple resources**: Test resource counts
7. **Dependencies**: Resources that depend on others

### Best Practices

**DO**:
- ✅ Write tests FIRST (TDD: test before code)
- ✅ Test each feature independently
- ✅ Use descriptive test names (`test-xvpc-nat-single`)
- ✅ Assert all generated resources
- ✅ Test conditional logic (enabled vs disabled)
- ✅ Keep tests fast (< 10 seconds)
- ✅ Run tests frequently

**DON'T**:
- ❌ Skip composition tests
- ❌ Test too much in one test
- ❌ Use partial assertions
- ❌ Ignore test failures
- ❌ Write tests after implementation

---

## 3. E2E Tests (Integration Tests)

### What Are E2E Tests?

**Definition**: End-to-End tests validate compositions by creating REAL cloud resources in a live environment.

**Purpose**:
- Validate compositions work with real cloud providers (AWS)
- Test provider integration and authentication
- Verify resources reach Ready/Synced states
- Ensure cleanup works correctly
- Catch issues that composition tests miss (AWS API behavior, timing, dependencies)

**Speed**: 20-40 minutes per test (slow!)

**When to use**:
- **MANDATORY** for all features in this project
- Before merging to main
- After implementing major features
- For critical paths in CI/CD (labeled PRs)

### E2E Test Structure

```kcl
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-basic"
        spec= {
            # Crossplane configuration (REQUIRED!)
            crossplane: {
                version: "2.0.2-up.5"  # CRITICAL - Must specify v2
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts
            timeoutSeconds: 1800            # 30 minutes for resource creation
            cleanupTimeoutSeconds: 600      # 10 minutes for cleanup

            # Cleanup settings (CRITICAL!)
            skipDelete: False               # MUST be False for cleanup verification

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Main test manifests
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-vpc"
                        namespace: "default"  # REQUIRED for namespaced claims
                    }
                    spec: {
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a"]
                        publicSubnets: ["10.0.1.0/24"]
                        tags: {
                            Environment: "e2e-test"
                            TestName: "basic"
                        }
                    }
                }
            ]

            # ProviderConfig for AWS authentication (REQUIRED!)
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"  # Note: .m. for namespaced
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"  # REQUIRED for namespaced claims
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"  # For Upbound Spaces
                        }
                        assumeRoleChain: [
                            {
                                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        ]
                    }
                }
            ]
        }
    }
]
items= _items
```

### Critical Configuration Requirements

#### 1. Crossplane Version (MANDATORY)

**ALWAYS specify Crossplane version**:

```kcl
crossplane: {
    version: "2.0.2-up.5"  # Crossplane v2 with Upbound extensions
    autoUpgrade: {
        channel: "Rapid"
    }
}
```

**Why this matters**:
- Default version may be v1 (incompatible with v2 APIs)
- Missing version causes package installation failure
- Error: `no kind "CompositeResourceDefinition" is registered for version "apiextensions.crossplane.io/v2"`

**Lesson learned**: If test hangs at "Waiting for package to be ready" for >3 minutes, check `kubectl get pkgrev -oyaml` for UnhealthyPackageRevision.

#### 2. ProviderConfig (MANDATORY)

**For Crossplane v2 with namespaced claims**:

```kcl
{
    apiVersion: "aws.m.upbound.io/v1beta1"  # CRITICAL: Use .m. suffix
    kind: "ProviderConfig"
    metadata: {
        name: "default"
        namespace: "default"  # REQUIRED for namespaced claims
    }
    spec: {
        credentials: {
            source: "Upbound"  # For Upbound Spaces identity
        }
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

**Key points**:
- ✅ Use `aws.m.upbound.io/v1beta1` (note the `.m.` suffix for namespaced provider)
- ✅ Add `namespace: "default"` to metadata (required for namespaced claims)
- ✅ Use `source: "Upbound"` (for Upbound Spaces managed credentials)
- ✅ Use `assumeRoleChain` with IAM role (never static credentials)
- ❌ NEVER use `aws.upbound.io/v1beta1` (parent provider - will not work)
- ❌ NEVER omit namespace field (will cause test to hang)

**Why the `.m.` suffix?**:
- Crossplane v2 introduced namespaced resources
- Parent provider: `aws.upbound.io`
- Namespaced provider: `aws.m.upbound.io` (note the `.m.`)
- Managed resources (VPC, Subnet, etc.) look for ProviderConfig in `aws.m.upbound.io`

#### 3. Control Plane Group (MANDATORY)

**ALWAYS specify `--control-plane-group` when running E2E tests**:

```bash
# ✅ CORRECT - Specifies group
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# ❌ WRONG - Missing group (will fail or use wrong context)
up test run tests/e2etest-* --e2e
```

**Why this is required**:
- E2E tests create ephemeral control planes in Upbound Spaces
- Control planes must be created in a specific group
- Without specifying the group, test may fail or use wrong context
- Use `claude-testing` for development/testing

**Check available groups**:
```bash
up group list
```

**Create group if needed**:
```bash
up group create claude-testing
```

### Timeout Settings

Set timeouts based on resource complexity:

| Resource Type | Recommended Timeout | Rationale |
|--------------|---------------------|-----------|
| VPC only | 600s (10 min) | VPC creation is fast |
| VPC + Subnets | 900s (15 min) | Subnets take 1-2 min each |
| VPC + IGW + Routes | 1200s (20 min) | IGW attachment can be slow |
| **VPC + NAT** | **1800s (30 min)** | NAT takes 10-15 min to reach Ready |
| Complete VPC (18 subnets) | 2400s (40 min) | Many resources, longer wait |

**Cleanup Timeout**: Always set `cleanupTimeoutSeconds: 600` (10 minutes)

### Running E2E Tests

```bash
# List available groups first
up group list

# Run specific E2E test (MUST specify group!)
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing

# Run all E2E tests (MUST specify group!)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

### E2E Test Execution Phases

**Complete timeline**: 25-47 minutes per test

| Phase | Duration | What's Happening |
|-------|----------|------------------|
| 1. Build & Package | 1-2 min | Local compilation |
| 2. Control Plane Setup | 2-3 min | Upbound Spaces provisioning |
| 3. Apply Manifests | 1 min | Create XR and managed resources |
| 4. Wait for Ready/Synced | 15-30 min | AWS creating actual resources |
| 5. Validation | 1 min | Test framework checks |
| 6. Cleanup | 5-10 min | Delete all resources |
| 7. Report | 1 sec | Final result |

### Monitoring E2E Tests

**Upbound Console**:
1. Login: https://console.upbound.io
2. Navigate: Organizations → solutions → Spaces
3. Find: Development control plane
4. Click: Control Plane → Managed Resources
5. Watch: Status progression (Creating → Syncing → Ready)

**AWS Console**:
1. Login: https://console.aws.amazon.com
2. Region: **us-west-2**
3. Service: **VPC**
4. Filter by tags: `Environment=e2e-test`, `TestName=<feature>`

### Cleanup Verification (CRITICAL!)

**After EVERY E2E test**, verify ALL resources are deleted:

```bash
# VPCs - MUST be empty
https://console.aws.amazon.com/vpc → Your VPCs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Subnets - MUST be empty
https://console.aws.amazon.com/vpc → Subnets
Filter: CIDR contains test CIDR
Expected: NO RESULTS

# Internet Gateways - MUST be empty
https://console.aws.amazon.com/vpc → Internet Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# NAT Gateways - MUST be empty (EXPENSIVE!)
https://console.aws.amazon.com/vpc → NAT Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Elastic IPs - MUST be empty (billable if unattached)
https://console.aws.amazon.com/ec2 → Elastic IPs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Route Tables - Custom tables MUST be empty
https://console.aws.amazon.com/vpc → Route Tables
Filter: Tags → TestName=<feature>
Expected: NO RESULTS (main/default tables are OK)
```

**Cost warning**: If resources NOT deleted:
- NAT Gateway: $0.045/hour = $32/month
- EIP (unattached): $0.005/hour = $3.60/month
- **ALWAYS verify cleanup!**

### Best Practices

**DO**:
- ✅ Write E2E tests for ALL major features
- ✅ Use IAM role authentication (never static credentials)
- ✅ Set appropriate timeouts (NAT = 30 min, VPC = 10 min)
- ✅ Always set `skipDelete: False` for cleanup verification
- ✅ Verify cleanup in AWS Console after test
- ✅ Tag resources with `Environment: e2e-test` for easy filtering
- ✅ Run composition tests first (fast feedback)
- ✅ **ALWAYS specify `--control-plane-group`**

**DON'T**:
- ❌ Skip E2E tests for "simple" features
- ❌ Use static AWS credentials (security risk!)
- ❌ Set `skipDelete: True` in committed tests
- ❌ Forget to verify cleanup (cost risk!)
- ❌ Use production AWS account for E2E tests
- ❌ Run E2E tests on every commit (too slow)
- ❌ Commit failing E2E tests
- ❌ **Run without `--control-plane-group` flag**

---

## 4. Test Organization

### Directory Structure

```
tests/
├── test-xvpc-basic/                    # Composition test: Basic VPC
│   ├── main.k
│   ├── kcl.mod
│   └── kcl.mod.lock
├── test-xvpc-public-subnets/           # Composition test: Public subnets
│   └── main.k
├── test-xvpc-nat-single/               # Composition test: Single NAT
│   └── main.k
├── test-xvpc-nat-per-az/               # Composition test: NAT per AZ
│   └── main.k
└── e2etest-xvpc-basic/                 # E2E test: Basic VPC
    └── main.k
```

### Naming Conventions

**Composition tests**: `test-<resource>-<variant>/`
- `test-xvpc-basic` - Basic VPC only
- `test-xvpc-public-subnets` - VPC with public subnets
- `test-xvpc-nat-single` - Single NAT Gateway strategy
- `test-xvpc-nat-per-az` - NAT per AZ strategy

**E2E tests**: `e2etest-<resource>-<variant>/`
- `e2etest-xvpc-basic` - Basic E2E test
- `e2etest-xvpc-nat` - NAT Gateway E2E test
- `e2etest-xvpc-complete` - Complete E2E test

### Test File Structure

Each test directory contains:
- `main.k` (or `main.py`): Test definition
- `kcl.mod`: KCL dependencies
- `kcl.mod.lock`: Dependency lock file
- `README.md` (optional): What the test validates

---

## 5. CI/CD Integration

### Composition Tests Workflow

Run on **every** push and PR (fast, no cost):

```yaml
# .github/workflows/composition-test.yaml
name: Composition Tests
on:
  push:
    branches: [main]
  pull_request: {}

jobs:
  composition-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          skip-login: true  # No credentials needed
      - run: up project build
      - run: up test run tests/test-*
```

### E2E Tests Workflow

Run **only on labeled PRs** (slow, has cost):

```yaml
# .github/workflows/e2e.yaml
name: E2E Tests
on:
  pull_request_target:
    types: [synchronize, labeled]

env:
  UP_API_TOKEN: ${{ secrets.UP_API_TOKEN }}
  UP_ORG: ${{ secrets.UP_ORG }}
  UP_GROUP: ${{ secrets.UP_GROUP || 'default' }}

jobs:
  e2e:
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e-tests')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          api-token: ${{ secrets.UP_API_TOKEN }}
          organization: ${{ secrets.UP_ORG }}
      - run: up project build
      - run: up test run tests/e2etest-* --e2e --control-plane-group=${{ env.UP_GROUP }}
```

**Key features**:
- Only runs when PR has "run-e2e-tests" label
- Uses pull_request_target for secret access
- Requires UP_API_TOKEN, UP_ORG, UP_GROUP
- Tests run on real control plane in Upbound Cloud

---

## 6. Common Issues & Solutions

### Composition Test Issues

#### Issue: "no actual resource found"

**Error**: `no actual resource found: ec2.aws.upbound.io/v1beta1/VPC/`

**Cause**: Missing or empty `metadata.name` in assertResources

**Solution**: Add `metadata.name` with exact name your composition generates:
```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        metadata = {
            name = "vpc-test-vpc"  # Must match generated name
        }
        spec = { ... }
    }
]
```

#### Issue: Test fails with spec mismatch

**Error**: `Resource spec doesn't match assertion`

**Cause**: Assertion doesn't match actual generated resources

**Solution**: Render composition to see actual output:
```bash
up composition render apis/vpc/composition.yaml examples/xr.yaml --xrd apis/vpc/definition.yaml
```

### E2E Test Issues

#### Issue: Test hangs at "Waiting for package to be ready"

**Symptoms**: Test stuck for >3 minutes at package installation

**Diagnosis**: Package installation failing or Crossplane version mismatch

**Check**: `kubectl get pkgrev -oyaml` on control plane for errors

**Solution**: Ensure `crossplane.version = "2.0.2-up.5"` is set in test

#### Issue: "IAM role cannot be assumed"

**Error**: `User: ... is not authorized to perform: sts:AssumeRole`

**Cause**: Provider can't authenticate with AWS

**Solution**:
1. Verify ProviderConfig uses correct IAM role ARN
2. Ensure `source: "Upbound"` (not "Secret")
3. Check IAM role trust policy allows Upbound

#### Issue: "ProviderConfig not found"

**Error**: `ProviderConfig.aws.m.upbound.io "default" not found`

**Cause**: Using wrong API group or missing namespace

**Solution**:
1. Use `aws.m.upbound.io/v1beta1` (note the `.m.` suffix)
2. Add `namespace: "default"` to ProviderConfig metadata
3. Ensure namespace matches your claim namespace

#### Issue: Test hangs at "Applying Extra Resources"

**Symptoms**: Test stuck on "Applying Extra Resources" for >10 minutes

**Cause**: ProviderConfig missing namespace field

**Solution**: Add `namespace: "default"` to ProviderConfig metadata:
```kcl
metadata: {
    name: "default"
    namespace: "default"  # REQUIRED for namespaced claims
}
```

#### Issue: Resources not cleaning up

**Symptoms**: Test completes but AWS resources remain

**Diagnosis**: Dependencies blocking deletion

**Solution**: Manual cleanup in reverse dependency order:
```bash
# 1. Delete route table associations
# 2. Delete routes
# 3. Delete NAT Gateways (wait 5-10 min!)
# 4. Release Elastic IPs
# 5. Detach and delete Internet Gateway
# 6. Delete subnets
# 7. Delete route tables
# 8. Delete VPC
```

---

## 7. Quick Reference

### Commands

```bash
# Composition Tests
up test generate test-xvpc-<feature> --language=kcl  # Generate test
up test run tests/test-*                             # Run all
up test run tests/test-xvpc-basic                    # Run specific
up test run tests/test-* --verbose                   # Verbose output

# E2E Tests
up group list                                        # List groups
up test generate e2etest-xvpc-<feature> --e2e --language=kcl  # Generate
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing  # Run all
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing  # Run specific

# Preview
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml --xrd apis/vpc/definition.yaml

# Monitoring
up controlplane list --group=claude-testing          # List control planes
kubectl get managed                                  # List managed resources
kubectl get composite                                # List composites
kubectl describe xvpc <name>                         # Inspect VPC
```

### Timeouts

| Test Scenario | Creation Timeout | Cleanup Timeout |
|--------------|------------------|-----------------|
| VPC only | 600s (10 min) | 600s (10 min) |
| VPC + Subnets | 900s (15 min) | 600s (10 min) |
| VPC + IGW + Routes | 1200s (20 min) | 600s (10 min) |
| **VPC + NAT** | **1800s (30 min)** | **600s (10 min)** |
| Complete VPC | 2400s (40 min) | 900s (15 min) |

### AWS Costs

**If cleanup works** (resources exist <1 hour):
- ✅ $0.00 - $0.10 per test

**If cleanup fails** (resources orphaned):
- ❌ NAT Gateway: $0.045/hour = $32/month
- ❌ Elastic IP (unattached): $0.005/hour = $3.60/month
- ❌ VPC, Subnets, Routes: Free (but clutter account)

**ALWAYS verify cleanup in AWS Console!**

### Test Checklist

**Before committing**:
- [ ] All composition tests pass: `up test run tests/test-*`
- [ ] All E2E tests pass: `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`
- [ ] Project builds: `up project build`
- [ ] AWS resources cleaned up (check AWS Console)
- [ ] No regressions in existing tests

**For new features**:
- [ ] Composition test written first (TDD)
- [ ] Composition test passes
- [ ] E2E test written
- [ ] E2E test passes
- [ ] Cleanup verified
- [ ] Documentation updated

---

## Summary

**Testing is MANDATORY for all features**:
1. Write composition tests for fast feedback (< 10 seconds)
2. Write E2E tests for real AWS validation (20-40 minutes)
3. Run composition tests on every commit
4. Run E2E tests before merging to main
5. Verify cleanup after E2E tests (cost risk!)
6. **ALWAYS use `--control-plane-group=claude-testing` for E2E tests**

**Key takeaways**:
- Composition tests: Fast, free, logic validation
- E2E tests: Slow, costs money, real AWS validation
- Both are required for complete feature validation
- Never skip E2E tests - they catch real-world issues
- Always verify cleanup - orphaned resources cost money

**References**:
- [Upbound Testing Docs](https://docs.upbound.io/build/control-plane-projects/testing/)
- [Unified Testing Blog](https://blog.upbound.io/unified-testing-with-upbound)
- [Composition Testing Patterns](https://blog.upbound.io/composition-testing-patterns-rendering)
- [Platform Ref Upbound](https://github.com/upbound/platform-ref-upbound)
