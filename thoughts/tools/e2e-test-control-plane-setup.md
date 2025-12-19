# E2E Test Control Plane Configuration

## Key Learning: Control Plane Group Selection

**IMPORTANT**: E2E tests should ALWAYS run on a dedicated control plane group for testing, NOT on production control plane groups.

## Local Testing vs CI/CD

### Local Testing (Manual Runs)

For local testing, use the **`upbound-gcp-us-central-1`** control plane group:

```bash
# Run E2E tests locally on GCP control plane group
up test run tests/e2etest-* --e2e --control-plane-group=upbound-gcp-us-central-1

# Example with specific test
up test run tests/e2etest-xvpc-simple --e2e --control-plane-group=upbound-gcp-us-central-1
```

### CI/CD Testing (GitHub Actions)

**NOTE**: GitHub workflow configuration is separate and will be configured later. Do not modify `.github/workflows/` files yet.

### Available Flags

```bash
--control-plane-group=STRING
    The control plane group that the control plane to use is contained in.
    This defaults to the group specified in the current context.

--control-plane-name-prefix=STRING
    Prefix of the control plane name to use.
    It will be created if not found.

--skip-control-plane-check
    Allow running on a non-development control plane.

--skip-control-plane-cleanup
    Skip cleanup of the control plane after the test run.
    (Useful for debugging failed tests)
```

## How E2E Tests Work with Control Planes

### Automatic Control Plane Creation

When you run an E2E test with `--e2e`:

1. **Creates temporary dev control plane** in the specified control plane group
2. **Installs providers and functions** from your project
3. **Applies test manifests** (Claims, XRs, etc.)
4. **Waits for conditions** (Ready, Synced)
5. **Automatically cleans up** control plane when done

### Control Plane Lifecycle

```
Test Start
  ↓
Create dev control plane in <control-plane-group>
  ↓
Install Crossplane (version from test spec)
  ↓
Push and install configuration package
  ↓
Install providers (from dependencies)
  ↓
Apply initResources (if any)
  ↓
Apply extraResources (ProviderConfig, etc.)
  ↓
Apply manifests (Claims/XRs being tested)
  ↓
Wait for defaultConditions (Ready, Synced)
  ↓
Validate resources
  ↓
Cleanup: Delete resources and control plane
  ↓
Test Complete (Pass/Fail)
```

## Current Context vs Explicit Group

### Default Behavior (Uses Current Context)

```bash
# Check current context
up ctx .
# Output: Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske

# ❌ DON'T RUN without specifying group - uses current context group!
up test run tests/e2etest-* --e2e
```

### Explicit Group (Required for Local Testing)

```bash
# ✅ CORRECT - Run test on GCP control plane group for local testing
up test run tests/e2etest-* --e2e --control-plane-group=upbound-gcp-us-central-1

# This overrides the context and creates control plane in "upbound-gcp-us-central-1"
```

## Best Practices

### 1. Always Use Dedicated Test Control Plane Group

**✅ GOOD** - For local testing:
```bash
up test run tests/e2etest-* --e2e --control-plane-group=upbound-gcp-us-central-1
```

**❌ BAD** - Using production control plane group:
```bash
up test run tests/e2etest-* --e2e  # Uses current context group!
```

### 2. Control Plane Groups by Environment

- **Local Testing**: `upbound-gcp-us-central-1` (manual developer testing)
- **CI/CD Testing**: TBD (will be configured in GitHub workflows later)

### 3. Document the Required Group

In your project README or CI/CD docs, document:
- Which control plane group to use for tests
- How to create the control plane group if it doesn't exist
- IAM roles and permissions required

### 4. CI/CD Configuration

**NOTE**: GitHub workflows will be configured separately later. Do not modify `.github/workflows/` files yet.

## Checking Current Configuration

```bash
# View current profile and organization
up profile list

# View current context (includes control plane group)
up ctx .

# Example output:
# Kubeconfig context "upbound": Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske
# Organization: solutions
# Control Plane Group: upbound-aws-us-east-1
# Control Plane: upbox
# Space: upbox-danske
```

## Control Plane Groups in Upbound

### What is a Control Plane Group?

A control plane group is a logical grouping of control planes within an Upbound organization. It provides:
- **Isolation**: Separate test control planes from production
- **Resource organization**: Group related control planes
- **Access control**: Different permissions per group
- **Cost tracking**: Separate billing/usage by group

### Typical Organization Structure

```
Organization: solutions
  ├── Control Plane Group: production
  │   ├── control plane: prod-us-east
  │   └── control plane: prod-eu-west
  ├── Control Plane Group: staging
  │   └── control plane: staging-us-east
  └── Control Plane Group: test-cplanes (for E2E tests)
      ├── control plane: e2e-test-1 (auto-created by tests)
      ├── control plane: e2e-test-2 (auto-created by tests)
      └── ... (cleaned up automatically after tests)
```

## Debugging Failed E2E Tests

### Keep Control Plane for Investigation

```bash
# Skip cleanup to investigate issues
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=test-cplanes \
  --skip-control-plane-cleanup
```

Then manually inspect:
```bash
# Switch to test control plane
up ctx <control-plane-name>

# Check resources
kubectl get composite
kubectl get managed
kubectl describe xvpc <name>
kubectl get events --sort-by='.lastTimestamp'
```

### Run on Existing Control Plane

```bash
# Use current kubeconfig context instead of creating new
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --use-current-context
```

## Example: Complete E2E Test Workflow (Local Testing)

```bash
# 1. Ensure logged into Upbound
up login

# 2. Check current context
up ctx .
# Output: Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske

# 3. Run E2E tests on GCP control plane group (for local testing)
up test run tests/e2etest-* \
  --e2e \
  --control-plane-group=upbound-gcp-us-central-1 \
  --organization=solutions

# 4. Tests will:
#    - Create temporary control plane in "upbound-gcp-us-central-1"
#    - Run tests
#    - Clean up control plane
#    - Report results

# 5. If test fails and you need to debug:
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=upbound-gcp-us-central-1 \
  --skip-control-plane-cleanup

# 6. Then inspect the control plane:
kubectl get controlplanes -n upbound-system
up ctx <failed-test-control-plane-name>
kubectl get all
```

## Summary

### Local Testing
- ✅ **ALWAYS** use `--control-plane-group=upbound-gcp-us-central-1` for local E2E tests
- ✅ **NEVER** run E2E tests without specifying control plane group
- ✅ **NEVER** run E2E tests on production control plane groups
- ✅ E2E tests create temporary control planes automatically
- ✅ Control planes are cleaned up automatically (unless `--skip-control-plane-cleanup`)

### CI/CD Testing
- ⏸️ GitHub workflows will be configured separately later
- ⏸️ Do not modify `.github/workflows/` files yet
