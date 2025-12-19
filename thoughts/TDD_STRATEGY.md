# Test-Driven Development (TDD) Strategy

## Overview

This project follows **strict Test-Driven Development (TDD)** practices. Tests are written **BEFORE** implementation code, and **all tests must pass before committing**.

## Core TDD Principle

```
🔴 RED → 🟢 GREEN → 🔵 REFACTOR → ✅ COMMIT
```

1. **🔴 RED**: Write a failing test
2. **🟢 GREEN**: Write minimum code to pass
3. **🔵 REFACTOR**: Improve code while keeping tests green
4. **✅ COMMIT**: Only commit when all tests pass

## Why TDD for This Project?

### 1. Feature Parity Guarantee

We're building a **drop-in replacement** for terraform-aws-modules/vpc. TDD ensures:
- ✅ Every Terraform feature has a corresponding test
- ✅ Behavior matches exactly (validated by tests)
- ✅ No regressions when adding features
- ✅ Outputs match Terraform module

### 2. Modular, Scalable Code

TDD forces modular design:
- ✅ Each module testable independently
- ✅ Clear interfaces between modules
- ✅ Low coupling, high cohesion
- ✅ Easy to extend without breaking existing code

### 3. Confidence

With comprehensive tests:
- ✅ Refactor fearlessly
- ✅ Add features without breaking existing ones
- ✅ Catch issues before production
- ✅ Document behavior through tests

## Test Pyramid

```
        ╱╲
       ╱E2E╲         1-5 E2E tests (slow, expensive, real AWS)
      ╱────╲
     ╱ Integ╲        5-10 integration tests (medium speed)
    ╱────────╲
   ╱ Comp Unit╲      50+ composition tests (fast, isolated)
  ╱────────────╲
```

### Level 1: Composition Tests (Unit) - MAJORITY OF TESTS

**Purpose**: Validate composition logic generates correct managed resources

**Characteristics**:
- ⚡ Fast (< 10 seconds each)
- 🔒 Isolated (no AWS calls)
- 🎯 Focused (one feature per test)
- 📦 Comprehensive (100% feature coverage)

**When to Write**: **BEFORE implementing ANY feature**

**Example**:
```bash
# Write test FIRST
up test generate test-xvpc-public-subnets --language=kcl

# Edit: tests/test-xvpc-public-subnets/main.k
# Assert:
# - 2 public subnets created
# - Correct CIDR blocks
# - mapPublicIpOnLaunch: true
# - Correct tags

# Run (should FAIL)
up test run tests/test-xvpc-public-subnets
# ❌ FAIL: No subnets generated

# Implement feature
# Edit: functions/vpc/main.k

# Run again (should PASS)
up test run tests/test-xvpc-public-subnets
# ✅ PASS

# Run ALL tests
up test run tests/test-*
# ✅ ALL PASS
```

### Level 2: Integration Tests - SOME TESTS

**Purpose**: Validate multiple modules working together

**Example**: Routes + Route Tables + Subnets integration

**When to Write**: After implementing related features

### Level 3: E2E Tests - FEW TESTS

**Purpose**: Validate in real AWS environment

**Characteristics**:
- 🐌 Slow (10-30 minutes)
- 💰 Expensive (real AWS resources)
- 🌐 Complete (full lifecycle)
- ✅ Final validation

**When to Write**: After composition tests pass, for critical scenarios

**Example**:
```bash
up test generate e2etest-xvpc-complete --e2e --language=kcl

# Run locally (requires up login)
up test run tests/e2etest-xvpc-complete --e2e

# Validates:
# - Resources created in AWS
# - Reach Ready/Synced state
# - Outputs correct
# - Resources cleaned up
```

## TDD Workflow: Step-by-Step

### For Every New Feature

#### Step 1: Understand Terraform Behavior

```bash
# 1. Read Terraform module code
# https://github.com/terraform-aws-modules/terraform-aws-vpc

# 2. Find relevant example
# https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples

# 3. Document expected behavior
# What inputs? What outputs? What resources created?
```

#### Step 2: Write Composition Test (RED)

```bash
# Generate test
up test generate test-xvpc-<feature> --language=kcl

# Edit test: tests/test-xvpc-<feature>/main.k
```

**Test Template**:
```kcl
"""
<Feature> Composition Test

Validates the terraform-aws-modules/vpc "<scenario>" example:
- <Expected behavior 1>
- <Expected behavior 2>
- <Expected behavior 3>

Spec: References terraform-vpc-analysis.md section <X>
"""

import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-<feature>"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define test input (XR)
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "XVPC"
                metadata.name: "test-vpc"
                spec: {
                    region: "us-west-2"
                    # ... test inputs
                }
            }

            # Assert expected resources
            assertResources: [
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "<ResourceKind>"
                    metadata.name: "<expected-name>"
                    spec.forProvider: {
                        # Assert all critical fields
                        field1: "expectedValue"
                        field2: true
                        # ...
                    }
                },
                # More resources...
            ]
        }
    }
]
items= _items
```

#### Step 3: Run Test (Should FAIL)

```bash
up test run tests/test-xvpc-<feature>

# Expected output:
# ❌ FAIL: test-xvpc-<feature>
# Reason: Resource not found / Field mismatch / etc.
```

**Important**: If test passes immediately, your test is wrong! Fix the test.

#### Step 4: Implement Minimum Code (GREEN)

```bash
# Edit appropriate module
# - functions/vpc/main.k (simple features)
# - functions/vpc/<module>.k (complex features)

# Follow existing patterns
# Keep it simple
# Only add what's needed to pass test
```

#### Step 5: Run Test Until Green

```bash
# Run specific test
up test run tests/test-xvpc-<feature>

# Debug if failing
# - Check generated resources
# - Verify field values
# - Check for typos

# Iterate until:
# ✅ PASS: test-xvpc-<feature>
```

#### Step 6: Run ALL Tests (No Regressions)

```bash
# Run all composition tests
up test run tests/test-*

# MUST see:
# ✅ PASS: test-xvpc-basic
# ✅ PASS: test-xvpc-public-subnets
# ✅ PASS: test-xvpc-<feature>
# ✅ PASS: ... (all other tests)

# If ANY test fails:
# - Fix the regression
# - Don't proceed until all green
```

#### Step 7: Refactor (REFACTOR)

```bash
# Improve code quality
# - Extract to separate module if needed
# - Reduce duplication
# - Improve naming
# - Add documentation

# After each change, run tests:
up test run tests/test-*

# Tests must stay green during refactoring
```

#### Step 8: Commit (Only When Green)

```bash
# Final check
up project build                  # ✅ Must pass
up test run tests/test-*          # ✅ All must pass

# Commit
git add .
git commit -m "feat: implement <feature>

- Add composition test for <feature>
- Implement <feature> in functions/vpc/<module>.k
- All tests passing
"

git push
```

#### Step 9: Write E2E Test (Critical Features Only)

```bash
# For critical features (NAT, routing, complete VPC):
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Edit: tests/e2etest-xvpc-<feature>/main.k
# - Use real AWS resources
# - Set realistic timeout (1800 seconds)
# - Add ProviderConfig with IAM role
# - Set skipDelete: False

# Run locally (requires up login)
up test run tests/e2etest-xvpc-<feature> --e2e

# Or in CI with label: "run-e2e-tests"
```

## Test Organization

### Directory Structure

```
tests/
├── test-xvpc-basic/              # VPC creation
├── test-xvpc-public-subnets/     # Public subnets
├── test-xvpc-private-subnets/    # Private subnets
├── test-xvpc-database-subnets/   # Database subnets
├── test-xvpc-igw/                # Internet Gateway
├── test-xvpc-nat-single/         # Single NAT Gateway
├── test-xvpc-nat-per-az/         # NAT per AZ
├── test-xvpc-nat-disabled/       # No NAT Gateway
├── test-xvpc-routes-public/      # Public routing
├── test-xvpc-routes-private/     # Private routing
├── test-xvpc-routes-isolated/    # Isolated routing
├── test-xvpc-endpoints-gateway/  # Gateway endpoints
├── test-xvpc-endpoints-interface/# Interface endpoints
├── test-xvpc-nacl/               # Network ACLs
├── test-xvpc-dhcp/               # DHCP options
├── test-xvpc-flowlogs-cw/        # Flow logs CloudWatch
├── test-xvpc-flowlogs-s3/        # Flow logs S3
├── test-xvpc-secondary-cidr/     # Secondary CIDRs
├── test-xvpc-ipv6/               # IPv6 support
├── test-xvpc-vpn/                # VPN Gateway
├── e2etest-xvpc-basic/           # E2E: Basic VPC
├── e2etest-xvpc-nat/             # E2E: VPC with NAT
└── e2etest-xvpc-complete/        # E2E: All features
```

### Naming Convention

**Composition Tests**:
```
test-xvpc-<feature>[-<variant>]

Examples:
- test-xvpc-basic
- test-xvpc-nat-single
- test-xvpc-routes-private
```

**E2E Tests**:
```
e2etest-xvpc-<scenario>

Examples:
- e2etest-xvpc-basic
- e2etest-xvpc-complete
```

## Test Content Standards

### 1. Documentation

Every test MUST have clear documentation:

```kcl
"""
<Feature> Composition Test

Validates the terraform-aws-modules/vpc "<terraform-example>" scenario:
- <Specific behavior 1>
- <Specific behavior 2>
- <Specific behavior 3>

Spec: This validates <test case name> from terraform-vpc-analysis.md

Reference:
- Terraform example: https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples/<example>
"""
```

### 2. Complete Assertions

Test ALL critical fields:

```kcl
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        metadata.name: "subnet-public-test-vpc-us-west-2a"
        spec.forProvider: {
            # ✅ Assert all critical fields
            vpcIdSelector.matchControllerRef: True
            region: "us-west-2"
            availabilityZone: "us-west-2a"
            cidrBlock: "10.0.1.0/24"
            mapPublicIpOnLaunch: True
            tags: {
                Environment: "test"
                Type: "public"
            }
        }
    }
]
```

### 3. Realistic Inputs

Use inputs that match real-world usage:

```kcl
xr: {
    spec: {
        region: "us-west-2"
        cidr: "10.0.0.0/16"
        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
        privateSubnets: ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
        # ... realistic configuration
    }
}
```

### 4. Edge Cases

Test edge cases and boundary conditions:

```
- Zero subnets
- One subnet
- Many subnets (10+)
- Single AZ
- Many AZs (6)
- Minimal config
- Maximum config
- Conditional features (enabled/disabled)
```

## Feature Parity Validation

### Input Validation

For each Terraform input variable, we MUST:

1. **Map to XRD field** (documented in ARCHITECTURE.md)
2. **Write test** validating the mapping
3. **Implement** in composition
4. **Verify** behavior matches Terraform

### Output Validation

For each Terraform output, we MUST:

1. **Add to XRD status fields**
2. **Write test** asserting output is set
3. **Implement** status patching
4. **Verify** matches Terraform output

### Behavior Validation

E2E tests validate behavior:

```bash
# Deploy same config with Terraform
cd terraform-test/
terraform apply -var-file=test.tfvars

# Capture outputs
terraform output -json > terraform-outputs.json

# Deploy with Upbound
kubectl apply -f upbound-test.yaml

# Wait for ready
kubectl wait --for=condition=Ready xvpc/test-vpc

# Capture outputs
kubectl get xvpc test-vpc -o json | jq '.status' > upbound-outputs.json

# Compare
diff terraform-outputs.json upbound-outputs.json
# Should be identical (except resource IDs)
```

## CI/CD Integration

### Composition Tests (Every PR)

```yaml
# .github/workflows/composition-test.yaml
- name: Run Composition Tests
  run: up test run tests/test-*

# MUST pass for PR to merge
```

### E2E Tests (Labeled PRs)

```yaml
# .github/workflows/e2e.yaml
# Triggered by label: "run-e2e-tests"
- name: Run E2E Tests
  run: up test run tests/e2etest-* --e2e

# SHOULD pass for production releases
```

## Common Pitfalls

### ❌ Don't: Write Code Before Tests

```bash
# ❌ WRONG
# 1. Write implementation
# 2. Write tests after

# ✅ CORRECT
# 1. Write test first
# 2. Watch it fail
# 3. Implement feature
# 4. Watch it pass
```

### ❌ Don't: Skip Tests for "Simple" Features

```bash
# ❌ WRONG: "It's just one field, no test needed"

# ✅ CORRECT: Every feature has a test
up test generate test-xvpc-<even-simple-feature> --language=kcl
```

### ❌ Don't: Commit Failing Tests

```bash
# ❌ WRONG
git commit -m "feat: work in progress (tests failing)"

# ✅ CORRECT
# Fix tests first, then commit
```

### ❌ Don't: Write Tests After Implementation

```bash
# ❌ WRONG
git commit -m "feat: implement NAT gateway"
git commit -m "test: add tests for NAT gateway"  # Too late!

# ✅ CORRECT
git commit -m "feat: implement NAT gateway

- Add composition test for NAT gateway
- Implement NAT gateway generation
- All tests passing
"
```

### ❌ Don't: Test Implementation Details

```bash
# ❌ WRONG: Testing internal functions
test "_generateSubnets() returns list"

# ✅ CORRECT: Test observable behavior
test "public subnets created with correct specs"
```

## Test Coverage Goals

### Phase 1: Foundation
- ✅ test-xvpc-basic (VPC creation)
- ✅ test-xvpc-public-subnets
- ✅ test-xvpc-private-subnets
- ✅ test-xvpc-igw

### Phase 2: Core Features
- ✅ test-xvpc-nat-single
- ✅ test-xvpc-nat-per-az
- ✅ test-xvpc-routes-public
- ✅ test-xvpc-routes-private
- ✅ e2etest-xvpc-basic (E2E)

### Phase 3: Enhanced Features
- ✅ test-xvpc-database-subnets
- ✅ test-xvpc-endpoints-gateway
- ✅ test-xvpc-nacl
- ✅ test-xvpc-flowlogs-cw
- ✅ e2etest-xvpc-complete (E2E)

### Phase 4: Advanced Features
- ✅ test-xvpc-ipv6
- ✅ test-xvpc-vpn
- ✅ test-xvpc-secondary-cidr

## Success Metrics

### Code Coverage
- ✅ 100% of features have composition tests
- ✅ 100% of critical paths have E2E tests
- ✅ All tests documented with expected behavior

### Test Health
- ✅ All tests pass before every commit
- ✅ No flaky tests (99.9% pass rate)
- ✅ Fast tests (< 10s per composition test)
- ✅ E2E tests clean up resources (no orphans)

### Feature Parity
- ✅ All Terraform inputs tested
- ✅ All Terraform outputs tested
- ✅ Side-by-side validation passes
- ✅ Behavior matches Terraform module

## Quick Reference

### Generate Test
```bash
# Composition test
up test generate test-xvpc-<feature> --language=kcl

# E2E test
up test generate e2etest-xvpc-<scenario> --e2e --language=kcl
```

### Run Tests
```bash
# Single test
up test run tests/test-xvpc-<feature>

# All composition tests
up test run tests/test-*

# All E2E tests (requires up login)
up test run tests/e2etest-* --e2e

# Specific E2E test
up test run tests/e2etest-xvpc-basic --e2e
```

### Debugging Tests
```bash
# Build project first
up project build

# Run test with verbose output
up test run tests/test-xvpc-<feature> -v

# Check generated resources
cat .upbound/build/debug/<test-name>/resources.yaml
```

## Resources

- [Testing Guide](../tools/testing-guide.md)
- [Testing Patterns](../tools/testing-kcl-patterns.md)
- [Platform Ref Examples](../tools/testing-notes-platform-ref.md)
- [E2E Test Setup](../tools/e2e-test-control-plane-setup.md)
- [Architecture Guide](ARCHITECTURE.md)

---

**Remember**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → ✅ COMMIT

**Never commit failing tests. Never write code before tests.**
