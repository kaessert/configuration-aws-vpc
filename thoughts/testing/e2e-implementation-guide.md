# E2E Test Implementation Guide

## Overview

This guide provides **step-by-step instructions** for writing End-to-End (E2E) tests for Upbound configurations. E2E tests validate that your compositions work correctly in real AWS environments.

**When to use this guide**: When you need to write E2E tests for implemented features (VPC, subnets, NAT Gateway, routing, etc.) to validate they work correctly in real AWS.

**Critical**: E2E tests are **MANDATORY** for all features. A feature is NOT complete until it passes E2E validation in real AWS.

---

## Quick Start (5 Minutes)

### Prerequisites

1. **Upbound CLI** installed (`up` command)
2. **Upbound account** authenticated (`up login`)
3. **Feature already implemented** with passing composition tests
4. **IAM role configured** (handled automatically by Upbound Cloud)

### Steps

1. Generate E2E test:
   ```bash
   up test generate e2etest-xvpc-<feature-name> --e2e --language=kcl
   ```

2. Edit `tests/e2etest-*/main.k` - configure test manifest and ProviderConfig

3. Run test:
   ```bash
   up test run tests/e2etest-xvpc-<feature-name> --e2e
   ```

4. Wait 20-40 minutes for AWS resource creation and cleanup

5. Verify cleanup in AWS Console

---

## Step-by-Step Workflow

### Step 1: Generate E2E Test Structure

```bash
# Example: E2E test for VPC creation
up test generate e2etest-xvpc-vpc --e2e --language=kcl

# Example: E2E test for subnets
up test generate e2etest-xvpc-subnets --e2e --language=kcl

# Example: E2E test for NAT Gateway
up test generate e2etest-xvpc-nat --e2e --language=kcl
```

**What this creates**:
```
tests/
└── e2etest-xvpc-<feature>/
    ├── main.k          # Test definition
    ├── kcl.mod         # Dependencies
    └── kcl.mod.lock    # Dependency lock file
```

---

### Step 2: Configure Test Manifest

Open `tests/e2etest-xvpc-<feature>/main.k` and configure the E2E test.

#### Template Structure

```kcl
"""
<Feature Name> E2E Test

Tests the <feature> with real AWS resources:
- <List what resources are created>
- Resources reach Ready/Synced state
- Proper cleanup after test

Spec: Validates <reference to feature in spec>
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-<feature>"
        spec= {
            # Crossplane configuration
            crossplane: {
                version: "2.0.2-up.5"
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts (see "Timeout Settings" section below)
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
                    }
                    spec: {
                        # Your feature configuration here
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

            # ProviderConfig for AWS authentication
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
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
            ]
        }
    }
]
items= _items
```

---

### Step 3: Configure ProviderConfig (AWS Authentication)

**CRITICAL**: Always use IAM role authentication. NEVER use static credentials!

#### ProviderConfig Template (Ready to Copy-Paste)

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Upbound
  assumeRoleChain:
    - roleARN: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
```

**In KCL** (for main.k):

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
                source: "Upbound"
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

**Why this matters**:
- ✅ `source: "Upbound"` - Uses Upbound Cloud-managed credentials
- ✅ `assumeRoleChain` - Assumes IAM role with proper permissions
- ✅ **Secure** - No credentials stored in code
- ❌ NEVER use `source: "Secret"` with static AWS keys

---

### Step 4: Set Timeout and Cleanup Options

#### Timeout Settings by Resource Type

| Resource Type | Recommended Timeout | Rationale |
|--------------|---------------------|-----------|
| VPC only | 600 seconds (10 min) | VPC creation is fast |
| VPC + Subnets | 900 seconds (15 min) | Subnets take 1-2 min each |
| VPC + IGW + Routes | 1200 seconds (20 min) | IGW attachment can be slow |
| **NAT Gateway** | **1800 seconds (30 min)** | NAT takes 10-15 min to reach Ready |
| Complete VPC (18 subnets) | 2400 seconds (40 min) | Many resources, longer wait |

#### Cleanup Timeout

**Always set**: `cleanupTimeoutSeconds: 600` (10 minutes)

**Why**: AWS resource deletion takes time:
- Route table associations must delete first
- IGW must detach before deletion
- NAT Gateway takes 5-10 minutes to delete
- Subnets must be empty before deletion

#### Skip Delete (CRITICAL!)

**Always set**: `skipDelete: False`

**Why**: We MUST verify cleanup works correctly. Orphaned AWS resources:
- ❌ Cost money (NAT Gateway = $32/month!)
- ❌ Clutter the AWS account
- ❌ May interfere with future tests

**NEVER use `skipDelete: True` in committed tests!**

---

### Step 5: Run E2E Test

```bash
# Run specific E2E test
up test run tests/e2etest-xvpc-<feature> --e2e

# Run all E2E tests (takes 2-4 hours!)
up test run tests/e2etest-* --e2e
```

**What happens** (25-47 minutes per test):

1. **Build & Package** (1-2 min) - Compile KCL functions
2. **Control Plane Setup** (2-3 min) - Provision ephemeral control plane in Upbound Cloud
3. **Apply Manifests** (1 min) - Create VPC and ProviderConfig
4. **Wait for Ready/Synced** (15-30 min) ← **LONGEST PHASE** - AWS creates resources
5. **Validation** (1 min) - Verify all resources reached Ready/Synced
6. **Cleanup** (5-10 min) ← **CRITICAL** - Delete all AWS resources
7. **Report** (1 sec) - Display results

**Expected output**:
```
Parsing tests ✓
Building configuration package ✓
Creating development control plane in Spaces ✓
Pushing configuration image ✓
Installing package on development control plane ✓
Waiting for package to be ready ...
Applying test manifests ...
Waiting for resources to be ready ...
[Long wait - 15-30 minutes]
All resources Ready and Synced ✓
Cleaning up test resources ...
All resources deleted ✓
Test: PASSED ✓
Duration: 38m 42s
```

---

### Step 6: Monitor Test Execution

#### Monitor in Upbound Console

1. Login: https://console.upbound.io
2. Navigate: **Organizations → solutions → Spaces**
3. Find: Development control plane (e2etest-xvpc-<feature>)
4. Click: **Control Plane → Managed Resources**
5. Watch: Status progression (Creating → Syncing → Ready)

**What to check**:
- ✅ All managed resources appear (VPC, Subnet, IGW, etc.)
- ✅ Status changes: Creating → Syncing → Ready
- ✅ No error events in resource details
- ✅ Conditions show: Ready=True, Synced=True

#### Monitor in AWS Console

1. Login: https://console.aws.amazon.com
2. Region: **us-west-2**
3. Service: **VPC**
4. Filter by tags:
   - `Environment=e2e-test`
   - `TestName=<feature>`

**What to check**:
- ✅ Resources appear in AWS (VPC, Subnets, IGW, etc.)
- ✅ Resources reach proper AWS state (available, attached, active)
- ✅ Tags are applied correctly
- ✅ Configuration matches test manifest

---

### Step 7: Verify Cleanup (CRITICAL!)

**After test completes**, verify ALL resources are deleted from AWS:

#### AWS Console Cleanup Verification Checklist

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

#### If Resources Are NOT Deleted

**Manual cleanup required!** Use AWS CLI:

```bash
# Get VPC ID from AWS Console
VPC_ID="vpc-xxxxx"

# Delete in reverse dependency order:

# 1. Delete route table associations
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].Associations[*].RouteTableAssociationId' --output text | xargs -n1 aws ec2 disassociate-route-table --association-id

# 2. Delete routes (except local)
# (Do this manually in AWS Console - safer)

# 3. Delete NAT Gateway (takes 5-10 minutes!)
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text | xargs -n1 aws ec2 delete-nat-gateway --nat-gateway-id
# Wait 5-10 minutes for NAT Gateway to delete!

# 4. Release Elastic IPs
aws ec2 describe-addresses --filters "Name=tag:TestName,Values=<feature>" --query 'Addresses[*].AllocationId' --output text | xargs -n1 aws ec2 release-address --allocation-id

# 5. Delete Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# 6. Delete Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text | xargs -n1 aws ec2 delete-subnet --subnet-id

# 7. Delete Route Tables (non-main)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" --query 'RouteTables[*].RouteTableId' --output text | xargs -n1 aws ec2 delete-route-table --route-table-id

# 8. Delete VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

---

## Feature-Specific Examples

### Example 1: E2E Test for VPC Creation

**Feature**: Basic VPC creation (Task 2.1)

**What to test**:
- VPC with specified CIDR block
- DNS support and hostnames enabled
- Tags applied correctly
- VPC reaches Ready state

**Test manifest** (`tests/e2etest-xvpc-vpc/main.k`):

```kcl
manifests: [
    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "VPC"
        metadata: {
            name: "e2e-test-vpc"
        }
        spec: {
            region: "us-west-2"
            cidr: "10.0.0.0/16"
            enableDnsSupport: True
            enableDnsHostnames: True
            tags: {
                Environment: "e2e-test"
                ManagedBy: "upbound"
                TestName: "vpc-creation"
            }
        }
    }
]
```

**Timeout**: `timeoutSeconds: 600` (10 minutes)

**Expected AWS resources**: 1 VPC

---

### Example 2: E2E Test for Subnets

**Feature**: Subnet creation with public/private types (Task 2.2)

**What to test**:
- VPC with public and private subnets
- Subnets across multiple AZs
- Map public IP on launch for public subnets
- Subnet tags applied correctly

**Test manifest**:

```kcl
manifests: [
    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "VPC"
        metadata: {
            name: "e2e-test-subnets"
        }
        spec: {
            region: "us-west-2"
            cidr: "10.0.0.0/16"
            azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
            publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
            privateSubnets: ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
            mapPublicIpOnLaunch: True
            tags: {
                Environment: "e2e-test"
                ManagedBy: "upbound"
                TestName: "subnets"
            }
            publicSubnetTags: {
                Tier: "public"
            }
            privateSubnetTags: {
                Tier: "private"
            }
        }
    }
]
```

**Timeout**: `timeoutSeconds: 1200` (20 minutes)

**Expected AWS resources**:
- 1 VPC
- 6 Subnets (3 public, 3 private)

---

### Example 3: E2E Test for NAT Gateway

**Feature**: NAT Gateway with single or per-AZ strategy (Task 2.4)

**What to test**:
- VPC with public and private subnets
- NAT Gateway created in public subnet
- Elastic IP allocated for NAT Gateway
- Private route table routes through NAT Gateway
- NAT Gateway reaches Ready state (takes 10-15 minutes!)

**Test manifest**:

```kcl
manifests: [
    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "VPC"
        metadata: {
            name: "e2e-test-nat"
        }
        spec: {
            region: "us-west-2"
            cidr: "10.0.0.0/16"
            azs: ["us-west-2a", "us-west-2b"]
            publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
            privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
            enableNatGateway: True
            singleNatGateway: True  # Or oneNatGatewayPerAz: True
            tags: {
                Environment: "e2e-test"
                ManagedBy: "upbound"
                TestName: "nat-gateway"
            }
        }
    }
]
```

**Timeout**: `timeoutSeconds: 1800` (30 minutes) ← **CRITICAL: NAT is slow!**

**Expected AWS resources**:
- 1 VPC
- 4 Subnets (2 public, 2 private)
- 1 Internet Gateway
- 1 NAT Gateway (or more for per-AZ)
- 1 Elastic IP (or more for per-AZ)
- 2 Route Tables (public, private)
- Routes and associations

**Cost warning**: NAT Gateway costs $0.045/hour ($32/month). Cleanup is CRITICAL!

---

### Example 4: E2E Test for Routing

**Feature**: Route tables and routing logic (Task 2.5)

**What to test**:
- VPC with Internet Gateway
- Public route table routes to IGW (0.0.0.0/0 → igw-xxx)
- Private route table (if NAT: routes to NAT)
- Route table associations to subnets
- All routes reach Active state

**Test manifest**:

```kcl
manifests: [
    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "VPC"
        metadata: {
            name: "e2e-test-routing"
        }
        spec: {
            region: "us-west-2"
            cidr: "10.0.0.0/16"
            azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
            publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
            mapPublicIpOnLaunch: True
            tags: {
                Environment: "e2e-test"
                ManagedBy: "upbound"
                TestName: "routing"
            }
        }
    }
]
```

**Timeout**: `timeoutSeconds: 1200` (20 minutes)

**Expected AWS resources**:
- 1 VPC
- 3 Public Subnets
- 1 Internet Gateway
- 1 Public Route Table
- 1 Route (0.0.0.0/0 → IGW)
- 3 Route Table Associations

---

## Troubleshooting Common Issues

### Issue 1: Test Hangs at "Waiting for package to be ready"

**Symptoms**: Test stuck for >10 minutes at package installation

**Diagnosis**: Package installation failing or provider not ready

**Check**:
1. Upbound Console → Control Plane → Packages
2. Look for package status: Should be "Healthy" or "Installed"
3. Check provider status: AWS provider should be "Healthy"

**Solution**:
- Wait 5 more minutes (provider installation can be slow)
- If still stuck, check provider logs in Upbound Console
- Verify ProviderConfig is correct

---

### Issue 2: "IAM role cannot be assumed"

**Symptoms**: Resources fail to create with authentication error

**Error message**: `User: ... is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`

**Diagnosis**: Provider can't authenticate with AWS

**Check**:
1. ProviderConfig IAM role ARN is correct
2. IAM role exists in AWS
3. IAM role has trust policy for Upbound

**Solution**:
- Verify ProviderConfig uses correct IAM role ARN
- Ensure `source: "Upbound"` (not "Secret")
- Check IAM role trust policy allows Upbound to assume it

---

### Issue 3: "VPC creation failed" or "Permission denied"

**Symptoms**: VPC resource fails with AWS API error

**Error message**: `User: ... is not authorized to perform: ec2:CreateVpc`

**Diagnosis**: IAM role lacks necessary permissions

**Check**:
1. AWS CloudTrail for denied API calls
2. IAM role permissions (should have EC2 full access)

**Solution**:
- Update IAM role with required EC2 permissions
- Ensure role has permissions for: VPC, Subnet, IGW, NAT, Routes, Route Tables

---

### Issue 4: Resources Not Cleaning Up

**Symptoms**: Test completes but AWS resources remain

**Diagnosis**: Dependencies blocking deletion, or Crossplane bug

**Check**:
1. AWS Console for resources in "deleting" state
2. Upbound Console for resources stuck in "Deleting"
3. Check for dependency errors in resource events

**Solution**:
- **Manual cleanup** (see "Step 7: Verify Cleanup" section above)
- Delete resources in reverse dependency order:
  1. Route table associations
  2. Routes
  3. Route tables
  4. NAT Gateways (wait 5-10 min for deletion!)
  5. Elastic IPs
  6. Internet Gateway (detach first!)
  7. Subnets
  8. VPC

---

### Issue 5: Test Times Out

**Symptoms**: Test reaches timeout before resources ready

**Diagnosis**: Timeout too short, or AWS is slow, or resources stuck

**Check**:
1. AWS Console: Are resources still creating?
2. Upbound Console: What's the status of resources?
3. Look for error events in resource details

**Solution**:
- **Increase timeout** if resources are creating slowly
- NAT Gateway needs 30+ minutes: `timeoutSeconds: 1800`
- Complete VPC (18 subnets) needs 40+ minutes: `timeoutSeconds: 2400`
- Check for stuck resources and investigate error events

---

## AWS Cost Monitoring

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

**Composition tests**: Run on every PR (fast, no cloud required)

**E2E tests**: Run only on labeled PRs (slow, requires Upbound Cloud)

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
    steps:
      - uses: actions/checkout@v3
      - name: Setup Upbound CLI
        run: curl -sL https://cli.upbound.io | sh
      - name: Login to Upbound
        run: up login -t ${{ secrets.UPBOUND_TOKEN }}
      - name: Run E2E Tests
        run: up test run tests/e2etest-* --e2e
        timeout-minutes: 120  # 2 hours for all tests
```

**Best practices**:
- ✅ Run composition tests on every PR
- ✅ Run E2E tests only when labeled (saves time and cost)
- ✅ Set timeout for E2E job (2 hours max)
- ✅ Fail pipeline if any E2E test fails
- ✅ Verify cleanup in separate step

---

## Best Practices

### DO:
- ✅ Write E2E tests for ALL major features
- ✅ Use IAM role authentication (never static credentials)
- ✅ Set appropriate timeouts (NAT = 30 min, VPC = 10 min)
- ✅ Always set `skipDelete: False` for cleanup verification
- ✅ Verify cleanup in AWS Console after test
- ✅ Tag resources with `Environment: e2e-test` for easy filtering
- ✅ Run composition tests first (fast feedback)
- ✅ Run E2E tests before merging to main

### DON'T:
- ❌ Skip E2E tests for "simple" features
- ❌ Use static AWS credentials (security risk!)
- ❌ Set `skipDelete: True` in committed tests
- ❌ Forget to verify cleanup (cost risk!)
- ❌ Use production AWS account for E2E tests
- ❌ Run E2E tests on every commit (too slow)
- ❌ Commit failing E2E tests

---

## Quick Reference

### Common Commands

```bash
# Generate E2E test
up test generate e2etest-xvpc-<feature> --e2e --language=kcl

# Run specific E2E test
up test run tests/e2etest-xvpc-<feature> --e2e

# Run all E2E tests
up test run tests/e2etest-* --e2e

# Login to Upbound
up login

# Check Upbound profile
up whoami
```

### Timeout Recommendations

| Test Scenario | Timeout | Cleanup Timeout |
|--------------|---------|-----------------|
| VPC only | 600s (10 min) | 600s (10 min) |
| VPC + Subnets | 900s (15 min) | 600s (10 min) |
| VPC + IGW + Routes | 1200s (20 min) | 600s (10 min) |
| **VPC + NAT** | **1800s (30 min)** | **600s (10 min)** |
| Complete VPC | 2400s (40 min) | 900s (15 min) |

### ProviderConfig Quick Copy

```kcl
extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"
        kind: "ProviderConfig"
        metadata: { name: "default" }
        spec: {
            credentials: { source: "Upbound" }
            assumeRoleChain: [
                { roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws" }
            ]
        }
    }
]
```

---

## See Also

- [E2E Testing Reference](e2e-testing.md) - Complete E2E testing documentation
- [Composition Testing](composition-testing.md) - Writing composition tests
- [Testing Overview](TESTING_OVERVIEW.md) - Testing strategy and philosophy
- [TDD Strategy](../development/TDD_STRATEGY.md) - Test-driven development workflow

---

## Summary

E2E tests are **MANDATORY** for all features. They validate that your compositions work correctly in real AWS environments.

**Key takeaways**:
1. Generate test with `up test generate e2etest-xvpc-<feature> --e2e --language=kcl`
2. Configure test manifest with feature parameters
3. Use IAM role authentication (NEVER static credentials)
4. Set appropriate timeout (NAT = 30 min, others = 10-20 min)
5. Always enable cleanup (`skipDelete: False`)
6. Run test with `up test run tests/e2etest-xvpc-<feature> --e2e`
7. Wait 20-40 minutes for AWS resource creation and cleanup
8. **VERIFY cleanup** in AWS Console (CRITICAL to avoid costs!)

**Now you're ready to write E2E tests!** Start with Task 0.1 and write E2E tests for all implemented features.
