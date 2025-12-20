# E2E Test Implementation Guide

**Last Updated**: 2025-12-20

This guide provides **step-by-step instructions** for writing and running End-to-End (E2E) tests for Upbound configurations.

**Critical**: E2E tests are **MANDATORY** for all features. A feature is NOT complete until it passes E2E validation in real AWS.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Step-by-Step Workflow](#step-by-step-workflow)
3. [Critical Configuration Requirements](#critical-configuration-requirements)
4. [Test Execution Phases](#test-execution-phases)
5. [Monitoring & Verification](#monitoring--verification)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

## Quick Start

### Prerequisites

1. **Upbound CLI** installed (`up` command)
2. **Upbound account** authenticated (`up login`)
3. **Control plane group** created or available
4. **Feature implemented** with passing composition tests
5. **IAM role configured** (handled by Upbound Cloud)

### 5-Minute Quick Start

```bash
# 1. List available groups
up group list

# 2. Generate E2E test
up test generate e2etest-xvpc-<feature-name> --e2e --language=kcl

# 3. Edit test: tests/e2etest-*/main.k
# Configure: Crossplane version, ProviderConfig, test manifest

# 4. Run test (MUST specify --control-plane-group!)
up test run tests/e2etest-xvpc-<feature-name> --e2e --control-plane-group=claude-testing

# 5. Wait 20-40 minutes for AWS resource creation and cleanup

# 6. Verify cleanup in AWS Console (CRITICAL!)
```

---

## Step-by-Step Workflow

### Step 1: Generate E2E Test Structure

```bash
# Generate E2E test with KCL
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Example: E2E test for VPC creation
up test generate e2etest-xvpc-vpc --e2e --language=kcl

# Example: E2E test for NAT Gateway
up test generate e2etest-xvpc-nat --e2e --language=kcl
```

**What this creates**:
```
tests/
└── e2etest-xvpc-<feature>/
    ├── main.k          # Test definition (edit this!)
    ├── kcl.mod         # Dependencies
    └── kcl.mod.lock    # Dependency lock file
```

---

### Step 2: Configure Test Manifest

Open `tests/e2etest-xvpc-<feature>/main.k` and configure the test:

```kcl
"""
<Feature Name> E2E Test

Tests the <feature> with real AWS resources:
- <List what resources are created>
- Resources reach Ready/Synced state
- Proper cleanup after test

Validates: <reference to feature in spec>
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-<feature>"
        spec= {
            # CRITICAL: Crossplane v2 version (REQUIRED!)
            crossplane: {
                version: "2.0.2-up.5"  # Must specify v2
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts (adjust based on complexity)
            timeoutSeconds: 1800            # 30 minutes for resource creation
            cleanupTimeoutSeconds: 600      # 10 minutes for cleanup

            # Ensure cleanup happens (CRITICAL!)
            skipDelete: False

            # Validation: Check Ready and Synced states
            defaultConditions: ["Ready", "Synced"]

            # Main test manifests
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"  # Use Claim, not XVPC
                    metadata: {
                        name: "e2e-test-<feature>"
                        namespace: "default"  # REQUIRED for namespaced claims
                    }
                    spec: {
                        # Your feature configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        # ... more config ...
                        tags: {
                            Environment: "e2e-test"
                            ManagedBy: "upbound"
                            TestName: "<feature>"
                        }
                    }
                }
            ]

            # ProviderConfig for AWS authentication (REQUIRED!)
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"  # Note: .m. suffix!
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"  # REQUIRED for namespaced claims
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"  # For Upbound Spaces
                        }
                        assumeRoleChain: [
                            {
                                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        ]
                    }
                }
            ]
        }
    }
]
items= _items
```

---

## Critical Configuration Requirements

### 1. Crossplane Version (MANDATORY)

**ALWAYS specify Crossplane version**:

```kcl
crossplane: {
    version: "2.0.2-up.5"  # CRITICAL - Must specify v2
    autoUpgrade: {
        channel: "Rapid"
    }
}
```

**Why this matters**:
- Default version may be v1 (incompatible with v2 APIs)
- Missing version causes package installation failure
- Error: `no kind "CompositeResourceDefinition" is registered for version "apiextensions.crossplane.io/v2"`

**Debugging tip**: If test hangs at "Waiting for package to be ready" for >3 minutes:
```bash
# Switch to control plane and check package status
up controlplane list --group=claude-testing
kubectl get pkgrev -oyaml  # Look for UnhealthyPackageRevision
```

### 2. ProviderConfig Configuration (MANDATORY)

**For Crossplane v2 with namespaced claims**:

```kcl
{
    apiVersion: "aws.m.upbound.io/v1beta1"  # CRITICAL: .m. suffix
    kind: "ProviderConfig"
    metadata: {
        name: "default"
        namespace: "default"  # REQUIRED for namespaced claims
    }
    spec: {
        credentials: {
            source: "Upbound"  # For Upbound Spaces
        }
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

**Critical Points**:

✅ **DO**:
- Use `aws.m.upbound.io/v1beta1` (note the `.m.` suffix for namespaced provider)
- Add `namespace: "default"` to metadata (REQUIRED for namespaced claims)
- Use `source: "Upbound"` (for Upbound Spaces managed credentials)
- Use `assumeRoleChain` with IAM role (never static credentials)

❌ **DON'T**:
- Use `aws.upbound.io/v1beta1` (parent provider - will not work)
- Omit namespace field (will cause test to hang)
- Use static AWS credentials (security risk)
- Use `source: "Secret"` (not compatible with Upbound Spaces)

**Why the `.m.` suffix?**:
- Crossplane v2 introduced namespaced resources
- Parent provider: `aws.upbound.io`
- Namespaced provider: `aws.m.upbound.io` (note the `.m.`)
- Managed resources (VPC, Subnet, etc.) look for ProviderConfig in `aws.m.upbound.io`

**Why the namespace field?**:
- Namespaced claims require namespaced ProviderConfigs
- ProviderConfig must be in same namespace as claim
- Without namespace, Kubernetes cannot create the ProviderConfig
- This causes "Applying Extra Resources" phase to hang indefinitely

### 3. Control Plane Group (MANDATORY)

**ALWAYS specify `--control-plane-group` when running E2E tests**:

```bash
# ✅ CORRECT - Specifies group
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# ❌ WRONG - Missing group (will fail or use wrong context)
up test run tests/e2etest-* --e2e
```

**Why this is required**:
- E2E tests create ephemeral control planes in Upbound Spaces
- Control planes must be created in a specific group
- Without specifying the group, test may fail or use wrong context
- Use `claude-testing` for development/testing

**List available groups**:
```bash
up group list
```

**Create group if needed**:
```bash
up group create claude-testing
```

### 4. Timeout Settings

Set timeouts based on resource complexity:

| Resource Type | Recommended Timeout | Cleanup Timeout |
|--------------|---------------------|-----------------|
| VPC only | 600s (10 min) | 600s (10 min) |
| VPC + Subnets | 900s (15 min) | 600s (10 min) |
| VPC + IGW + Routes | 1200s (20 min) | 600s (10 min) |
| **VPC + NAT** | **1800s (30 min)** | **600s (10 min)** |
| Complete VPC (18 subnets) | 2400s (40 min) | 900s (15 min) |

**Why timeouts matter**:
- AWS resources take time to create (VPC: 30s, NAT: 10-15 min)
- Crossplane needs time to verify resources match desired state
- Cleanup needs time for dependency-ordered deletion

### 5. Cleanup Configuration (CRITICAL)

**ALWAYS set** `skipDelete: False`:

```kcl
skipDelete: False  # MUST be False for cleanup verification
```

**Why this matters**:
- We MUST verify cleanup works correctly
- Orphaned AWS resources cost money (NAT Gateway = $32/month!)
- Resources clutter the AWS account
- May interfere with future tests

**NEVER use `skipDelete: True` in committed tests!**

---

## Test Execution Phases

E2E tests go through 7 phases from build to cleanup:

| Phase | Duration | What's Happening |
|-------|----------|------------------|
| 1. Build & Package | 1-2 min | Local compilation |
| 2. Control Plane Setup | 2-3 min | Upbound Spaces provisioning |
| 3. Apply Manifests | 1 min | Create XR and managed resources |
| 4. Wait for Ready/Synced | 15-30 min | AWS creating actual resources |
| 5. Validation | 1 min | Test framework checks |
| 6. Cleanup | 5-10 min | Delete all resources |
| 7. Report | 1 sec | Final result |
| **TOTAL** | **25-47 min** | **Average: ~40 minutes** |

### Phase 1: Build & Package (1-2 min)

**What happens**:
- Parse test files (KCL syntax validation)
- Collect resources
- Generate language schemas
- Check dependencies
- Build KCL functions
- Build configuration package (.uppkg)

**Expected output**:
```
Parsing tests ✓
Collecting resources ✓
Generating language schemas ✓
Checking dependencies ✓
Building functions ✓
Building configuration package ✓
```

### Phase 2: Control Plane Setup (2-3 min)

**What happens**:
1. Create development control plane in Upbound Spaces
2. Ensure container registry exists
3. Push KCL function package to registry
4. Push configuration package to registry
5. Apply init resources (CRDs, providers)
6. Install configuration package on control plane
7. Wait for package to reach Installed/Healthy state

**Expected output**:
```
Creating development control plane in Spaces ✓
Ensuring repository exists ✓
Pushing function package ✓
Pushing configuration image ✓
Applying Init Resources ✓
Installing package on development control plane ✓
Waiting for package to be ready ...
```

**Where to check**: Upbound Console → Organizations → solutions → Spaces

### Phase 3: Apply Manifests (1 min)

**What happens**:
1. Apply VPC Composite Resource (XR/Claim)
2. Apply ProviderConfig (AWS authentication)
3. Composition function executes (generates managed resources)
4. Crossplane creates managed resources
5. AWS provider syncs with AWS

**Expected output**:
```
Applying test manifests ...
Created: VPC/e2e-test-<feature>
Created: ProviderConfig/default
Waiting for resources to be ready ...
```

### Phase 4: Wait for Ready/Synced (15-30 min)

**This is the LONGEST phase.** AWS takes time to create resources.

**What happens**:
1. VPC Creation - AWS creates VPC (~30 seconds)
2. Subnet Creation - AWS creates subnets (~1-2 minutes)
3. IGW Creation & Attachment - AWS creates and attaches IGW (~2-3 minutes)
4. Route Table Creation - AWS creates route tables (~1 minute)
5. Route Creation - AWS adds routes (~1 minute)
6. Route Table Associations - AWS associates subnets (~1-2 minutes)
7. NAT Gateway Creation (if enabled) - AWS creates NAT (~10-15 minutes)
8. Crossplane Syncing - Crossplane verifies resources (~5-10 minutes)
9. Condition Checking - Test framework verifies Ready AND Synced (~1-2 minutes)

**Expected output**:
```
Waiting for resources to be ready ...
[Long wait - 15-30 minutes]
VPC: Ready ✓
Subnet (us-west-2a): Ready ✓
Subnet (us-west-2b): Ready ✓
InternetGateway: Ready ✓
RouteTable: Ready ✓
Route: Ready ✓
RouteTableAssociation (us-west-2a): Ready ✓
All resources Ready and Synced ✓
```

### Phase 5: Validation (1 min)

**What happens**:
- Condition verification - Check all defaultConditions met
- Resource count check - Verify expected number of resources created
- Status field check - Validate XR status fields populated

**Expected output**:
```
Validating test results ...
✓ All resources Ready
✓ All resources Synced
✓ Expected resource count: 10/10
✓ No error events
Test validation: PASSED ✓
```

### Phase 6: Cleanup (5-10 min)

**This phase is CRITICAL** - verify NO resources are orphaned in AWS.

**What happens**:
1. Delete test manifests (XR/Claim)
2. Crossplane cascade delete (deletes all managed resources)
3. AWS resource deletion in dependency order
4. Verify deletion - Test framework verifies all resources deleted
5. Control plane cleanup - Deletes ephemeral control plane

**Expected output**:
```
Cleaning up test resources ...
Deleting VPC/e2e-test-<feature> ...
Waiting for resources to be deleted ...
All resources cleaned up ✓
Control plane deleted ✓
```

### Phase 7: Report (1 sec)

**Expected output (Success)**:
```
Test: e2etest-xvpc-<feature>
Status: PASSED ✓
Duration: 38m 42s
Resources Created: 10
Resources Cleaned: 10
```

---

## Monitoring & Verification

### Monitor in Upbound Console

1. Login: https://console.upbound.io
2. Navigate: **Organizations → solutions → Spaces**
3. Find: Development control plane (e2etest-xvpc-<feature>)
4. Click: **Control Plane → Managed Resources**
5. Watch: Status progression (Creating → Syncing → Ready)

### Monitor in AWS Console

1. Login: https://console.aws.amazon.com
2. Region: **us-west-2**
3. Service: **VPC**
4. Filter by tags:
   - `Environment=e2e-test`
   - `TestName=<feature>`

### Verify Cleanup (CRITICAL!)

**After test completes**, verify ALL resources are deleted from AWS:

```bash
# Check VPCs - MUST be empty
https://console.aws.amazon.com/vpc → Your VPCs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Check Subnets - MUST be empty
https://console.aws.amazon.com/vpc → Subnets
Filter: CIDR contains test CIDR (10.0.x.0/24)
Expected: NO RESULTS

# Check Internet Gateways - MUST be empty
https://console.aws.amazon.com/vpc → Internet Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Check NAT Gateways - MUST be empty (EXPENSIVE!)
https://console.aws.amazon.com/vpc → NAT Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Check Elastic IPs - MUST be empty (billable if unattached)
https://console.aws.amazon.com/ec2 → Elastic IPs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Check Route Tables - MUST be empty (except default)
https://console.aws.amazon.com/vpc → Route Tables
Filter: Tags → TestName=<feature>
Expected: NO RESULTS (default/main tables are OK)
```

**Cost warning**:
- NAT Gateway: $0.045/hour = $32/month
- EIP (unattached): $0.005/hour = $3.60/month
- **ALWAYS verify cleanup!**

---

## Troubleshooting

### Issue: Test hangs at "Waiting for package to be ready"

**Symptoms**: Test stuck for >3 minutes at package installation

**Diagnosis**: Package installation failing or Crossplane version mismatch

**Check**:
```bash
up controlplane list --group=claude-testing
kubectl get pkgrev -oyaml  # Look for UnhealthyPackageRevision
```

**Solution**: Ensure `crossplane.version = "2.0.2-up.5"` is set in test

---

### Issue: "IAM role cannot be assumed"

**Error**: `User: ... is not authorized to perform: sts:AssumeRole`

**Cause**: Provider can't authenticate with AWS

**Solution**:
1. Verify ProviderConfig uses correct IAM role ARN
2. Ensure `source: "Upbound"` (not "Secret")
3. Check IAM role trust policy allows Upbound

---

### Issue: "ProviderConfig not found"

**Error**: `ProviderConfig.aws.m.upbound.io "default" not found`

**Cause**: Using wrong API group or missing namespace

**Solution**:
1. Use `aws.m.upbound.io/v1beta1` (note the `.m.` suffix)
2. Add `namespace: "default"` to ProviderConfig metadata
3. Ensure namespace matches your claim namespace

---

### Issue: Test hangs at "Applying Extra Resources"

**Symptoms**: Test stuck on "Applying Extra Resources" for >10 minutes

**Cause**: ProviderConfig missing namespace field

**Solution**: Add `namespace: "default"` to ProviderConfig metadata:
```kcl
metadata: {
    name: "default"
    namespace: "default"  # REQUIRED for namespaced claims
}
```

---

### Issue: Resources not cleaning up

**Symptoms**: Test completes but AWS resources remain

**Diagnosis**: Dependencies blocking deletion

**Solution**: Manual cleanup in reverse dependency order:
```bash
# Get VPC ID from AWS Console
VPC_ID="vpc-xxxxx"

# 1. Delete route table associations
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].Associations[*].RouteTableAssociationId' --output text | \
  xargs -n1 aws ec2 disassociate-route-table --association-id

# 2. Delete NAT Gateway (takes 5-10 minutes!)
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].NatGatewayId' --output text | \
  xargs -n1 aws ec2 delete-nat-gateway --nat-gateway-id
# Wait 5-10 minutes!

# 3. Release Elastic IPs
aws ec2 describe-addresses --filters "Name=tag:TestName,Values=<feature>" \
  --query 'Addresses[*].AllocationId' --output text | \
  xargs -n1 aws ec2 release-address --allocation-id

# 4. Delete Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 5. Delete Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' --output text | \
  xargs -n1 aws ec2 delete-subnet --subnet-id

# 6. Delete Route Tables (non-main)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" \
  --query 'RouteTables[*].RouteTableId' --output text | \
  xargs -n1 aws ec2 delete-route-table --route-table-id

# 7. Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

## Quick Reference

### Common Commands

```bash
# Generate E2E test
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# List available groups
up group list

# Run specific E2E test (MUST specify group!)
up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing

# Run all E2E tests (MUST specify group!)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Check running control planes
up controlplane list --group=claude-testing

# Login to Upbound
up login

# Check Upbound profile
up whoami
```

### ProviderConfig Quick Copy

```kcl
extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"  # Note: .m. suffix
        kind: "ProviderConfig"
        metadata: {
            name: "default"
            namespace: "default"  # REQUIRED for namespaced claims
        }
        spec: {
            credentials: {
                source: "Upbound"  # For Upbound Spaces
            }
            assumeRoleChain: [
                {
                    roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                }
            ]
        }
    }
]
```

---

## Summary

E2E tests are **MANDATORY** for all features. They validate that your compositions work correctly in real AWS environments.

**Key takeaways**:
1. Generate test with `up test generate e2etest-xvpc-<feature> --e2e --language=kcl`
2. Configure test manifest with feature parameters
3. **ALWAYS specify Crossplane v2 version**
4. **ALWAYS use `aws.m.upbound.io/v1beta1` with namespace field**
5. **ALWAYS specify `--control-plane-group=claude-testing`**
6. Set appropriate timeout (NAT = 30 min, others = 10-20 min)
7. Always enable cleanup (`skipDelete: False`)
8. Run test and wait 20-40 minutes
9. **VERIFY cleanup** in AWS Console (CRITICAL to avoid costs!)

**Now you're ready to write E2E tests!**
