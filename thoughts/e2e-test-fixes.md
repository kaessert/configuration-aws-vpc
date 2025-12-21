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

---

## Date: 2025-12-20 - CRITICAL FIX FOUND

#### Issue 6: ProviderConfig Missing Namespace Field
**Problem**: E2E test still hanging on "Applying Extra Resources..." even with correct API version
**Root Cause**: **ProviderConfig was missing the `namespace` field!**
**Discovery**: User identified that namespaced claims REQUIRE namespaced ProviderConfigs

**The Critical Fix**:
```kcl
{
    apiVersion: "aws.m.upbound.io/v1beta1"
    kind: "ProviderConfig"
    metadata: {
        name: "default"
        namespace: "default"  # <-- THIS WAS MISSING!
    }
    spec: {
        credentials: {
            source: "Upbound"
        }
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

**Why This Was The Issue**:
- The test uses a **namespaced VPC claim** (`kind: "VPC"` with `namespace: "default"`)
- Namespaced claims require **namespaced ProviderConfigs** in the same namespace
- Without the namespace field, Kubernetes cannot create the ProviderConfig
- This caused the "Applying Extra Resources" phase to hang indefinitely

**Key Rule**:
- **Namespaced claims** → ProviderConfig MUST have `namespace` field
- **Cluster-scoped composites** (XVPC) → ProviderConfig can be cluster-scoped (no namespace)

**Repository Fix**:
Also changed repository from `solutions` to `upbound`:
- FROM: `xpkg.upbound.io/solutions/configuration-aws-vpc`
- TO: `xpkg.upbound.io/upbound/configuration-aws-vpc`

**All 5 E2E Tests Need This Fix**:
1. e2etest-e2etest-xvpc-simple ← FIXING NOW
2. e2etest-e2etest-xvpc-basic
3. e2etest-e2etest-xvpc-nat-single
4. e2etest-e2etest-xvpc-nat-per-az
5. e2etest-e2etest-xvpc-complete

---

## Date: 2025-12-20 - E2E TEST RESULTS

### Test Run: e2etest-e2etest-xvpc-simple

**Status**: ❌ FAILED

**Duration**: 30 minutes (timed out)

**Critical Issues Found**:

#### Issue 7: Composition Function Creates Cluster-Scoped Managed Resources
**Problem**: When using a namespaced VPC claim, the composition function creates **cluster-scoped** managed resources (no namespace), but they should be **namespaced** to match the claim.

**Evidence**:
- VPC claim created in `namespace: default`
- All 8 child managed resources created WITHOUT namespace (cluster-scoped)
- Cleanup failed with error: "an empty namespace may not be set when a resource name is..."
- Only the namespaced claim could be deleted (1/9), all cluster-scoped resources failed (8/9)

**Root Cause**: The composition function in `functions/vpc/main.k` is not propagating the namespace from the claim to the managed resources.

**Required Fix**: Update composition function to add namespace metadata to all managed resources when the XR has a namespace.

#### Issue 8: Composite Readiness Status Bug
**Problem**: VPC composite claim never reached `Ready=True` even though ALL 8 child resources were Ready.

**Evidence**:
```
VPC Claim Status:
- SYNCED: True
- READY: False ❌
- MESSAGE: "Creating: Unready resources: igw, public-route-igw, public-route-table, and 5 more"

Child Resources Status:
- VPC: SYNCED=True, READY=True ✅
- InternetGateway: SYNCED=True, READY=True ✅
- RouteTable: SYNCED=True, READY=True ✅
- Route: SYNCED=True, READY=True ✅
- Subnet (2x): SYNCED=True, READY=True ✅
- RouteTableAssociation (2x): SYNCED=True, READY=True ✅
```

All 8 resources were Ready, but the composite reported them as "Unready".

**Root Cause**: The readiness calculation logic in the composition function or Crossplane is incorrectly reporting child status. This could be:
1. Status check looking at wrong field
2. Readiness conditions not properly defined
3. Status aggregation bug in composition function

**Impact**:
- E2E tests will always timeout waiting for Ready=True
- Users will see resources as "Creating" even when fully operational
- Makes it impossible to determine actual resource health

#### Issue 9: Orphaned AWS Resources
**Result**: Because cleanup failed, 8 AWS resources are orphaned in account 609897127049, us-west-2:
- 1x VPC
- 1x Internet Gateway
- 1x Route Table
- 1x Route
- 2x Subnet
- 2x Route Table Association

**Action Required**: Manual cleanup in AWS Console or via AWS CLI.

### Next Steps

**Priority 1**: Fix namespace propagation in composition function
- Managed resources must inherit namespace from XR
- All resources in the same namespace for proper lifecycle management

**Priority 2**: Debug readiness status calculation
- Investigate why composite reports children as Unready when they're Ready
- May need to check status field references in composition function

**Priority 3**: Manual cleanup
- Delete orphaned AWS resources
- Verify no other resources left behind from previous test runs
