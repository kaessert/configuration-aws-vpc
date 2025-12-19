# E2E Test Control Plane Group Requirement

**Date**: 2025-12-19
**Issue**: Missing documentation on `--control-plane-group` requirement for E2E tests

---

## Problem

The E2E testing documentation was missing critical information about the `--control-plane-group` flag, which is **REQUIRED** when running E2E tests with Upbound Spaces.

### What Was Missing

Original documentation showed:
```bash
# WRONG - This will fail or use wrong context
up test run tests/e2etest-* --e2e
```

### What Should Be Used

**CORRECT** command structure:
```bash
# CORRECT - Must specify control plane group
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

---

## Why This Matters

### Control Plane Groups in Upbound Spaces

1. **Groups are organizational units** in Upbound that contain control planes
2. **E2E tests create ephemeral control planes** that run your composition
3. **Control planes must be created in a group** - there's no "default" group
4. **Without specifying the group**, the test will either:
   - Fail with an error about missing group
   - Use the wrong group from your current kubectl context
   - Create resources in an unintended location

### How E2E Tests Use Groups

When you run an E2E test:

1. **Test parses and builds** your configuration package
2. **Creates ephemeral control plane** in the specified group (e.g., `claude-testing`)
3. **Installs your configuration** on that control plane
4. **Applies test manifests** (VPC, ProviderConfig, etc.)
5. **Waits for resources** to reach Ready/Synced
6. **Cleans up** the control plane and all resources

**Without `--control-plane-group`**: Step 2 fails or uses wrong group!

---

## How to Find Your Group

### List Available Groups

```bash
up group list
```

**Example output**:
```
NAME                              PROTECTED
claude-testing                    false
default                           false
production                        false
```

### Common Groups

- **`claude-testing`** - Development and testing (recommended for this project)
- **`default`** - Default group (if it exists)
- **`production`** - Production workloads (avoid for E2E tests!)
- **Custom groups** - Your organization may have specific groups

### Creating a New Group

If you don't have a suitable group:

```bash
# Create a new group for E2E testing
up group create e2e-testing
```

---

## Updated Command Reference

### Run Single E2E Test

```bash
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing
```

### Run All E2E Tests

```bash
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

### Check Running Control Planes in Group

```bash
up controlplane list --group=claude-testing
```

### Monitor E2E Test Control Plane

```bash
# List control planes (find the ephemeral E2E test control plane)
up controlplane list --group=claude-testing

# Get details about a specific control plane
up controlplane get <control-plane-name> --group=claude-testing
```

---

## CI/CD Integration

When running E2E tests in CI/CD, ensure the group is specified:

```yaml
# .github/workflows/e2e.yaml
- name: Run E2E Tests
  run: |
    up test run tests/e2etest-* --e2e --control-plane-group=ci-testing
```

**Best practices for CI**:
- Use a dedicated group for CI (e.g., `ci-testing`, `github-actions`)
- Don't use `production` or `default` groups for CI
- Ensure cleanup happens even if tests fail
- Monitor for orphaned control planes

---

## Flags Reference

### `--control-plane-group`

**Purpose**: Specify which Upbound group to create the E2E test control plane in

**Required**: Yes, for E2E tests on Upbound Spaces

**Format**: `--control-plane-group=<group-name>`

**Examples**:
```bash
--control-plane-group=claude-testing
--control-plane-group=default
--control-plane-group=e2e-ci
```

### Other Useful Flags

```bash
# Skip control plane cleanup (for debugging)
--skip-control-plane-cleanup

# Use current kubeconfig context instead of creating new control plane
--use-current-context

# Allow running on non-development control plane
--skip-control-plane-check
```

---

## Documentation Updates Made

Updated the following files to include `--control-plane-group` requirement:

1. **`thoughts/testing/e2e-implementation-guide.md`**
   - ✅ Added to Quick Start section
   - ✅ Added to Step 5 (Run E2E Test)
   - ✅ Added to Common Commands
   - ✅ Added explanation of why it's required

2. **`TESTING.md`**
   - ✅ Added to E2E Tests section
   - ✅ Added critical warning about requirement

3. **`CLAUDE.md`**
   - ✅ Added to TDD workflow (🧪 E2E TEST Phase)
   - ✅ Added to final commit checks

4. **`thoughts/E2E_CONTROL_PLANE_GROUP_REQUIREMENT.md`** (this file)
   - ✅ Created comprehensive reference document

---

## Key Takeaways

1. **Always specify `--control-plane-group`** when running E2E tests
2. **Use `claude-testing` group** for development and testing
3. **List groups first** with `up group list` if unsure
4. **E2E tests create ephemeral control planes** in the specified group
5. **Without the flag**, tests will fail or use wrong context

---

## References

- `up test run --help` - Full command reference
- `up group --help` - Group management commands
- `up controlplane --help` - Control plane management

---

## Next Steps

1. ✅ Documentation updated with `--control-plane-group` requirement
2. ⏳ Run E2E tests with correct command structure
3. ⏳ Verify tests pass with proper group specification
4. ⏳ Update any CI/CD workflows to include the flag
