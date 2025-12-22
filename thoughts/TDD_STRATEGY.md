# Test-Driven Development (TDD) Strategy

## Related Documentation

This document covers TDD workflow and strategy. For technical testing details, see [TESTING_REFERENCE.md](TESTING_REFERENCE.md).

For related topics, see:
- **Test Schemas & Patterns**: [TESTING_REFERENCE.md](TESTING_REFERENCE.md)
- **up CLI Commands**: [UPBOUND_REFERENCE.md → Testing Commands](UPBOUND_REFERENCE.md#testing)
- **Git Workflows**: [GIT_WORKFLOW.md → Making Commits](GIT_WORKFLOW.md#3-making-commits)

---

## Overview

This project follows **strict Test-Driven Development (TDD)** practices. Tests are written **BEFORE** implementation code, and **all tests must pass before committing**.

## Core TDD Principle

```
🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT
```

1. **🔴 RED**: Write a failing composition test (work locally, don't commit)
2. **🟢 GREEN**: Write minimum code to pass (work locally, don't commit)
3. **🔵 REFACTOR**: Improve code while keeping tests green (work locally, don't commit)
4. **🧪 E2E TEST**: Write and pass E2E test (MANDATORY - 30-40 min)
5. **✅ COMMIT**: Only commit when ALL tests pass (composition + E2E)

**CRITICAL**: E2E tests are MANDATORY before ANY commit. A feature is NOT done until it's validated in real AWS.

**Commit Strategy**:
- ✅ **DO**: Work locally through steps 1-4 without committing
- ✅ **DO**: Run E2E test before ANY commit (30-40 minutes)
- ✅ **DO**: Commit ONLY after E2E passes
- ❌ **DON'T**: Commit "work in progress" without E2E validation
- ❌ **DON'T**: Make incremental commits during development
- ❌ **DON'T**: Skip E2E tests to "commit small increments"

**Rationale**: Every commit in git history must be E2E validated. This ensures production quality at every point in history.

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

**When to Write**: **BEFORE implementing ANY feature** (🔴 RED → 🟢 GREEN → 🔵 REFACTOR)

**Example**: Test for public subnets → Assert 2 subnets with correct CIDRs → Test fails → Implement feature → Test passes

### Level 2: Integration Tests - SOME TESTS

**Purpose**: Validate multiple modules working together

**Example**: Routes + Route Tables + Subnets integration

**When to Write**: After implementing related features

### Level 3: E2E Tests - MANDATORY FOR ALL FEATURES

**Purpose**: Validate in real AWS environment

**Characteristics**:
- 🐌 Slow (30-40 minutes) - this is expected and acceptable
- 💰 Minimal cost (real AWS resources, but test duration is intentional)
- 🌐 Complete (full lifecycle)
- ✅ Final validation
- 🔒 **NO AWS credentials needed** - uses Upbound web identity federation

**When to Write**: After composition tests pass, for ALL major features

**Authentication**: See [TESTING_REFERENCE.md](TESTING_REFERENCE.md) for complete E2E testing guide.

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

**Test Structure** (see [TESTING_REFERENCE.md → Complete Composition Test Example](TESTING_REFERENCE.md#complete-composition-test-example) for full template):
```kcl
metav1alpha1.CompositionTest{
    metadata.name: "test-xvpc-<feature>"
    spec= {
        compositionPath: "../../apis/vpc/composition.yaml"
        xr: { /* test input */ }
        assertResources: [ /* expected managed resources */ ]
    }
}
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

#### Step 8: Write E2E Test (MANDATORY)

```bash
# Generate E2E test
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Run locally
up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing
```

**See [TESTING_REFERENCE.md → E2E Tests](TESTING_REFERENCE.md#e2e-tests) for complete E2E test setup, test duration expectations, ProviderConfig configuration, and authentication details.**

#### Step 9: Commit (Only When ALL Tests Pass)

**Work Locally (Steps 1-8)**: Do NOT commit until E2E passes:
```bash
# Work through RED → GREEN → REFACTOR locally
# Run composition tests as you go: up test run tests/test-*
# But do NOT commit yet

# Step 8: Run E2E test (MANDATORY - 30-40 minutes)
up test run tests/e2etest-xvpc-<feature> --e2e

# ✅ E2E test MUST pass before ANY commit
```

**Commit ONLY After E2E Passes**:
```bash
# All tests passed (composition + E2E) - NOW commit
git add .
git commit -m "feat: implement <feature>

- Add composition test for <feature>
- Implement <feature> in functions/vpc/
- Add E2E test validating real AWS behavior
- All tests passing (17 composition + 1 E2E)
"

git push
```

**MANDATORY CHECKS BEFORE ANY COMMIT**:
- ✅ Project builds: `up project build`
- ✅ All composition tests pass: `up test run tests/test-*`
- ✅ E2E test passes: `up test run tests/e2etest-* --e2e` (30-40 minutes)
- ✅ No AWS resources orphaned (verify cleanup)
- ✅ Documentation updated

**Key Principle**: DO NOT commit until E2E test passes. Every commit in git history must be E2E validated.

## Test Organization

**For complete test organization, directory structure, and naming conventions, see [TESTING_REFERENCE.md → Test Organization](TESTING_REFERENCE.md#test-organization)**

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

Test ALL critical fields in assertResources.

**See [TESTING_REFERENCE.md → Key Learnings](TESTING_REFERENCE.md#key-learnings) for complete assertResources syntax, common mistakes, and detailed examples.**

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

**For detailed success metrics and validation criteria, see [TESTING_REFERENCE.md → Success Metrics](TESTING_REFERENCE.md#success-metrics)**

---

## CI/CD Integration

**For complete CI/CD workflows, GitHub Actions configuration, local testing commands, and cost considerations, see [TESTING_REFERENCE.md → CI/CD Integration](TESTING_REFERENCE.md#cicd-integration)**

**Quick reference**:
- **Composition tests**: Run on every PR (fast, free)
- **E2E tests**: Run with "run-e2e-tests" label (slow, creates real AWS resources)
- **Local testing**: `up test run tests/test-*` before every commit

---

## Quick Reference

> 📖 **Command Syntax**: See [TESTING_REFERENCE.md](TESTING_REFERENCE.md) and [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md) for complete command reference

**Essential Commands**:
```bash
up test generate test-xvpc-<feature> --language=kcl    # Generate composition test
up test run tests/test-*                                # Run all composition tests
up test run tests/e2etest-* --e2e                       # Run all E2E tests
```

## Related Documentation

- **Commands**: [UPBOUND_REFERENCE.md → Quick Reference](UPBOUND_REFERENCE.md#quick-reference) - Complete `up` CLI reference
- **Git Workflow**: [GIT_WORKFLOW.md → Making Commits](GIT_WORKFLOW.md#3-making-commits) - TDD commit workflow
- **Implementation**: [IMPLEMENTATION_GUIDE.md → Architecture](IMPLEMENTATION_GUIDE.md#architecture-overview) - Architecture and patterns
- **Specification**: [SPECIFICATION.md](SPECIFICATION.md) - Feature requirements

---

**Remember**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**Key Principles**:
- Work locally through RED → GREEN → REFACTOR without committing
- Run E2E test before ANY commit (30-40 minutes)
- Commit ONLY when all tests pass (composition + E2E)
- Never commit without E2E validation
- Never write code before tests
- Every commit in git history must be production-ready and E2E validated
