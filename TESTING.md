# Testing Guide

This project follows **strict Test-Driven Development (TDD)**. All code is tested before implementation.

## Quick Start

```bash
# Run all composition tests (fast, no AWS)
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-public-subnets

# Run E2E tests (slow, requires AWS credentials)
up login
up test run tests/e2etest-xvpc-basic --e2e
```

## The Golden Rule

**🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT**

Never write code before tests. Never commit failing tests. **E2E tests are MANDATORY for all features.**

## Test-Driven Development Workflow

### For Every New Feature:

#### 1. 🔴 RED - Write Test First

```bash
# Generate test
up test generate test-xvpc-<feature> --language=kcl

# Edit test
cd tests/test-xvpc-<feature>/
# Edit main.k - assert expected resources

# Run test (should FAIL)
up test run tests/test-xvpc-<feature>
```

**Expected**: ❌ FAIL (feature not implemented yet)

**If test passes immediately**: Your test is wrong. Fix it.

#### 2. 🟢 GREEN - Make Test Pass

```bash
# Implement feature
cd functions/vpc/
# Edit main.k or create module

# Run test until it passes
up test run tests/test-xvpc-<feature>
```

**Expected**: ✅ PASS

```bash
# Run ALL tests (check for regressions)
up test run tests/test-*
```

**Expected**: ✅ ALL PASS

**If ANY test fails**: Fix broken tests immediately. Do not proceed.

#### 3. 🔵 REFACTOR - Improve Code

```bash
# Refactor for clarity
# Extract to modules
# Improve naming

# Keep tests green
up test run tests/test-*
```

**Expected**: ✅ ALL PASS (always)

#### 4. 🧪 E2E TEST - MANDATORY Real AWS Validation

```bash
# Generate E2E test (MANDATORY for ALL major features)
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Edit test: tests/e2etest-xvpc-<feature>/main.k
# Configure:
# - ProviderConfig with IAM role: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
# - Use assumeRoleChain (NEVER static credentials)
# - Set timeout: 1800-3000 seconds (30-50 minutes)
# - Set skipDelete: false (ensure cleanup)
# - Set validate: true
# - Add defaultConditions: ["Ready", "Synced"]

# Run E2E test (requires up login)
up login
up test run tests/e2etest-xvpc-<feature> --e2e
```

**Expected**: ✅ PASS (resources created, reach Ready/Synced, cleaned up)

**CRITICAL**: Do NOT skip this step. E2E tests are MANDATORY.

#### 5. ✅ COMMIT - Only When ALL Tests Pass

```bash
# Final checks - EVERYTHING must pass
up project build
up test run tests/test-*                    # Composition tests
up test run tests/e2etest-* --e2e           # E2E tests

# Commit only if EVERYTHING passes
git add .
git commit -m "feat: implement <feature>

- Add composition test for <feature>
- Implement <feature> in functions/vpc/
- Add E2E test validating real AWS behavior
- All tests passing
"
```

## Test Types

### Composition Tests (Unit Tests)

**Purpose**: Validate that composition generates correct managed resources

**Characteristics**:
- ⚡ Fast (< 10 seconds)
- 🔒 Isolated (no AWS API calls)
- 🎯 Focused (one feature per test)
- 📦 Comprehensive (100% feature coverage)

**Location**: `tests/test-xvpc-*/`

**Run**: `up test run tests/test-*`

**Example**:
```kcl
# tests/test-xvpc-public-subnets/main.k
metav1alpha1.CompositionTest{
    metadata.name: "test-xvpc-public-subnets"
    spec= {
        compositionPath: "../../apis/vpc/composition.yaml"
        xrdPath: "../../apis/vpc/definition.yaml"
        timeoutSeconds: 60

        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "XVPC"
            spec: {
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                azs: ["us-west-2a", "us-west-2b"]
            }
        }

        assertResources: [
            {
                apiVersion: "ec2.aws.upbound.io/v1beta1"
                kind: "Subnet"
                spec.forProvider: {
                    cidrBlock: "10.0.1.0/24"
                    mapPublicIpOnLaunch: True
                }
            }
        ]
    }
}
```

### E2E Tests - MANDATORY FOR ALL FEATURES

**Purpose**: Validate behavior with real AWS resources

**Characteristics**:
- 🐌 Slow (10-30 minutes)
- 💰 Expensive (real AWS resources)
- 🌐 Complete (full lifecycle: create → ready → delete)
- ⚠️ **MANDATORY** - Required for ALL major features

**CRITICAL**: E2E tests are NO LONGER optional. Composition tests validate KCL logic, but E2E tests validate real AWS behavior. A feature is NOT complete without E2E validation.

**Location**: `tests/e2etest-xvpc-*/`

**Run**: `up test run tests/e2etest-* --e2e` (requires `up login`)

**Example**:
```kcl
# tests/e2etest-xvpc-basic/main.k
metav1alpha1.E2ETest{
    metadata.name: "e2etest-xvpc-basic"
    spec= {
        timeoutSeconds: 1800
        cleanupTimeoutSeconds: 600
        skipDelete: False
        defaultConditions: ["Ready", "Synced"]

        manifests: [
            {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                }
            }
        ]

        extraResources: [
            {
                apiVersion: "aws.upbound.io/v1beta1"
                kind: "ProviderConfig"
                metadata.name: "default"
                spec.assumeRoleChain: [
                    {roleARN: "arn:aws:iam::ACCOUNT:role/ROLE"}
                ]
            }
        ]
    }
}
```

## Test Organization

```
tests/
├── test-xvpc-basic/              # Basic VPC
├── test-xvpc-subnets-public/     # Public subnets
├── test-xvpc-subnets-private/    # Private subnets
├── test-xvpc-igw-enabled/        # IGW enabled
├── test-xvpc-igw-disabled/       # IGW disabled
├── test-xvpc-nat-single/         # Single NAT
├── test-xvpc-nat-per-az/         # NAT per AZ
├── test-xvpc-routes-public/      # Public routing
├── test-xvpc-routes-private/     # Private routing
└── e2etest-xvpc-basic/           # E2E: Basic VPC
```

## Writing Good Tests

### 1. Test One Thing

```kcl
# ✅ GOOD: Test public subnets only
test-xvpc-subnets-public

# ❌ BAD: Test everything at once
test-xvpc-complete-with-all-features
```

### 2. Assert All Critical Fields

```kcl
# ✅ GOOD: Complete assertions
assertResources: [{
    kind: "Subnet"
    spec.forProvider: {
        cidrBlock: "10.0.1.0/24"
        availabilityZone: "us-west-2a"
        mapPublicIpOnLaunch: True
        vpcIdSelector.matchControllerRef: True
        tags: {Type: "public"}
    }
}]

# ❌ BAD: Incomplete assertions
assertResources: [{
    kind: "Subnet"
}]
```

### 3. Use Realistic Inputs

```kcl
# ✅ GOOD: Real-world configuration
xr: {
    spec: {
        region: "us-west-2"
        cidr: "10.0.0.0/16"
        azs: ["us-west-2a", "us-west-2b"]
        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
    }
}

# ❌ BAD: Minimal/unrealistic
xr: {
    spec: {region: "us-west-2"}
}
```

### 4. Document Expected Behavior

```kcl
"""
Public Subnets Composition Test

Validates the terraform-aws-modules/vpc "simple" example:
- Public subnets created across multiple AZs
- mapPublicIpOnLaunch enabled
- Correct CIDR blocks assigned
- Tags merged correctly

Spec: terraform-vpc-analysis.md section 2 (MINIMAL VPC)
"""
```

## Running Tests

### Local Development

```bash
# Run all composition tests
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-public-subnets

# Run pattern
up test run tests/test-xvpc-subnets-*

# Build first (if needed)
up project build
```

### E2E Tests

```bash
# Login to Upbound (required for E2E)
up login

# List available groups
up group list

# Run single E2E test (MUST specify group!)
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing

# Run all E2E tests (slow!)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

**CRITICAL**: Always specify `--control-plane-group` when running E2E tests. This determines which Upbound group the ephemeral control plane will be created in.

### CI/CD

**Composition Tests**: Run on every PR
```yaml
# .github/workflows/composition-test.yaml
- run: up test run tests/test-*
```

**E2E Tests**: Run on labeled PRs
```yaml
# .github/workflows/e2e.yaml
# Add label "run-e2e-tests" to PR
```

## Debugging Tests

### Test Fails - What to Do?

1. **Read the error message carefully**
   ```bash
   up test run tests/test-xvpc-public-subnets
   # Error: expected field "mapPublicIpOnLaunch: true" but got "false"
   ```

2. **Check generated resources**
   ```bash
   # Build project first
   up project build

   # Inspect generated resources (implementation-dependent)
   ```

3. **Verify test assertions match implementation**
   - Read: `functions/vpc/main.k`
   - Read: `tests/test-xvpc-public-subnets/main.k`
   - Ensure assertions match code

4. **Fix either test or implementation**
   - If test is wrong: fix test
   - If implementation is wrong: fix code
   - Run test again until green

### Common Issues

#### Test Passes Immediately (RED phase)

**Problem**: Test should fail because feature isn't implemented yet

**Solution**: Test is incomplete or wrong. Add more assertions.

```kcl
# ❌ BAD: Test too vague
assertResources: [{kind: "Subnet"}]

# ✅ GOOD: Test specific
assertResources: [{
    kind: "Subnet"
    spec.forProvider.cidrBlock: "10.0.1.0/24"
    spec.forProvider.mapPublicIpOnLaunch: True
}]
```

#### Test Fails After Implementation (GREEN phase)

**Problem**: Implementation doesn't match test expectations

**Solution**: Debug and fix

```bash
# Check what resources are actually generated
# Fix implementation or test assertion
up test run tests/test-xvpc-<feature>
```

#### Existing Tests Break (Regression)

**Problem**: New feature broke existing functionality

**Solution**: Fix the regression immediately

```bash
# Identify broken test
up test run tests/test-*

# Fix the implementation
# Ensure all tests pass before committing
```

## Test Coverage Goals

- ✅ **100% of features** have composition tests
- ✅ **100% of major features** have E2E tests (MANDATORY)
- ✅ **All tests pass** before every commit (composition + E2E)
- ✅ **No flaky tests** (99.9% pass rate)
- ✅ **All E2E tests verify cleanup** (no orphaned AWS resources)

## Feature Parity Validation

This project is a **drop-in replacement** for terraform-aws-modules/vpc.

### Input Validation

Every Terraform input variable MUST:
1. Have XRD field
2. Have composition test
3. Behave identically to Terraform

### Output Validation

Every Terraform output MUST:
1. Appear in XRD status
2. Have test asserting it's set
3. Match Terraform value

### Behavior Validation

E2E tests compare against Terraform:
1. Deploy same config with Terraform
2. Deploy same config with Upbound
3. Compare outputs (should match)

## Best Practices

### DO:
- ✅ Write tests before code (always)
- ✅ Write E2E tests for ALL major features (MANDATORY)
- ✅ Keep tests fast (< 10s for composition)
- ✅ Test one feature per test
- ✅ Assert all critical fields
- ✅ Fix broken tests immediately
- ✅ Run all tests before committing (composition + E2E)
- ✅ Verify E2E tests clean up resources

### DON'T:
- ❌ Write code before tests
- ❌ Commit failing tests
- ❌ Skip tests for "simple" features
- ❌ Skip E2E tests (they are MANDATORY)
- ❌ Mark features "complete" without E2E validation
- ❌ Write vague assertions
- ❌ Ignore test failures
- ❌ Write flaky tests
- ❌ Leave orphaned AWS resources after E2E tests

## Resources

### Documentation
- [thoughts/TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) - Complete TDD guide
- [thoughts/ARCHITECTURE.md](thoughts/ARCHITECTURE.md) - Modular design
- [thoughts/tools/testing-guide.md](thoughts/tools/testing-guide.md) - Technical guide
- [thoughts/tools/testing-kcl-patterns.md](thoughts/tools/testing-kcl-patterns.md) - KCL patterns

### Examples
- [tests/test-test-xvpc-simple/](tests/test-test-xvpc-simple/) - Simple composition test
- [tests/e2etest-e2etest-xvpc-simple/](tests/e2etest-e2etest-xvpc-simple/) - Simple E2E test

### References
- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Upbound Testing Docs](https://docs.upbound.io/)
- [Platform Ref Upbound](https://github.com/upbound/platform-ref-upbound) - Testing examples

## Getting Help

**Test generation**:
```bash
up test generate test-xvpc-<feature> --language=kcl
up test generate e2etest-xvpc-<scenario> --e2e --language=kcl
```

**Test execution**:
```bash
up test run tests/test-<name>
up test run tests/e2etest-<name> --e2e
```

**Common commands**:
```bash
# Build project
up project build

# Run all composition tests
up test run tests/test-*

# Run all E2E tests
up test run tests/e2etest-* --e2e

# Check test status
up test list
```

---

**Remember**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**Never skip tests. Never skip E2E tests. Never commit failing tests.**

## 🚨 CRITICAL CHANGE - E2E Tests Now MANDATORY

**Effective immediately**: E2E tests are MANDATORY for ALL features before marking them complete.

### Why:
- Composition tests validate KCL logic only
- E2E tests validate actual AWS behavior
- Features may pass composition tests but fail in real AWS
- We need confidence that implementations work in production

### What This Means:
1. **Task 0.1 is now the highest priority** - Add E2E tests for existing features (tasks 2.1-2.5)
2. **New workflow**: Write composition test → implement → write E2E test → commit
3. **Definition of "done"**: Feature is complete ONLY when both composition AND E2E tests pass
4. **Before commit**: Run `up test run tests/test-*` AND `up test run tests/e2etest-* --e2e`

### IAM Role for E2E Tests:
All E2E tests MUST use the following IAM role (never static credentials):
```
arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
```

Configure in ProviderConfig with `assumeRoleChain` (see examples above).
