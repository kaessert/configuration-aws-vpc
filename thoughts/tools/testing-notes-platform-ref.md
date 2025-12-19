# Testing Patterns from platform-ref-upbound

## Key Learnings from Upbound's Reference Platform

These notes document testing patterns observed in the [platform-ref-upbound](https://github.com/upbound/platform-ref-upbound) repository, which should be followed for consistency.

---

## Test Directory Structure

### Organization Pattern

Tests are organized by **resource type** with a naming convention:

```
tests/
├── test-xenvironment/                    # Basic XEnvironment tests
├── test-xenvironment-deletion-policy-delete/  # Variant test for deletion policies
├── test-xenvironment-no-cloudprovider-resource/  # Edge case test
├── test-xsharedawssecret/                # Basic SharedAWSSecret tests
├── test-xsharedawssecret-with-data/      # Variant test with data
├── test-xupboundreposet/                 # Basic UpboundRepoSet tests
└── test-xupboundreposet-repo-config/     # Variant test with config
```

**Naming Pattern**: `test-<resource-type>[-variant]`

**For our VPC project**:
```
tests/
├── test-xvpc-basic/                      # Minimal VPC
├── test-xvpc-public-subnets/             # VPC with public subnets
├── test-xvpc-private-subnets/            # VPC with private subnets
├── test-xvpc-nat-single/                 # Single NAT Gateway
├── test-xvpc-nat-per-az/                 # NAT per AZ
├── test-xvpc-routes/                     # Route tables
├── test-xvpc-endpoints/                  # VPC endpoints
├── test-xvpc-flow-logs/                  # Flow logs
├── test-xvpc-complete/                   # All features
└── e2etest-xvpc-basic/                   # E2E test (note prefix)
```

### Test File Structure

Each test directory contains:

```
test-xenvironment/
├── kcl.mod           # KCL module configuration
├── kcl.mod.lock      # Dependency lock file
├── main.k            # Test definition
└── model/            # (optional) Symbolic link to shared models
```

**Key files**:
- `kcl.mod`: Declares KCL dependencies
- `kcl.mod.lock`: Pins exact dependency versions
- `main.k`: Contains the CompositionTest or E2ETest definition

---

## Test Generation with up CLI

Tests can be scaffolded using the `up` CLI:

```bash
# Generate composition test
up test generate test-xvpc-basic --language=kcl

# Generate E2E test
up test generate e2etest-xvpc-basic --e2e --language=kcl
```

This creates:
- Test directory with proper structure
- `kcl.mod` with dependencies
- `main.k` template with basic structure

---

## Composition Test Structure (KCL)

Based on platform-ref-upbound's test-xenvironment/main.k:

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

# Composition test definition
test = metav1alpha1.CompositionTest {
    # Paths to composition files
    compositionPath = "../../apis/xenvironment/composition.yaml"
    xrPath = "../../examples/xenvironment.yaml"
    xrdPath = "../../apis/xenvironment/definition.yaml"

    # Test configuration
    timeoutSeconds = 60
    validate = False  # Disable validation if testing integration

    # Assert that these resources are created
    assertResources = [
        {
            apiVersion = "kubernetes.crossplane.io/v1alpha2"
            kind = "Object"
            metadata.name = "provider-kubernetes"
            # Can add spec assertions here
        }
        {
            apiVersion = "iam.aws.upbound.io/v1beta1"
            kind = "Role"
            metadata.name = "control-plane-role"
            # Assert spec fields match expected values
        }
        # ... more resources
    ]

    # Observe existing resources and assert their status
    observedResources = [
        {
            apiVersion = "kubernetes.crossplane.io/v1alpha1"
            kind = "ProviderConfig"
            metadata.name = "default"
            # Can check status fields
            status.conditions = [
                {
                    type = "Ready"
                    status = "True"
                }
            ]
        }
        # ... more observed resources
    ]
}
```

### Key Components

**1. assertResources**:
- Resources that SHOULD be created by the composition
- Used to validate the composition creates the right managed resources
- Can include partial specs to validate specific fields

**2. observedResources**:
- Resources that exist and should have certain status conditions
- Validates that resources reached expected states
- Useful for checking readiness, sync status, etc.

**3. managementPolicies**:
- Can be set to `["Observe"]` for read-only resources
- Useful for testing integration with existing resources

---

## GitHub Workflows

### CI Workflow (.github/workflows/ci.yaml)

**Purpose**: Build and push project on main branch

```yaml
name: CI
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag'
        required: false

env:
  UP_API_TOKEN: ${{ secrets.UP_API_TOKEN }}
  UP_ROBOT_ID: ${{ secrets.UP_ROBOT_ID }}
  UP_ORG: ${{ secrets.UP_ORG }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

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

      - name: Build and push
        if: env.UP_API_TOKEN != ''
        run: |
          up project build
          up project push --push-project=true
```

**Key features**:
- Robot credentials for registry access (UP_ROBOT_ID)
- Manual dispatch with version input
- Build and push on main branch only
- **Note**: No test step in CI workflow!

### Composition Test Workflow

Based on our existing `.github/workflows/composition-test.yaml`:

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
          skip-login: true  # No credentials needed for composition tests
      - run: up project build
      - run: up test run tests/*  # Runs all composition tests
```

**Key features**:
- Runs on every push and PR
- No credentials required
- Fast feedback (seconds to minutes)
- Tests all files matching `tests/*`

### E2E Test Workflow (.github/workflows/e2e.yaml)

**Purpose**: Run E2E tests on Upbound Cloud (requires label)

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
        run: up test run tests/* --e2e
```

**Key features**:
- Only runs when PR has "run-e2e-tests" label
- Uses pull_request_target for secret access
- Requires UP_API_TOKEN, UP_ORG
- Switches to Upbound Cloud context before running
- Tests run on real control plane (upbound-gcp-us-central-1)
- Uses robot credentials for registry access

---

## Running Tests Locally

### Composition Tests (No Cloud Required)

```bash
# Generate test
up test generate test-xvpc-basic --language=kcl

# Run single test
up test run tests/test-xvpc-basic/main.k

# Run all tests
up test run tests/*

# Run tests matching pattern
up test run tests/test-xvpc-*

# Verbose output
up test run tests/* --verbose
```

### E2E Tests (Requires Upbound Cloud)

```bash
# Login to Upbound
up login

# Switch to your control plane
up ctx <org>/upbound-gcp-us-central-1/default

# Run E2E tests
up test run tests/e2etest-* --e2e

# Run specific E2E test
up test run tests/e2etest-xvpc-basic/main.k --e2e
```

---

## Test Execution Flow

### Composition Test Flow

1. Load composition, XRD, and XR from specified paths
2. Simulate composition controller loop
3. Render composed resources
4. Assert that expected resources are present
5. Validate resource specifications match assertions
6. Check observed resource states
7. Report success or failure

**Duration**: Seconds (very fast)

### E2E Test Flow

1. Build and push project to registry
2. Create or use existing control plane on Upbound Cloud
3. Install project and dependencies
4. Apply extra resources (ProviderConfig, Secrets, etc.)
5. Wait for extra resources to be ready
6. Apply test manifests (XRs)
7. Wait for resources to reach expected conditions
8. Run assertions
9. Export resources if failure occurs (for debugging)
10. Clean up resources (unless skipDelete=true)
11. Clean up control plane

**Duration**: Minutes to tens of minutes (slow)

---

## Key Testing Principles from platform-ref-upbound

### 1. Resource-Based Organization
- One test directory per resource type
- Variants for different scenarios (basic, with-data, deletion-policy, etc.)
- Clear naming: `test-<resource>-<variant>`

### 2. Composition Tests for Everything
- Every composition should have at least one test
- Test basic scenario first
- Add variant tests for edge cases
- Fast feedback loop

### 3. E2E Tests for Critical Paths
- Not every composition needs E2E test
- Focus on critical integrations
- Require real cloud resources
- Run only when needed (labeled PRs)

### 4. Use KCL for Tests
- Consistent with composition language
- Type-safe test definitions
- Reusable patterns

### 5. CI/CD Integration
- Composition tests on every PR (fast, no cost)
- E2E tests on labeled PRs (slow, has cost)
- Automatic cleanup

---

## Testing Checklist for New Features

When adding a new feature to our VPC configuration:

- [ ] Write composition test for basic scenario
- [ ] Write composition tests for variants (if applicable)
- [ ] Generate test with: `up test generate test-xvpc-<feature>`
- [ ] Update test to include assertResources
- [ ] Run locally: `up test run tests/test-xvpc-<feature>`
- [ ] Fix any issues
- [ ] Commit with tests
- [ ] CI will run composition tests automatically
- [ ] Consider E2E test for critical features
- [ ] Update existing tests if they break

---

## Fixing Broken Tests

When implementing new features that break existing tests:

### Process

1. **Identify broken tests**:
   ```bash
   up test run tests/* --verbose
   ```

2. **Understand what changed**:
   - Did you add new required fields to XRD?
   - Did you add new resources to composition?
   - Did you change resource names or structure?

3. **Update test files**:
   - Update XR examples if XRD changed
   - Update assertResources if new resources added
   - Update resource names if they changed
   - Update spec fields if they changed

4. **Re-run tests**:
   ```bash
   up test run tests/* --verbose
   ```

5. **Iterate until passing**

### Common Issues

**Issue**: Test fails with "resource not found"
**Solution**: Add new resource to assertResources

**Issue**: Test fails with "field validation error"
**Solution**: Update XR example with new required fields

**Issue**: Test fails with "unexpected resource"
**Solution**: Update assertResources to expect the new resource

**Issue**: Test times out
**Solution**: Increase timeoutSeconds in test definition

---

## iterate_project Command Integration

The `iterate_project` skill should be updated to:

1. **Before implementing features**:
   - Check existing tests: `up test run tests/*`
   - Note which tests pass

2. **After implementing features**:
   - Re-run tests: `up test run tests/*`
   - Identify broken tests
   - Fix broken tests by updating:
     - XR examples
     - assertResources
     - observedResources
   - Ensure all tests pass before proceeding

3. **For new features**:
   - Generate new test: `up test generate test-xvpc-<feature>`
   - Write assertions for new resources
   - Run test: `up test run tests/test-xvpc-<feature>`
   - Fix until passing

---

## References

- **Platform Ref Upbound**: https://github.com/upbound/platform-ref-upbound
- **Platform Ref AWS**: https://github.com/upbound/platform-ref-aws
- **Testing Guide**: See thoughts/tools/testing-guide.md
- **Upbound Docs**: https://docs.upbound.io/build/control-plane-projects/testing/

---

## Summary

**Test Organization**:
- One directory per test: `test-<resource>-<variant>/`
- Each test has: `main.k`, `kcl.mod`, `kcl.mod.lock`
- Generate with: `up test generate`

**Test Types**:
- Composition tests: Fast, no cloud, every feature
- E2E tests: Slow, real cloud, critical paths only

**CI/CD**:
- Composition tests: Every push/PR
- E2E tests: Labeled PRs only ("run-e2e-tests")
- Runs on Upbound Cloud, not local

**Workflow**:
1. Generate test with up CLI
2. Write assertions (assertResources, observedResources)
3. Run locally
4. Fix issues
5. Commit
6. CI validates automatically

**When features change**:
- Re-run all tests
- Fix broken tests by updating XR examples and assertions
- Ensure all tests pass before merging
