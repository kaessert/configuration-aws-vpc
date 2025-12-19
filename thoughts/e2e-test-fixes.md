# E2E Test Fixes - Session Notes

## Date: 2025-12-19

### Issues Found and Fixed

#### Issue 1: e2etest-xvpc-simple Missing Crossplane Version
**Problem**: The test was using Crossplane v1 (1.20.4-up.1) instead of v2
**Root Cause**: Missing `crossplane.version` field in test configuration
**Fix**: Added `version: "2.0.2-up.5"` to crossplane configuration

**Before**:
```kcl
crossplane: {
    autoUpgrade: {
        channel: "Rapid"
    }
}
```

**After**:
```kcl
crossplane: {
    version: "2.0.2-up.5"  # CRITICAL - Must specify v2
    autoUpgrade: {
        channel: "Rapid"
    }
}
```

#### Issue 2: Wrong ProviderConfig API Version
**Problem**: Using `aws.upbound.io/v1beta1` (parent provider) instead of `aws.m.upbound.io/v1beta1` (namespaced)
**Root Cause**: Crossplane v2 uses namespaced providers with `.m.` suffix
**Fix**: Changed API version and added `credentials.source: "Upbound"`

**Before**:
```kcl
apiVersion: "aws.upbound.io/v1beta1"
spec: {
    assumeRoleChain: [...]
}
```

**After**:
```kcl
apiVersion: "aws.m.upbound.io/v1beta1"  # Note the .m. suffix
spec: {
    credentials: {
        source: "Upbound"  # For Upbound Spaces identity injection
    }
    assumeRoleChain: [...]
}
```

#### Issue 3: Must Use Control Plane Group for E2E Tests
**Problem**: Running tests without specifying control plane group
**Root Cause**: Tests default to current context group (may be production)
**Fix**: Always use `--control-plane-group=claude-testing` for local E2E tests

**Correct Command**:
```bash
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
```

**Why This Matters**:
- Prevents accidental creation of control planes in production groups
- Keeps test control planes isolated
- Enables proper cleanup and organization

### Files Fixed
1. `/Users/tkaesser/up/configuration-aws-vpc/tests/e2etest-e2etest-xvpc-simple/main.k`
   - Added Crossplane v2 version
   - Fixed ProviderConfig API version
   - Added credentials.source field

### Verification
- Control plane deleted: `configuration-aws-vpc-uptest-e2etest-xvpc-simple`
- Test file updated with correct configuration
- Ready to restart with `--control-plane-group=claude-testing`

### Key Learnings
1. **ALWAYS check Crossplane version** in E2E tests - v2 requires explicit version
2. **ALWAYS use `.m.` API suffix** for ProviderConfig in Crossplane v2
3. **ALWAYS specify control plane group** for E2E tests - never rely on context default
4. **Switch to correct space context** before running tests: `up ctx solutions/upbound-gcp-us-central-1/default`

#### Issue 4: claude-testing Group Did Not Exist
**Problem**: Test failed with "namespaces 'claude-testing' not found"
**Root Cause**: Group must be created before first use
**Fix**: Created group with `up group create claude-testing`

### Actions Taken
1. ✅ Fixed e2etest-xvpc-simple test file (Crossplane v2 + correct ProviderConfig)
2. ✅ Created `claude-testing` group for E2E tests
3. ✅ Started Test 1 with correct command
4. ⚠️ **Test hung on "Applying Extra Resources"**

#### Issue 5: E2E Test Framework Hangs on "Applying Extra Resources"
**Problem**: Test stuck on "Applying Extra Resources" for 10+ minutes
**Investigation**:
- Manually applied ProviderConfig - SUCCESS (resource is valid)
- Packages installed and healthy
- No errors in events or logs
**Root Cause**: Potential bug or timeout issue in `up test` E2E framework
**Impact**: Cannot complete E2E tests with current approach

**Evidence**:
```bash
# Manual apply worked fine
kubectl apply -f providerconfig.yaml
# providerconfig.aws.m.upbound.io/default created ✅

# Test remained stuck:
# Applying Extra Resources … (no progress for 10+ minutes)
```

**Next Steps**: Try alternative approach or investigate E2E test framework timeout settings

### Next Steps
1. ✅ Run test with correct command and group
2. ✅ Control plane created successfully
3. ⚠️ Investigate E2E framework hang issue
4. ⏳ Try alternative test approach or framework settings
