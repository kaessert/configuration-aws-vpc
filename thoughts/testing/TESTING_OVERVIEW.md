# Testing Overview

## Introduction

This document provides a high-level overview of the testing strategy for the AWS VPC Configuration for Upbound project. It explains **why we test**, **what we test**, and **how we test**.

**For detailed guides**: See [Composition Testing](composition-testing.md) and [E2E Implementation Guide](e2e-implementation-guide.md)

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Pyramid](#test-pyramid)
3. [When to Write Each Test Type](#when-to-write-each-test-type)
4. [Testing Workflow](#testing-workflow)
5. [Test Organization](#test-organization)
6. [CI/CD Integration](#cicd-integration)
7. [Quick Reference](#quick-reference)

---

## Testing Philosophy

### Why We Test

**Problem**: Crossplane compositions are complex. A composition function transforms user inputs into dozens of cloud resources. Without tests:
- ❌ Bugs discovered late (in production!)
- ❌ Regressions go unnoticed
- ❌ Refactoring is risky
- ❌ Confidence is low

**Solution**: Comprehensive testing at multiple levels ensures correctness, catches regressions early, and enables confident refactoring.

### Our Testing Principles

1. **Test-Driven Development (TDD)**: Write tests BEFORE implementation
   - 🔴 RED: Write failing test
   - 🟢 GREEN: Make test pass
   - 🔵 REFACTOR: Improve code
   - 🧪 E2E: Validate in real AWS
   - ✅ COMMIT: When all tests pass

2. **Test Pyramid**: Many fast tests, few slow tests
   - Base: Composition tests (fast, many)
   - Top: E2E tests (slow, few, critical)

3. **Mandatory E2E Tests**: Every feature MUST have E2E validation
   - Composition tests validate KCL logic
   - E2E tests validate AWS behavior
   - Both are required!

4. **Fail Fast**: Run fast tests first, slow tests later
   - Composition tests run on every commit (<1 min)
   - E2E tests run on labeled PRs (20-40 min)

5. **Living Documentation**: Tests document how features work
   - Tests are executable specifications
   - Tests show expected behavior
   - Tests catch documentation drift

---

## Test Pyramid

Our testing strategy follows the test pyramid pattern:

```
        /\
       /E2E\       ← Few, slow, expensive
      /      \       Real AWS resources
     /--------\      20-40 minutes per test
    / Compo-  \   ← Many, fast, cheap
   /  sition   \    Local execution
  /    Tests    \   Seconds per test
 /______________\
```

### Layer 1: Composition Tests (Base)

**Purpose**: Validate KCL logic without cloud resources

**Characteristics**:
- ✅ **Fast**: Seconds per test
- ✅ **Free**: No cloud costs
- ✅ **Isolated**: No external dependencies
- ✅ **Many**: 10-20 tests per feature

**What they test**:
- Resource generation (correct number, types)
- Resource specifications (CIDR blocks, names, tags)
- Conditional logic (feature flags, strategies)
- Edge cases (single AZ, many AZs)
- Resource relationships (dependencies)

**When to run**: Every commit, every PR, local development

**Example**:
```bash
# Fast feedback (<1 minute for all tests)
up test run tests/test-*
```

**Read more**: [Composition Testing Guide](composition-testing.md)

---

### Layer 2: E2E Tests (Top)

**Purpose**: Validate complete lifecycle with real AWS resources

**Characteristics**:
- ⏱️ **Slow**: 20-40 minutes per test
- 💰 **Expensive**: Real cloud costs (~$0.10 per test)
- 🌐 **Integrated**: Tests full system (Crossplane + AWS)
- 📊 **Few**: 1-4 tests covering critical paths

**What they test**:
- Real AWS resource creation
- Resources reach Ready/Synced states
- Provider authentication (IAM role)
- Resource lifecycle (create → ready → delete)
- Cleanup verification (no orphaned resources)

**When to run**: Labeled PRs, before releases, manually

**Example**:
```bash
# Slow but thorough (20-40 minutes)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

**Read more**: [E2E Implementation Guide](e2e-implementation-guide.md) and [E2E Testing Reference](e2e-testing.md)

---

## When to Write Each Test Type

### Composition Tests → Write for EVERY feature

**Scenarios to test**:
- ✅ Basic configuration (minimal inputs)
- ✅ Full configuration (all options)
- ✅ Conditional logic (feature enabled/disabled)
- ✅ Strategy variations (single NAT vs per-AZ NAT)
- ✅ Edge cases (1 AZ vs 6 AZs)
- ✅ Invalid inputs (if validation allows)

**Example test matrix for NAT Gateway**:
- `test-xvpc-nat-disabled` - No NAT
- `test-xvpc-nat-single` - Single NAT
- `test-xvpc-nat-per-az` - NAT per AZ
- `test-xvpc-nat-multi-region` - Edge case

---

### E2E Tests → Write for CRITICAL paths

**Mandatory E2E tests**:
- ✅ Basic VPC (VPC + Subnets + IGW)
- ✅ VPC with NAT (single strategy)
- ✅ VPC with NAT per AZ (HA strategy)
- ✅ Complete VPC (all 6 subnet types)

**Optional E2E tests** (if time/budget permits):
- VPC with endpoints
- VPC with flow logs
- VPC with secondary CIDRs

**Rule of thumb**: If it costs money (NAT, endpoints) or is critical infrastructure (VPC, subnets), write E2E test.

---

## Testing Workflow

### Development Workflow (TDD)

```
1. Pick feature from tasks.md
2. 🔴 RED: Write composition test (MUST fail)
   └─> up test generate test-xvpc-<feature> --language=kcl
   └─> Edit main.k with assertions
   └─> up test run tests/test-xvpc-<feature>
   └─> ❌ FAIL (expected - feature not implemented)

3. 🟢 GREEN: Implement minimum code to pass
   └─> Edit functions/vpc/<feature>.k
   └─> up test run tests/test-xvpc-<feature>
   └─> ✅ PASS

4. 🔵 REFACTOR: Improve code quality
   └─> Extract to modules, improve clarity
   └─> up test run tests/test-*
   └─> ✅ ALL PASS (no regressions)

5. 🧪 E2E: Validate in real AWS
   └─> up test generate e2etest-xvpc-<feature> --e2e --language=kcl
   └─> Edit main.k with ProviderConfig
   └─> up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing
   └─> ⏰ Wait 20-40 minutes
   └─> ✅ PASS + cleanup verified

6. ✅ COMMIT: Only when ALL tests pass
   └─> up test run tests/test-*  (composition)
   └─> up test run tests/e2etest-* --e2e --control-plane-group=claude-testing  (E2E)
   └─> git commit -m "feat: implement <feature>"
```

---

### CI/CD Workflow

```
Developer Push
     │
     ├──> Composition Tests (automatic, fast)
     │     └─> ✅ PASS → Continue
     │     └─> ❌ FAIL → Block PR
     │
     ├──> PR Created
     │     └─> Code Review
     │
     ├──> Label PR: "run-e2e-tests"
     │     └─> E2E Tests (manual trigger, slow)
     │          └─> ✅ PASS → Ready to merge
     │          └─> ❌ FAIL → Fix and retry
     │
     └──> Merge to main
           └─> Deploy to production
```

**Key points**:
- Composition tests run automatically (fast, free)
- E2E tests run on label (slow, costs money)
- All tests must pass before merge

---

## Test Organization

### Directory Structure

```
tests/
├── test-xvpc-basic/                 # Composition: Basic VPC
│   ├── main.k
│   ├── kcl.mod
│   └── kcl.mod.lock
├── test-xvpc-subnets-public/        # Composition: Public subnets
│   └── main.k
├── test-xvpc-subnets-private/       # Composition: Private subnets
│   └── main.k
├── test-xvpc-nat-single/            # Composition: Single NAT
│   └── main.k
├── test-xvpc-nat-per-az/            # Composition: NAT per AZ
│   └── main.k
├── test-xvpc-routes/                # Composition: Routing
│   └── main.k
├── test-xvpc-complete/              # Composition: All features
│   └── main.k
│
├── e2etest-xvpc-basic/              # E2E: Basic VPC (real AWS)
│   └── main.k
├── e2etest-xvpc-nat-single/         # E2E: NAT (real AWS)
│   └── main.k
├── e2etest-xvpc-nat-per-az/         # E2E: NAT HA (real AWS)
│   └── main.k
└── e2etest-xvpc-complete/           # E2E: Complete (real AWS)
    └── main.k
```

### Naming Conventions

**Composition tests**: `test-<resource>-<variant>/`
- `test-xvpc-basic` - Minimal configuration
- `test-xvpc-nat-single` - Single NAT strategy
- `test-xvpc-nat-per-az` - Per-AZ NAT strategy

**E2E tests**: `e2etest-<resource>-<variant>/`
- `e2etest-xvpc-basic` - Basic VPC with real AWS
- `e2etest-xvpc-nat-single` - NAT with real AWS

**Consistent patterns**: Easy to find, understand purpose at a glance

---

## CI/CD Integration

### GitHub Actions Workflows

**Composition Tests** (run on every PR):

```yaml
name: Composition Tests
on: [push, pull_request]
jobs:
  composition-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          skip-login: true
      - run: up project build
      - run: up test run tests/test-*
```

**E2E Tests** (run on labeled PRs):

```yaml
name: E2E Tests
on:
  pull_request_target:
    types: [synchronize, labeled]
jobs:
  e2e:
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e-tests')
    runs-on: ubuntu-latest
    timeout-minutes: 120
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          api-token: ${{ secrets.UP_API_TOKEN }}
      - run: up project build
      - run: up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

**Best practices**:
- ✅ Composition tests: Always run (fast, free)
- ✅ E2E tests: Only on label (slow, costs money)
- ✅ Set timeout for E2E (2 hours max)
- ✅ Fail pipeline if any test fails
- ✅ Verify cleanup after E2E tests

---

## Quick Reference

### Commands

```bash
# Generate composition test
up test generate test-xvpc-<feature> --language=kcl

# Generate E2E test
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Run all composition tests (fast)
up test run tests/test-*

# Run specific composition test
up test run tests/test-xvpc-basic

# Run all E2E tests (slow, requires login)
up login
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Run specific E2E test
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing

# Build project (required before tests)
up project build
```

---

### Test Comparison

| Aspect | Composition Tests | E2E Tests |
|--------|-------------------|-----------|
| **Speed** | Seconds | 20-40 minutes |
| **Cost** | Free | ~$0.10 per test |
| **When to run** | Every commit | Labeled PRs, releases |
| **What they test** | KCL logic | AWS behavior |
| **Dependencies** | None | Upbound Cloud, AWS |
| **Number of tests** | Many (10-20 per feature) | Few (1-4 critical paths) |
| **Failure impact** | Fast feedback | Slow feedback |
| **Run in CI** | Always | On label only |

---

### Testing Checklist

**Before implementing a feature**:
- [ ] Read feature spec in terraform-vpc-analysis.md
- [ ] Identify test scenarios (basic, full, edge cases)
- [ ] Plan composition tests (5-10 tests per feature)
- [ ] Plan E2E test (1 test for critical path)

**During implementation (TDD)**:
- [ ] 🔴 Write composition test (must fail)
- [ ] 🟢 Implement feature (test passes)
- [ ] 🔵 Refactor (all tests still pass)
- [ ] 🧪 Write E2E test (must pass in real AWS)
- [ ] ✅ Commit (all tests passing)

**After implementation**:
- [ ] Run all composition tests (`up test run tests/test-*`)
- [ ] Run all E2E tests (`up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`)
- [ ] Verify AWS cleanup (no orphaned resources)
- [ ] Update tasks.md (mark complete)
- [ ] Update documentation (if behavior changed)

---

## Testing Strategy for This Project

### Current Status

**Implemented features** (Tasks 2.1-2.5):
- ✅ VPC creation
- ✅ Subnets (all types: public, private, database, elasticache, redshift, intra)
- ✅ Internet Gateway
- ✅ NAT Gateway (single and per-AZ strategies)
- ✅ Route tables and routing

**Tests created**:
- ✅ 17 composition tests (covering all features)
- ✅ 4 E2E tests (basic, NAT single, NAT per-AZ, complete)

**All tests passing**: ✅ Composition tests + ✅ E2E tests

---

### Phase-by-Phase Testing

**Phase 1 (Foundation)** - ✅ Complete:
- Project initialization
- XRD definition
- Function scaffold
- Basic composition test

**Phase 2 (Core VPC)** - ✅ Complete:
- Composition tests for each feature
- E2E tests for critical paths
- All tests passing

**Phase 3 (Enhanced Networking)** - 🔄 Next:
- VPC Endpoints tests
- Network ACLs tests
- DHCP Options tests
- Flow Logs tests
- Same pattern: composition + E2E

**Phase 4 (Advanced Features)** - ⏸️ Future:
- VPN Gateway tests
- IPv6 tests
- Transit Gateway tests

---

## Best Practices

### DO:
- ✅ **Write tests first** (TDD)
- ✅ **Test every feature** (composition tests)
- ✅ **Validate critical paths** (E2E tests)
- ✅ **Run tests frequently** (every code change)
- ✅ **Verify E2E cleanup** (no orphaned resources)
- ✅ **Update tests when features change**
- ✅ **Use IAM roles** (never static credentials)
- ✅ **Set appropriate timeouts** (NAT = 30 min)

### DON'T:
- ❌ **Skip tests** ("it's simple, no need for tests")
- ❌ **Write code before tests** (violates TDD)
- ❌ **Skip E2E tests** (mandatory for all features)
- ❌ **Forget cleanup verification** (cost risk!)
- ❌ **Commit failing tests** (fix first!)
- ❌ **Use static AWS credentials** (security risk!)
- ❌ **Run E2E on every commit** (too slow/expensive)

---

## Common Questions

### Q: Why both composition and E2E tests?

**A**: They test different things!
- **Composition tests**: Validate KCL logic (resource generation, conditional logic)
- **E2E tests**: Validate AWS behavior (resources actually work, lifecycle)

Both are required. Composition tests catch logic errors fast. E2E tests catch integration issues.

---

### Q: How many tests should I write?

**A**:
- **Composition tests**: 5-10 per feature (basic, full, conditional, edge cases)
- **E2E tests**: 1 per critical path (basic VPC, NAT, complete)

More composition tests (fast, free), fewer E2E tests (slow, expensive).

---

### Q: When should I run E2E tests?

**A**:
- **Local development**: After implementing feature, before PR
- **CI/CD**: On labeled PRs ("run-e2e-tests")
- **Before release**: Always run all E2E tests

NOT on every commit (too slow/expensive).

---

### Q: What if E2E test fails?

**A**:
1. Check test output for error message
2. Check Upbound Console (control plane → managed resources)
3. Check AWS Console (verify resources)
4. Check CloudTrail (permission issues)
5. Fix issue, re-run test
6. **Verify cleanup** (critical!)

See [E2E Testing Reference](e2e-testing.md) for troubleshooting guide.

---

### Q: How do I verify E2E cleanup?

**A**: Manually check AWS Console after test:
- VPCs: Filter by tags, should be EMPTY
- NAT Gateways: Should be EMPTY (expensive!)
- Elastic IPs: Should be EMPTY (billable)
- Subnets, IGW, Routes: Should be EMPTY

See [E2E Implementation Guide](e2e-implementation-guide.md) for verification checklist.

---

## See Also

- [Composition Testing](composition-testing.md) - Complete composition test guide
- [E2E Implementation Guide](e2e-implementation-guide.md) - Step-by-step E2E guide
- [E2E Testing Reference](e2e-testing.md) - Complete E2E documentation
- [TDD Strategy](../development/TDD_STRATEGY.md) - Test-driven development workflow
- [Architecture](../architecture/ARCHITECTURE.md) - System design and test hierarchy

---

## Summary

Testing is **essential** for building reliable infrastructure code. Our testing strategy uses:

**Test Pyramid**:
- Many fast composition tests (validate logic)
- Few slow E2E tests (validate AWS behavior)

**Test-Driven Development**:
- 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**Mandatory E2E Tests**:
- Every feature requires E2E validation
- Composition tests test logic
- E2E tests test reality

**Best Practices**:
- Write tests first (TDD)
- Run composition tests on every commit
- Run E2E tests on labeled PRs
- Verify cleanup after E2E tests
- Use IAM roles (never static credentials)

**Start here**:
- New to testing? Read [Composition Testing](composition-testing.md)
- Need to write E2E test? Read [E2E Implementation Guide](e2e-implementation-guide.md)
- Need TDD workflow? Read [TDD Strategy](../development/TDD_STRATEGY.md)
