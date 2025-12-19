# E2E Testing Reference

## Overview

This is the complete reference documentation for End-to-End (E2E) testing with Upbound. E2E tests validate compositions with real cloud resources on Upbound Cloud.

**For step-by-step instructions**: See [E2E Implementation Guide](e2e-implementation-guide.md)

**For testing strategy**: See [Testing Overview](TESTING_OVERVIEW.md)

---

## Table of Contents

1. [What is E2E Testing](#what-is-e2e-testing)
2. [E2E Test Structure](#e2e-test-structure)
3. [Control Plane Setup](#control-plane-setup)
4. [ProviderConfig Configuration](#providerconfig-configuration)
5. [Test Execution Phases](#test-execution-phases)
6. [Resource Creation Timelines](#resource-creation-timelines)
7. [Monitoring During Execution](#monitoring-during-execution)
8. [Cleanup Verification](#cleanup-verification)
9. [Troubleshooting](#troubleshooting)
10. [Cost Management](#cost-management)
11. [CI/CD Integration](#cicd-integration)
12. [Advanced Topics](#advanced-topics)

---

## What is E2E Testing

**Definition**: End-to-End (E2E) tests validate compositions by creating REAL cloud resources in a live environment. They test the complete lifecycle: create → ready → delete.

**Purpose**:
- Validate compositions work with real cloud providers (AWS, Azure, GCP)
- Test provider integration and authentication
- Verify resources reach Ready/Synced states
- Ensure cleanup works correctly
- Catch issues that composition tests miss (AWS API behavior, timing, dependencies)

**Speed**: 20-40 minutes per test (slow!)

**When to use**:
- Before merging to main
- After implementing major features
- For critical paths in CI/CD (labeled PRs)
- **MANDATORY** for all features in this project

**Trade-offs**:
- ✅ High confidence (tests real AWS behavior)
- ✅ Catches integration issues
- ✅ Validates complete lifecycle
- ❌ Slow (20-40 minutes)
- ❌ Expensive (real cloud resources)
- ❌ Requires cloud credentials

---

## E2E Test Structure

### Schema Definition

```kcl
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

test = metav1alpha1.E2ETest {
    metadata.name: "e2etest-xvpc-<feature>"
    spec = {
        # Crossplane version (REQUIRED!)
        crossplane: {
            version: "2.0.2-up.5"
            autoUpgrade: {
                channel: "Rapid"
            }
        }

        # Timeouts
        timeoutSeconds: 1800              # Resource creation (30 min)
        cleanupTimeoutSeconds: 600        # Cleanup (10 min)

        # Cleanup settings
        skipDelete: False                 # MUST be False for cleanup verification

        # Validation conditions
        defaultConditions: ["Ready", "Synced"]

        # Test manifests (your XR/Claim)
        manifests: [
            {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: { name: "e2e-test-vpc" }
                spec: {
                    # Your configuration here
                }
            }
        ]

        # Extra resources (ProviderConfig, Secrets, etc.)
        extraResources: [
            {
                # ProviderConfig for AWS authentication
            }
        ]
    }
}
```

### Key Fields

| Field | Purpose | Example | Required |
|-------|---------|---------|----------|
| `crossplane.version` | Crossplane version for control plane | `"2.0.2-up.5"` | ✅ YES |
| `timeoutSeconds` | Max time for resource creation | `1800` (30 min) | ✅ YES |
| `cleanupTimeoutSeconds` | Max time for cleanup | `600` (10 min) | ✅ YES |
| `skipDelete` | Skip cleanup (for debugging) | `False` | ✅ YES (must be False in committed tests) |
| `defaultConditions` | Conditions all resources must meet | `["Ready", "Synced"]` | ✅ YES |
| `manifests` | XR/Claims to create | Array of resources | ✅ YES |
| `extraResources` | Supporting resources | ProviderConfig, Secrets | ✅ YES (for ProviderConfig) |

---

## Control Plane Setup

### Auto-Provisioned Control Planes

E2E tests automatically create **ephemeral control planes** in Upbound Spaces:

**What happens**:
1. `up test run --e2e` triggers control plane creation
2. Upbound Spaces provisions a new Kubernetes cluster
3. Crossplane is installed (version from test spec)
4. AWS provider is installed and configured
5. Your configuration package is installed
6. Test manifests are applied
7. After test completes, control plane is deleted

**Duration**: Control plane setup takes 2-3 minutes

**Visibility**: View in Upbound Console → Organizations → solutions → Spaces

**Naming**: Control planes are named after test: `e2etest-xvpc-<feature>`

### Crossplane Version

**CRITICAL**: Always specify Crossplane version in E2E tests!

```kcl
crossplane: {
    version: "2.0.2-up.5"  # Crossplane v2 with Upbound extensions
    autoUpgrade: {
        channel: "Rapid"    # Auto-upgrade to latest in channel
    }
}
```

**Why this matters**:
- Default Crossplane version may be v1 (incompatible with v2 APIs)
- Missing version causes package installation failure
- Error: `no kind "CompositeResourceDefinition" is registered for version "apiextensions.crossplane.io/v2"`

**Lesson learned**: If test hangs at "Waiting for package to be ready" for >3 minutes, check `kubectl get pkgrev -oyaml` on control plane for UnhealthyPackageRevision.

---

## ProviderConfig Configuration

### IAM Role Authentication (Recommended)

**Always use IAM role**, never static credentials:

```kcl
extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"
        kind: "ProviderConfig"
        metadata: {
            name: "default"
        }
        spec: {
            credentials: {
                source: "Upbound"  # Use Upbound-managed credentials
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

### IAM Role for This Project

**Role**: `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`

**Permissions**: EC2 full access (VPC, Subnet, NAT, IGW, Routes, etc.)

**Trust policy**: Allows Upbound to assume role

**Region**: us-west-2 (default for E2E tests)

### Why IAM Role > Static Credentials

| Method | Security | Rotation | Auditing | Recommendation |
|--------|----------|----------|----------|----------------|
| **IAM Role** | ✅ High | ✅ Automatic | ✅ CloudTrail | **USE THIS** |
| Static Keys | ❌ Low | ❌ Manual | ⚠️ Limited | **NEVER USE** |

**Security benefits**:
- No credentials in code or git
- Automatic credential rotation
- Centralized permission management
- Auditable via CloudTrail
- Temporary credentials (1-hour tokens)

---

## Test Execution Phases

E2E tests go through 7 phases from build to cleanup. Understanding these phases helps debug issues.

### Phase 1: Build & Package (Local) - 1-2 minutes

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

**Success criteria**:
- ✅ All steps show checkmarks
- ✅ No compilation errors
- ✅ Package built successfully

**Common issues**:
- ❌ KCL syntax errors → Fix in test main.k
- ❌ Missing dependencies → Update kcl.mod
- ❌ Invalid schema fields → Remove unsupported fields

---

### Phase 2: Control Plane Setup (Upbound Cloud) - 2-3 minutes

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
Pushing function package xpkg.upbound.io/solutions/configuration-aws-vpc_vpc ✓
Pushing configuration image xpkg.upbound.io/solutions/configuration-aws-vpc:v0.0.0-XXXXXX ✓
Applying Init Resources ✓
Installing package on development control plane ✓
Waiting for package to be ready ...
```

**Success criteria**:
- ✅ Control plane created (visible in Upbound Console)
- ✅ Package pushed to registry
- ✅ Package installed and healthy
- ✅ AWS provider installed and authenticated

**Where to check**:
- **Upbound Console**: https://console.upbound.io/
- Navigate to: Organizations → solutions → Spaces
- Look for: Development control plane (ephemeral)
- Check: Package status should be "Healthy" or "Installed"

**Common issues**:
- ❌ Package fails to install → Check provider dependencies
- ❌ Provider not ready → Wait for AWS provider installation
- ❌ Authentication fails → Verify ProviderConfig with IAM role
- ❌ Hangs >3 minutes → Check `kubectl get pkgrev -oyaml` for errors

---

### Phase 3: Apply Test Manifests - 1 minute

**What happens**:
1. Apply VPC Composite Resource (XR/Claim)
2. Apply ProviderConfig (AWS authentication)
3. Composition function executes (generates managed resources)
4. Crossplane creates managed resources
5. AWS provider syncs with AWS

**Expected output**:
```
Applying test manifests ...
Created: VPC/e2e-test-basic-vpc
Created: ProviderConfig/default
Waiting for resources to be ready ...
```

**Success criteria**:
- ✅ All managed resources created
- ✅ No error events in resource status
- ✅ Resources show in AWS Console

**Where to check**:
- **Upbound Console**: Control Plane → Managed Resources
  - Filter by Kind (VPC, Subnet, InternetGateway, etc.)
  - Status should be: Creating → Syncing → Ready
- **AWS Console**: https://console.aws.amazon.com/vpc
  - Region: us-west-2
  - Tags: Look for `Environment=e2e-test`, `TestName=<feature>`

---

### Phase 4: Wait for Ready/Synced (AWS) - 15-30 minutes

**This is the LONGEST phase.** AWS takes time to create and configure resources.

**What happens**:
1. **VPC Creation** - AWS creates VPC (~30 seconds)
2. **Subnet Creation** - AWS creates subnets (~1-2 minutes)
3. **IGW Creation & Attachment** - AWS creates and attaches IGW (~2-3 minutes)
4. **Route Table Creation** - AWS creates route tables (~1 minute)
5. **Route Creation** - AWS adds routes (~1 minute)
6. **Route Table Associations** - AWS associates subnets (~1-2 minutes)
7. **NAT Gateway Creation** (if enabled) - AWS creates NAT (~10-15 minutes) ← SLOW!
8. **Crossplane Syncing** - Crossplane verifies resources (~5-10 minutes)
9. **Condition Checking** - Test framework verifies Ready AND Synced (~1-2 minutes)

**Expected output**:
```
Waiting for resources to be ready ...
[Long wait - 15-30 minutes]
VPC: Ready ✓
Subnet (us-west-2a): Ready ✓
Subnet (us-west-2b): Ready ✓
Subnet (us-west-2c): Ready ✓
InternetGateway: Ready ✓
RouteTable: Ready ✓
Route: Ready ✓
RouteTableAssociation (us-west-2a): Ready ✓
RouteTableAssociation (us-west-2b): Ready ✓
RouteTableAssociation (us-west-2c): Ready ✓
All resources Ready and Synced ✓
```

**Success criteria**:
- ✅ All managed resources reach "Ready" condition
- ✅ All managed resources reach "Synced" condition
- ✅ No error events or failed conditions
- ✅ Resources functional in AWS

**AWS Resource States**:
- VPC: `available` state
- Subnets: `available` state
- Internet Gateway: `attached` state
- Route Tables: `active` with routes
- Routes: `active` state
- NAT Gateway: `available` state (takes 10-15 min!)
- Associations: Subnets associated with route tables

**Monitoring progress**:

*Upbound Console* (Real-time):
1. Navigate to Control Plane → Managed Resources
2. Watch status change: Creating → Syncing → Ready
3. Click on each resource to see conditions

*AWS Console* (Actual Resources):
1. **VPCs**: https://console.aws.amazon.com/vpc → Your VPCs
   - Look for: CIDR block matching test (10.0.0.0/16, etc.)
   - State: available
   - Tags: Environment=e2e-test, TestName=<feature>

2. **Subnets**: https://console.aws.amazon.com/vpc → Subnets
   - Look for: CIDR blocks from test
   - State: available
   - Auto-assign public IPv4: Yes (for public subnets)

3. **Internet Gateway**: https://console.aws.amazon.com/vpc → Internet Gateways
   - State: attached
   - Attached VPC: The test VPC

4. **Route Tables**: https://console.aws.amazon.com/vpc → Route Tables
   - Look for: Public route table with route to IGW
   - Routes: 0.0.0.0/0 → igw-xxxxx
   - Associations: 3 explicit associations

**Common issues**:
- ⏱️ **Timeout** - Test times out before resources ready
  - Cause: AWS slow, or stuck resource, or timeout too short
  - Check: AWS console for failed resources
  - Action: Increase timeout or delete stuck resources

- ❌ **IAM Permission Denied**
  - Error: "User: ... is not authorized to perform: ec2:CreateVpc"
  - Cause: IAM role lacks permissions
  - Action: Update IAM role with EC2 full access

- ❌ **Subnet CIDR Conflict**
  - Error: "The CIDR '10.0.1.0/24' conflicts with another subnet"
  - Cause: Overlapping CIDR blocks or leftover resources
  - Action: Use different CIDR ranges or cleanup old resources

- ❌ **IGW Attachment Timeout**
  - Symptom: IGW stuck in "attaching" state
  - Cause: AWS API delay
  - Action: Wait longer or delete and retry

- ❌ **NAT Gateway Timeout**
  - Symptom: NAT stuck in "pending" state
  - Cause: NAT takes 10-15 minutes to reach available
  - Action: Increase timeout to 30+ minutes for NAT tests

---

### Phase 5: Test Validation - 1 minute

**What happens**:
1. Condition verification - Test framework checks all defaultConditions met
2. Resource count check - Verifies expected number of resources created
3. Status field check - Validates XR status fields populated

**Expected output**:
```
Validating test results ...
✓ All resources Ready
✓ All resources Synced
✓ Expected resource count: 10/10
✓ No error events
Test validation: PASSED ✓
```

**Success criteria**:
- ✅ defaultConditions met (["Ready", "Synced"])
- ✅ All managed resources exist
- ✅ No failure conditions
- ✅ XR status populated (if status fields defined)

---

### Phase 6: Cleanup - 5-10 minutes

**This phase is CRITICAL** - we must verify NO resources are orphaned in AWS.

**What happens**:
1. Delete test manifests (XR/Claim)
2. Crossplane cascade delete (deletes all managed resources)
3. AWS resource deletion in dependency order:
   - Delete Route Table Associations
   - Delete Routes
   - Delete Route Tables (non-main)
   - Delete Subnets
   - Delete NAT Gateways (5-10 minutes!)
   - Release Elastic IPs
   - Detach Internet Gateway
   - Delete Internet Gateway
   - Delete VPC
4. Verify deletion - Test framework verifies all resources deleted
5. Control plane cleanup - Deletes ephemeral control plane

**Expected output**:
```
Cleaning up test resources ...
Deleting VPC/e2e-test-basic-vpc ...
Waiting for resources to be deleted ...
Route table associations deleted ✓
Routes deleted ✓
Route tables deleted ✓
Subnets deleted ✓
NAT gateway(s) deleted ✓
Elastic IP(s) released ✓
Internet gateway detached ✓
Internet gateway deleted ✓
VPC deleted ✓
All resources cleaned up ✓
Control plane deleted ✓
```

**Success criteria**:
- ✅ All managed resources deleted from control plane
- ✅ All AWS resources deleted from AWS Console
- ✅ No orphaned resources in AWS
- ✅ Control plane deleted from Spaces

**Verification (MANDATORY)**:

After test completes, MANUALLY verify cleanup in AWS Console:

```bash
# VPCs - MUST be empty
https://console.aws.amazon.com/vpc → Your VPCs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Subnets - MUST be empty
https://console.aws.amazon.com/vpc → Subnets
Filter: CIDR contains test CIDR
Expected: NO RESULTS

# Internet Gateways - MUST be empty
https://console.aws.amazon.com/vpc → Internet Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# NAT Gateways - MUST be empty (EXPENSIVE!)
https://console.aws.amazon.com/vpc → NAT Gateways
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Elastic IPs - MUST be empty
https://console.aws.amazon.com/ec2 → Elastic IPs
Filter: Tags → TestName=<feature>
Expected: NO RESULTS

# Route Tables - Custom tables MUST be empty
https://console.aws.amazon.com/vpc → Route Tables
Filter: Tags → TestName=<feature>
Expected: NO RESULTS (main/default tables are OK)
```

**Common issues**:

⚠️ **Resources Not Deleted**:
- Symptom: Resources remain in AWS after test
- Cause: Dependency blocking deletion, or Crossplane bug, or timeout
- Action: Manual cleanup required (see manual cleanup commands below)

⚠️ **Deletion Timeout**:
- Symptom: Test times out during cleanup
- Cause: AWS resources slow to delete (NAT takes 5-10 min!)
- Action: Verify in AWS console if actually deleted

⚠️ **Cost Alert**:
- If resources NOT deleted: You will be charged!
- NAT Gateway: ~$0.045/hour ($32/month)
- EIP (unattached): $0.005/hour
- **Always verify cleanup!**

**Manual cleanup commands** (if resources not deleted):

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
# WAIT 5-10 minutes for NAT to delete!

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

### Phase 7: Test Result - 1 second

**What happens**:
- Test framework reports final result
- Logs written to test output
- Exit code returned (0 = success, 1 = failure)

**Expected output (Success)**:
```
Test: e2etest-xvpc-basic
Status: PASSED ✓
Duration: 38m 42s
Resources Created: 10
Resources Cleaned: 10
```

**Expected output (Failure)**:
```
Test: e2etest-xvpc-basic
Status: FAILED ✗
Duration: 40m 00s (timeout)
Error: Resource VPC/e2e-test-basic-vpc failed to reach Ready condition
Reason: IAM permissions denied
```

---

## Resource Creation Timelines

Understanding how long each test scenario takes helps with timeout planning.

### Complete Phase Timeline

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

### Resources Created by Test Scenario

**Test 1: Basic VPC** (25-30 minutes)
- 1 VPC
- 3 Public Subnets
- 1 Internet Gateway
- 1 Public Route Table
- 1 Route (0.0.0.0/0 → IGW)
- 3 Route Table Associations
- **Total: 10 resources**

**Test 2: NAT Single** (35-40 minutes)
- 1 VPC
- 3 Public Subnets
- 3 Private Subnets
- 1 Internet Gateway
- 1 Elastic IP
- 1 NAT Gateway ← **SLOW (10-15 min)**
- 1 Public Route Table + 1 Route + 3 Associations
- 1 Private Route Table + 1 Route + 3 Associations
- **Total: 21 resources**

**Test 3: NAT Per AZ** (40-45 minutes)
- 1 VPC
- 3 Public Subnets
- 3 Private Subnets
- 1 Internet Gateway
- 3 Elastic IPs
- 3 NAT Gateways ← **VERY SLOW (3 × 10-15 min)**
- 1 Public Route Table + 1 Route + 3 Associations
- 3 Private Route Tables + 3 Routes + 3 Associations
- **Total: 27 resources**

**Test 4: Complete VPC** (45-50 minutes)
- 1 VPC
- 18 Subnets (3 public, 3 private, 3 database, 3 elasticache, 3 redshift, 3 intra)
- 1 Internet Gateway
- 1 Elastic IP
- 1 NAT Gateway
- 1 Public Route Table + 1 Route + 3 Associations
- 1 Private Route Table + 1 Route + 3 Associations
- 1 Database Route Table + 1 Route + 3 Associations
- 3 Isolated Route Tables + 9 Associations
- **Total: 45+ resources**

---

## Monitoring During Execution

### Real-time Progress Checks

**Check every 5 minutes:**
```bash
# Local - Check test output
up test run tests/e2etest-xvpc-<feature> --e2e

# Or if running in background
cat /tmp/claude/<path>/tasks/<task-id>.output
```

**Upbound Console**:
1. Login: https://console.upbound.io
2. Navigate: Organizations → solutions → Spaces
3. Look for: Development control plane (e2etest-xvpc-<feature>)
4. Click: Control Plane → Managed Resources
5. Filter: By Kind (VPC, Subnet, etc.)
6. Watch: Status progression (Creating → Syncing → Ready)

**AWS Console**:
1. Login: https://console.aws.amazon.com
2. Region: **us-west-2**
3. Service: VPC
4. Filter: By tags (TestName=<feature>)
5. Watch: Resources being created

---

## Cleanup Verification

See [Phase 6: Cleanup](#phase-6-cleanup---5-10-minutes) for complete verification checklist.

**Critical checklist after EVERY E2E test**:
- [ ] VPCs deleted (filter by tags)
- [ ] Subnets deleted (filter by CIDR)
- [ ] Internet Gateways deleted
- [ ] **NAT Gateways deleted** (EXPENSIVE!)
- [ ] **Elastic IPs released** (billable if unattached)
- [ ] Route Tables deleted (except default/main)
- [ ] Control plane deleted from Upbound Spaces

**Cost if not cleaned up**:
- NAT Gateway: $32/month
- EIP (unattached): $3.60/month
- VPC/Subnets/Routes: Free (but clutter account)

---

## Troubleshooting

### Issue: Test Hangs at "Waiting for package to be ready"

**Symptoms**: Test stuck for >3 minutes at package installation

**Diagnosis**: Package installation failing or provider not ready

**Check**:
1. Upbound Console → Control Plane → Packages
2. Look for package status (should be "Healthy")
3. Check provider status (AWS provider should be "Healthy")
4. **Critical**: Check `kubectl get pkgrev -oyaml` for UnhealthyPackageRevision

**Solution**:
- Wait 5 more minutes (provider installation can be slow)
- If still stuck, check for Crossplane version mismatch
- Ensure `crossplane.version = "2.0.2-up.5"` is set in test
- Check provider logs in Upbound Console

---

### Issue: "IAM role cannot be assumed"

**Symptoms**: Resources fail to create with authentication error

**Error**: `User: ... is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`

**Diagnosis**: Provider can't authenticate with AWS

**Check**:
1. ProviderConfig IAM role ARN is correct
2. IAM role exists in AWS
3. IAM role has trust policy allowing Upbound

**Solution**:
- Verify ProviderConfig uses correct role ARN
- Ensure `source: "Upbound"` (not "Secret")
- Check IAM role trust policy allows Upbound to assume it
- Verify role has EC2 permissions

---

### Issue: Resources Not Cleaning Up

See [Phase 6: Cleanup - Common Issues](#phase-6-cleanup---5-10-minutes) for manual cleanup commands.

---

## Cost Management

### Cost Per Test

**Typical E2E test cost** (if cleanup works):
- ✅ $0.00 - $0.10 per test (resources exist <1 hour)

**If cleanup fails** (resources orphaned):
- ❌ NAT Gateway: $0.045/hour = $32/month
- ❌ Elastic IP (unattached): $0.005/hour = $3.60/month
- ❌ VPC, Subnets, Routes: Free (but clutter account)

### Verify Costs

```bash
# Check AWS Cost Explorer
# Filter: us-west-2, Last 1 day
# Services: EC2, VPC
# Expected cost: ~$0.00 - $0.10 per test
# Concerning cost: >$1.00 = resources not cleaned up!
```

### Cost Alerts

Set up AWS Cost Alerts:
1. AWS Console → Billing → Budgets
2. Create budget: "E2E Tests"
3. Amount: $5/day
4. Alert if exceeded

---

## CI/CD Integration

### GitHub Actions

**Composition tests**: Run on every PR (fast, free)

**E2E tests**: Run only on labeled PRs (slow, costs money)

```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on:
  pull_request:
    types: [labeled]

jobs:
  e2e:
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e-tests')
    runs-on: ubuntu-latest
    timeout-minutes: 120  # 2 hours for all tests
    steps:
      - uses: actions/checkout@v3

      - name: Setup Upbound CLI
        run: curl -sL https://cli.upbound.io | sh

      - name: Login to Upbound
        run: up login -t ${{ secrets.UPBOUND_TOKEN }}

      - name: Run E2E Tests
        run: up test run tests/e2etest-* --e2e

      - name: Verify Cleanup
        if: always()
        run: |
          # Script to verify no AWS resources remain
          # Check for orphaned VPCs, NAT Gateways, EIPs
```

**Best practices**:
- ✅ Run composition tests on every PR
- ✅ Run E2E tests only when labeled (saves time/cost)
- ✅ Set timeout for E2E job (2 hours max)
- ✅ Fail pipeline if any E2E test fails
- ✅ Verify cleanup in separate step
- ✅ Use GitHub secrets for UPBOUND_TOKEN

---

## Advanced Topics

### Running Tests in Parallel

E2E tests CAN run in parallel if they use different CIDR blocks:

```bash
# All tests use unique CIDRs:
# Test 1: 10.0.0.0/16
# Test 2: 10.1.0.0/16
# Test 3: 10.2.0.0/16
# Test 4: 10.3.0.0/16

# Run in parallel (saves time in CI)
up test run tests/e2etest-xvpc-basic --e2e &
up test run tests/e2etest-xvpc-nat-single --e2e &
up test run tests/e2etest-xvpc-nat-per-az --e2e &
up test run tests/e2etest-xvpc-complete --e2e &
wait
```

**Benefits**: 4 tests complete in ~45 minutes (instead of 2.5-3 hours)

**Risks**: Higher AWS bill if cleanup fails on multiple tests

---

### Debugging Failed Tests

**Step 1**: Check test output for error message

**Step 2**: Check Upbound Console
- Control Plane → Managed Resources
- Look for resources with error events
- Click resource → View conditions and events

**Step 3**: Check AWS Console
- Verify resources exist in AWS
- Check resource states
- Look for AWS errors (permissions, quotas, etc.)

**Step 4**: Check AWS CloudTrail
- Find denied API calls
- Identify permission issues

**Step 5**: Manual verification
- Try creating resources manually in AWS Console
- Verify IAM permissions work

---

### Custom Timeouts

Adjust timeouts based on test complexity:

```kcl
spec = {
    # VPC only: 10 minutes
    timeoutSeconds: 600

    # VPC + Subnets + IGW: 20 minutes
    timeoutSeconds: 1200

    # VPC + NAT (single): 30 minutes
    timeoutSeconds: 1800

    # VPC + NAT (per-AZ): 40 minutes
    timeoutSeconds: 2400

    # Complete VPC (18 subnets): 50 minutes
    timeoutSeconds: 3000
}
```

---

## See Also

- [E2E Implementation Guide](e2e-implementation-guide.md) - Step-by-step guide to write E2E tests
- [Composition Testing](composition-testing.md) - Fast unit tests
- [Testing Overview](TESTING_OVERVIEW.md) - Testing strategy and philosophy
- [TDD Strategy](../development/TDD_STRATEGY.md) - Development workflow

---

## Summary

E2E tests are **MANDATORY** for validating compositions work in real cloud environments.

**Key points**:
- E2E tests create real AWS resources on Upbound Cloud
- Tests take 20-40 minutes (slow!)
- Always specify Crossplane version
- Use IAM role authentication (never static credentials)
- Verify cleanup after EVERY test (cost risk!)
- Run on labeled PRs in CI (not every commit)

**For implementation**: See [E2E Implementation Guide](e2e-implementation-guide.md)

**For strategy**: See [Testing Overview](TESTING_OVERVIEW.md)
