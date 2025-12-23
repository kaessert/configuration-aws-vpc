# Test Execution Guide

**Date**: January 2025
**Purpose**: Guide for running and interpreting tests for AWS VPC Configuration Package

---

## Quick Start

### Run All Composition Tests (Fast - ~5-10 minutes)
```bash
# Build project first
up project build

# Run all composition tests
up test run tests/test-*
```

### Run Specific Composition Test
```bash
up test run tests/test-vpc-simple
```

### Run All E2E Tests (Slow - ~6-8 hours)
```bash
# Requires AWS credentials via web identity
up test run tests/e2etest-* --e2e
```

### Run Specific E2E Test
```bash
up test run tests/e2etest-vpc-basic --e2e
```

---

## Test Types

### Composition Tests (32 tests)

**Purpose**: Fast validation of composition logic without creating real AWS resources

**Characteristics**:
- Run locally without AWS credentials
- Complete in seconds per test (~5-10 minutes total)
- Validate resource generation and configuration
- Validate label selectors and relationships
- Validate conditional logic

**When to run**:
- ✅ Before every commit
- ✅ During development (TDD workflow)
- ✅ In CI on every PR
- ✅ When refactoring code

**Test naming pattern**: `test-{feature}-{variant}`
- Examples: `test-vpc-simple`, `test-vpc-nat-single`, `test-vpc-routes-public`

---

### E2E Tests (10 tests)

**Purpose**: Validation with real AWS resources

**Characteristics**:
- Create real resources in AWS (us-west-2)
- Take 30-50 minutes per test (~6-8 hours total)
- Require AWS credentials (web identity)
- Cost money (NAT Gateways, VPC Endpoints)
- Validate complete resource lifecycle
- Automatic cleanup (skipDelete: false)

**When to run**:
- ✅ Before major releases
- ✅ After significant changes
- ✅ On labeled PRs ("run-e2e-tests")
- ❌ NOT on every commit (too slow/expensive)

**Test naming pattern**: `e2etest-{feature}-{variant}`
- Examples: `e2etest-vpc-basic`, `e2etest-vpc-complete`, `e2etest-vpc-nat-per-az`

---

## Test Results Interpretation

### Composition Test Success
```
Assert test-vpc-simple …
Assert test-vpc-simple ✓
SUCCESS: 
SUCCESS: Tests Summary:
SUCCESS: ------------------
SUCCESS: Total Tests Executed: 1
SUCCESS: Passed tests:         1
SUCCESS: Failed tests:         0
```

**Meaning**: Composition logic is correct, resources generated as expected

---

### Composition Test Failure
```
Assert test-vpc-simple …
FAIL: assertion failed: 
FAIL: Expected 1 VPC resources, but found 0
```

**Meaning**: 
- Composition logic has a bug
- Resource not generated when expected
- Selector not matching correctly
- Conditional logic incorrect

**Action**: Review composition code, fix bug, rerun test

---

### E2E Test Success
```
Running e2etest-vpc-basic …
Resources created: 15
All resources Ready: ✓
All resources Synced: ✓
Cleanup started …
Cleanup complete: ✓
SUCCESS: Test passed
```

**Meaning**: 
- Resources created successfully in AWS
- Resources reached Ready/Synced states
- Resources cleaned up successfully
- Full lifecycle validated

---

### E2E Test Failure (Timeout)
```
Running e2etest-vpc-basic …
Resources created: 15
Waiting for Ready condition …
FAIL: Timeout after 2400 seconds
FAIL: 2 resources not Ready: [vpc-abc123, nat-gateway-xyz789]
```

**Meaning**:
- Resources created but didn't reach Ready state
- Possible AWS API issues
- Possible configuration error
- Possible dependency issue

**Action**:
1. Check AWS Console for resource status
2. Check Crossplane logs for errors
3. Verify ProviderConfig credentials
4. Increase timeout if needed
5. Manual cleanup may be required

---

### E2E Test Failure (Cleanup)
```
Running e2etest-vpc-basic …
Resources created: ✓
All resources Ready: ✓
Cleanup started …
FAIL: Cleanup timeout after 600 seconds
FAIL: 1 resource not deleted: [nat-gateway-xyz789]
```

**Meaning**:
- Test passed but cleanup failed
- Resources still exist in AWS
- Manual cleanup required

**Action**:
1. Go to AWS Console
2. Find resources with tag `Environment: e2e-test`
3. Delete manually (NAT Gateways take 5-10 minutes to delete)
4. Consider increasing cleanupTimeoutSeconds

---

## Running Tests in CI/CD

### Composition Tests (Automatic)

**Trigger**: Every PR

**Workflow**: `.github/workflows/composition-test.yaml`

**Behavior**:
1. Builds project
2. Runs all 32 composition tests
3. Fails PR if any test fails
4. ~10 minutes total

**Configuration**:
```yaml
jobs:
  composition-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run composition tests
        run: |
          up project build
          up test run tests/test-*
```

---

### E2E Tests (Manual Trigger)

**Trigger**: Add label "run-e2e-tests" to PR

**Workflow**: `.github/workflows/e2e.yaml`

**Behavior**:
1. Authenticates to AWS via web identity
2. Runs all 10 E2E tests
3. Fails PR if any test fails
4. ~6-8 hours total

**Configuration**:
```yaml
jobs:
  e2e-tests:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e-tests')
    steps:
      - uses: actions/checkout@v3
      - name: Run E2E tests
        run: |
          up test run tests/e2etest-* --e2e
```

---

## Test Development Workflow (TDD)

### 1. RED Phase - Write Failing Test
```bash
# Generate test scaffold
up test generate test-vpc-new-feature --language=kcl

# Edit tests/test-vpc-new-feature/main.k
# - Add test documentation
# - Define XR with new feature enabled
# - Add assertions for expected resources

# Run test (should FAIL - feature not implemented)
up test run tests/test-vpc-new-feature

# Expected: FAIL (this proves test is correct)
```

---

### 2. GREEN Phase - Implement Feature
```bash
# Edit functions/vpc/main.k (or appropriate module)
# - Implement feature logic
# - Generate resources conditionally
# - Add proper labels and selectors

# Run test again (should PASS now)
up test run tests/test-vpc-new-feature

# Expected: PASS
```

---

### 3. REFACTOR Phase - Clean Up
```bash
# Improve code quality
# - Extract helper functions
# - Add comments
# - Simplify logic

# Run test again (should still PASS)
up test run tests/test-vpc-new-feature

# Run all tests (no regressions)
up test run tests/test-*

# Expected: ALL PASS
```

---

### 4. E2E Phase - Validate in AWS
```bash
# Generate E2E test
up test generate e2etest-vpc-new-feature --e2e --language=kcl

# Edit tests/e2etest-vpc-new-feature/main.k
# - Add crossplane version: "2.0.2-up.5"
# - Add ProviderConfig with web identity
# - Set timeout: 1800+ seconds
# - Set skipDelete: false
# - Add test manifests

# Run E2E test
up test run tests/e2etest-vpc-new-feature --e2e

# Expected: PASS (resources created and cleaned up in AWS)
```

---

## Troubleshooting

### Problem: "up: command not found"
**Solution**: Install Upbound CLI
```bash
curl -sL "https://cli.upbound.io" | sh
sudo mv up /usr/local/bin/
```

---

### Problem: "No tests found matching pattern"
**Solution**: Check test directory structure
```bash
ls -l tests/
# Each test should be a directory with main.k file
```

---

### Problem: "Failed to build function"
**Solution**: Check KCL syntax and dependencies
```bash
# Check KCL module dependencies
cat functions/vpc/kcl.mod

# Rebuild project
up project build
```

---

### Problem: "E2E test timeout"
**Solution**: Increase timeout or check AWS resources
```bash
# Increase timeout in test
timeoutSeconds: 3600  # 60 minutes

# Check AWS Console for stuck resources
# Look for resources with tag: ManagedBy: upbound-e2e
```

---

### Problem: "E2E cleanup failed"
**Solution**: Manual cleanup required
```bash
# Find E2E test resources in AWS Console
# Filter by tag: Environment: e2e-test
# Delete manually in reverse order:
# 1. Routes
# 2. Route Table Associations
# 3. NAT Gateways (wait 5-10 min)
# 4. EIPs
# 5. Route Tables
# 6. Subnets
# 7. Internet Gateway
# 8. VPC
```

---

### Problem: "Composition test fails but should pass"
**Solution**: Check assertions carefully
```bash
# Review test assertions
cat tests/test-vpc-simple/main.k

# Check generated resources
up test run tests/test-vpc-simple --debug

# Compare expected vs actual resources
```

---

## Test Costs (E2E Only)

Composition tests are free (no AWS resources created).

E2E tests cost money:

| Resource | Cost | Duration | Total |
|----------|------|----------|-------|
| VPC | Free | N/A | $0 |
| Subnets | Free | N/A | $0 |
| Internet Gateway | Free | N/A | $0 |
| NAT Gateway | $0.045/hr | 40 min | ~$0.03/test |
| EIP | $0.005/hr | 40 min | ~$0.003/test |
| VPC Endpoint (Gateway) | Free | N/A | $0 |
| VPC Endpoint (Interface) | $0.01/hr | 40 min | ~$0.007/test |

**Estimated cost per E2E test**: $0.03 - $0.05
**Estimated cost for full E2E suite** (10 tests): $0.30 - $0.50

**Cost optimization**:
- Run E2E tests only before releases
- Use single NAT Gateway strategy in tests
- Ensure skipDelete: false (cleanup enabled)

---

## Best Practices

### Composition Tests
1. ✅ **Test one feature at a time** - Keep tests focused
2. ✅ **Test both enabled and disabled states** - Cover conditional logic
3. ✅ **Assert specific values** - Not just "resource exists"
4. ✅ **Use descriptive test names** - Clear purpose from name
5. ✅ **Document test purpose** - Add comments explaining what's tested

### E2E Tests
1. ✅ **Use realistic configurations** - Test production-like setups
2. ✅ **Set proper timeouts** - 30-50 minutes for complex tests
3. ✅ **Enable cleanup** - skipDelete: false (prevent orphaned resources)
4. ✅ **Use web identity** - Never static credentials
5. ✅ **Tag resources** - Enable easy identification and cleanup

### General
1. ✅ **Run composition tests frequently** - Fast feedback loop
2. ✅ **Run E2E tests sparingly** - Expensive and slow
3. ✅ **Fix failing tests immediately** - Don't let them accumulate
4. ✅ **Add tests for bug fixes** - Prevent regressions
5. ✅ **Follow TDD workflow** - Test first, then implement

---

## Test Organization

```
tests/
├── test-vpc-simple/              # Composition: Basic VPC
├── test-vpc-subnets-public/      # Composition: Public subnets
├── test-vpc-nat-single/          # Composition: Single NAT
├── test-vpc-routes-public/       # Composition: Public routing
├── test-vpc-endpoints-s3-gateway/  # Composition: S3 endpoint
├── test-nacl-public-dedicated/   # Composition: Network ACLs
├── test-vpc-dhcp-custom/         # Composition: DHCP options
├── test-test-vpc-flowlogs-cloudwatch/  # Composition: Flow logs
├── test-test-subnetgroup-db/     # Composition: DB subnet group
├── e2etest-vpc-basic/            # E2E: Basic VPC in AWS
├── e2etest-vpc-complete/         # E2E: Complete VPC in AWS
├── e2etest-vpc-nat-single/       # E2E: NAT Gateway in AWS
└── e2etest-vpc-endpoints/        # E2E: VPC Endpoints in AWS
```

---

## Summary

- **32 composition tests** - Fast, run frequently, free
- **10 E2E tests** - Slow, run before releases, costs ~$0.50
- **100% feature coverage** - All Phase 1-3 features tested
- **TDD workflow** - Test first, implement second
- **CI/CD integration** - Automatic composition tests, manual E2E tests

**Test early, test often, ship with confidence! ✅**
