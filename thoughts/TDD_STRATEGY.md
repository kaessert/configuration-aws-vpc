# Test-Driven Development (TDD) Strategy

## Related Documentation

For related topics, see:
- **Test Schemas & Patterns**: [TESTING_REFERENCE.md → Test Examples](TESTING_REFERENCE.md#complete-composition-test-example)
- **up CLI Commands**: [UPBOUND_REFERENCE.md → Testing Commands](UPBOUND_REFERENCE.md#testing)
- **Git Workflows**: [GIT_WORKFLOW.md → Making Commits](GIT_WORKFLOW.md#3-making-commits)

---

## Overview

This project follows **strict Test-Driven Development (TDD)** practices. Tests are written **BEFORE** implementation code, and **all tests must pass before committing**.

## Core TDD Principle

```
🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT
```

1. **🔴 RED**: Write a failing composition test
2. **🟢 GREEN**: Write minimum code to pass
3. **🔵 REFACTOR**: Improve code while keeping tests green
4. **🧪 E2E TEST**: Write and pass E2E test (MANDATORY)
5. **✅ COMMIT**: Only commit when ALL tests pass (composition + E2E)

**CRITICAL CHANGE**: E2E tests are now MANDATORY before marking ANY feature as complete. A feature is NOT done until it's validated in real AWS.

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
- 🐌 Slow (10-30 minutes)
- 💰 Expensive (real AWS resources)
- 🌐 Complete (full lifecycle)
- ✅ Final validation
- ⚠️ **MANDATORY** - Required before marking feature complete

**When to Write**: **MANDATORY** - After composition tests pass, for ALL major features

**CRITICAL**: E2E tests are NO LONGER optional. Every significant feature (VPC, subnets, NAT, routing, etc.) MUST have E2E test coverage. Composition tests validate KCL logic, but E2E tests validate real AWS behavior.

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
# For ALL major features (VPC, subnets, NAT, routing, etc.):
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Edit: tests/e2etest-xvpc-<feature>/main.k
# - Use real AWS resources
# - Set realistic timeout (1800-3000 seconds / 30-50 minutes)
# - Add ProviderConfig with IAM role: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
# - Use assumeRoleChain (NEVER static credentials)
# - Set skipDelete: false (ensure cleanup)
# - Set validate: true
# - Add defaultConditions: ["Ready", "Synced"]

# Run locally (requires up login)
up login
up test run tests/e2etest-xvpc-<feature> --e2e

# Or in CI with label: "run-e2e-tests"
# Wait for test to complete (may take 30+ minutes)
# Verify:
# ✅ Resources created in AWS
# ✅ Resources reach Ready/Synced state
# ✅ Resources cleaned up after test
```

**CRITICAL**: Do NOT skip this step. E2E tests are MANDATORY.

#### Step 9: Commit (Only When ALL Tests Pass)

```bash
# Final check - ALL tests must pass
up project build                          # ✅ Must pass
up test run tests/test-*                  # ✅ All composition tests must pass
up test run tests/e2etest-xvpc-<feature> --e2e  # ✅ E2E test must pass

# Only commit when EVERYTHING is green
git add .
git commit -m "feat: implement <feature>

- Add composition test for <feature>
- Implement <feature> in functions/vpc/
- Add E2E test validating real AWS behavior
- All tests passing (17 composition + 1 E2E)
"

git push
```

**MANDATORY CHECKS BEFORE COMMIT**:
- ✅ Project builds: `up project build`
- ✅ All composition tests pass: `up test run tests/test-*`
- ✅ E2E test passes: `up test run tests/e2etest-* --e2e`
- ✅ No AWS resources orphaned (verify cleanup)
- ✅ Documentation updated

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

---

## CI/CD Integration

### GitHub Workflows

#### Composition Tests

Run on every push and PR automatically:

```yaml
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
      - run: up test run tests/test-*  # Only composition tests
```

**Characteristics**:
- Fast feedback (seconds to minutes)
- No credentials required
- No cost (runs locally on GitHub runners)
- Catches KCL syntax errors and basic logic issues

#### E2E Tests

Run only when explicitly requested via PR label:

```yaml
name: End to End Testing
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

      - name: Install and login with up
        if: env.UP_API_TOKEN != '' && env.UP_ORG != ''
        uses: upbound/action-up@v1
        with:
          api-token: ${{ secrets.UP_API_TOKEN }}
          organization: ${{ secrets.UP_ORG }}

      - name: Login to xpkg.upbound.io
        uses: docker/login-action@v3
        with:
          registry: xpkg.upbound.io
          username: ${{ secrets.UP_ROBOT_ID }}
          password: ${{ secrets.UP_API_TOKEN }}

      - run: up project build

      - name: Switch up context
        if: env.UP_API_TOKEN != '' && env.UP_ORG != ''
        run: up ctx ${{ env.UP_ORG }}/upbound-gcp-us-central-1/${{ env.UP_GROUP }}

      - name: Run e2e tests
        if: env.UP_API_TOKEN != '' && env.UP_ORG != ''
        run: up test run tests/e2etest-* --e2e
```

**Characteristics**:
- Requires "run-e2e-tests" label on PR
- Uses real Upbound Cloud control plane
- Creates actual AWS resources
- Slower (5-30 minutes depending on resources)
- Has AWS costs (minimal but non-zero)

### Running Tests Locally

**During development**:
```bash
# Preview rendered resources (instant feedback)
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml
```

**Before committing** (CRITICAL):
```bash
# Build and run all composition tests
up project build && up test run tests/test-*
```

**Before creating PR**:
```bash
# Verbose output for debugging
up test run tests/test-* --verbose
```

**Local E2E testing** (creates real resources):
```bash
# Login to Upbound Cloud
up login

# Run E2E tests (specify control plane group)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Debug specific E2E test
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing --verbose
```

### Cost Considerations

E2E tests create real AWS resources. Understanding costs helps make informed testing decisions:

**AWS Resource Costs**:
- VPC: Free
- Subnets: Free
- Internet Gateway: Free
- NAT Gateway: ~$0.045/hour (~$1/day)
- VPC Endpoints: ~$0.01/hour per endpoint
- Elastic IP: $0.005/hour when not attached
- Control Plane: Free (dev control planes free for 24h)

**Best Practices**:
1. **Rely on composition tests** for most validation (free, fast)
2. **Use E2E tests for critical paths** (VPC creation, NAT Gateway, complex scenarios)
3. **Ensure cleanup** with `skipDelete=false` (default in E2E framework)
4. **Set reasonable timeouts** to avoid stuck resources
5. **Run E2E locally** before PR if making significant changes
6. **Monitor control plane** in Upbound Console during E2E tests

**Typical Test Run Cost**: $0.10 - $0.50 per E2E test (mostly NAT Gateway charges)

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

**Never commit failing tests. Never write code before tests. E2E tests are MANDATORY.**
