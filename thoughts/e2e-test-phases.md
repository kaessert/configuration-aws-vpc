# E2E Test Phases - Expected Behavior

## Overview

E2E tests go through multiple phases, from building the package to creating real AWS resources, waiting for them to become ready, and finally cleaning them up. This document explains what happens in each phase and how to verify success.

---

## Phase 1: Build and Package (Local) - ~1-2 minutes

### What Happens:
1. **Parse Tests** - Validates KCL syntax in test files
2. **Collect Resources** - Gathers all resources needed
3. **Generate Language Schemas** - Creates type definitions
4. **Check Dependencies** - Verifies all required packages
5. **Build Functions** - Compiles KCL composition functions
6. **Build Configuration Package** - Creates the .uppkg file

### Expected Output:
```
Parsing tests ✓
Collecting resources ✓
Generating language schemas ✓
Checking dependencies ✓
Building functions ✓
Building configuration package ✓
```

### Success Criteria:
- ✅ All steps show checkmarks (✓)
- ✅ No compilation errors
- ✅ Package built successfully

### Common Issues:
- ❌ KCL syntax errors → Fix in test main.k files
- ❌ Missing dependencies → Update kcl.mod
- ❌ Invalid schema fields → Remove unsupported fields

---

## Phase 2: Control Plane Setup (Upbound Cloud) - ~2-3 minutes

### What Happens:
1. **Create Development Control Plane** - Spins up ephemeral control plane in Upbound Spaces
2. **Ensure Repository Exists** - Creates or verifies container registry
3. **Push Function Package** - Uploads KCL function to registry
4. **Push Configuration Image** - Uploads main configuration package
5. **Apply Init Resources** - Installs Crossplane CRDs and providers
6. **Install Package** - Installs your configuration on control plane
7. **Wait for Package Ready** - Waits for package to reach Installed state

### Expected Output:
```
Creating development control plane in Spaces ✓
Ensuring repository exists ✓
Pushing function package xpkg.upbound.io/solutions/configuration-aws-vpc_vpc ✓
Pushing configuration image xpkg.upbound.io/solutions/configuration-aws-vpc:v0.0.0-XXXXXX ✓
Applying Init Resources ✓
Installing package on development control plane ✓
Waiting for package to be ready ...
```

### Success Criteria:
- ✅ Control plane created (visible in Upbound Console)
- ✅ Package pushed to registry
- ✅ Package installed and healthy
- ✅ AWS provider installed and authenticated

### Where to Check:
**Upbound Console**: https://console.upbound.io/
- Navigate to: Organizations → solutions → Spaces
- Look for: Development control plane (ephemeral)
- Check: Package status should be "Healthy" or "Installed"

### Common Issues:
- ❌ Package fails to install → Check provider dependencies
- ❌ Provider not ready → Wait for AWS provider installation
- ❌ Authentication fails → Verify ProviderConfig with IAM role

---

## Phase 3: Apply Test Manifests - ~1 minute

### What Happens:
1. **Apply VPC Composite Resource** - Creates the VPC XR
2. **Apply ProviderConfig** - Sets up AWS authentication
3. **Composition Function Executes** - Generates managed resources
4. **Managed Resources Created** - Crossplane creates AWS resources

### Expected Output:
```
Applying test manifests ...
Created: VPC/e2e-test-basic-vpc
Created: ProviderConfig/default
Waiting for resources to be ready ...
```

### What Gets Created (Test 1 - Basic VPC):
**Composite Resource (XR)**:
- `VPC/e2e-test-basic-vpc`

**Managed Resources (AWS)**:
- `VPC/vpc-e2e-test-basic-vpc` - The AWS VPC
- `Subnet/subnet-public-e2e-test-basic-vpc-us-west-2a` - Public subnet AZ a
- `Subnet/subnet-public-e2e-test-basic-vpc-us-west-2b` - Public subnet AZ b
- `Subnet/subnet-public-e2e-test-basic-vpc-us-west-2c` - Public subnet AZ c
- `InternetGateway/igw-e2e-test-basic-vpc` - Internet Gateway
- `RouteTable/rt-public-e2e-test-basic-vpc` - Public route table
- `Route/route-public-igw-e2e-test-basic-vpc` - Route to IGW
- `RouteTableAssociation/rta-public-e2e-test-basic-vpc-us-west-2a` - Association AZ a
- `RouteTableAssociation/rta-public-e2e-test-basic-vpc-us-west-2b` - Association AZ b
- `RouteTableAssociation/rta-public-e2e-test-basic-vpc-us-west-2c` - Association AZ c

**Total**: 1 VPC + 3 Subnets + 1 IGW + 1 RouteTable + 1 Route + 3 Associations = **10 AWS resources**

### Success Criteria:
- ✅ All managed resources created
- ✅ No error events in resource status
- ✅ Resources show in AWS Console (us-west-2)

### Where to Check:
**Upbound Console**:
- Navigate to: Control Plane → Managed Resources
- Filter by: Kind (VPC, Subnet, InternetGateway, etc.)
- Status should be: Creating → Syncing → Ready

**AWS Console**: https://console.aws.amazon.com/vpc
- Region: us-west-2
- Tags: Look for `ManagedBy: upbound-e2e`, `TestName: basic-vpc`
- VPCs: Should see 10.0.0.0/16 VPC
- Subnets: Should see 3 public subnets
- Internet Gateways: Should see IGW attached to VPC

---

## Phase 4: Wait for Ready/Synced (AWS) - ~15-30 minutes

This is the LONGEST phase. AWS takes time to create and configure resources.

### What Happens:
1. **VPC Creation** - AWS creates the VPC (~30 seconds)
2. **Subnet Creation** - AWS creates subnets (~1-2 minutes)
3. **IGW Creation & Attachment** - AWS creates and attaches IGW (~2-3 minutes)
4. **Route Table Creation** - AWS creates route table (~1 minute)
5. **Route Creation** - AWS adds route to IGW (~1 minute)
6. **Route Table Associations** - AWS associates subnets (~1-2 minutes)
7. **Crossplane Syncing** - Crossplane verifies all resources match desired state (~5-10 minutes)
8. **Condition Checking** - Test framework verifies Ready AND Synced conditions (~1-2 minutes)

### Expected Output:
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

### Success Criteria:
- ✅ All managed resources reach "Ready" condition
- ✅ All managed resources reach "Synced" condition
- ✅ No error events or failed conditions
- ✅ Resources functional in AWS

### AWS Resource States:
**VPC**: `available` state
**Subnets**: `available` state
**Internet Gateway**: `attached` state
**Route Table**: `active` with routes
**Routes**: `active` state
**Associations**: Subnets associated with route table

### Where to Check Progress:

**Upbound Console** (Real-time):
```bash
# View managed resources
- Navigate to Control Plane → Managed Resources
- Watch status change: Creating → Syncing → Ready
- Click on each resource to see conditions
```

**AWS Console** (Actual Resources):
```bash
# Check VPC
https://console.aws.amazon.com/vpc → Your VPCs
- Look for: 10.0.0.0/16 VPC
- State should be: available
- Tags: Environment=e2e-test, TestName=basic-vpc

# Check Subnets
https://console.aws.amazon.com/vpc → Subnets
- Look for: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- State should be: available
- Auto-assign public IPv4: Yes

# Check Internet Gateway
https://console.aws.amazon.com/vpc → Internet Gateways
- State should be: attached
- Attached VPC: The 10.0.0.0/16 VPC

# Check Route Tables
https://console.aws.amazon.com/vpc → Route Tables
- Look for: Public route table
- Routes should include: 0.0.0.0/0 → igw-xxxxx
- Subnet associations: 3 explicit associations
```

### Common Issues:
- ⏱️ **Timeout** - Test times out before resources ready
  - Cause: AWS slow, or stuck resource
  - Check: AWS console for failed resources
  - Action: Delete resources manually if test fails

- ❌ **IAM Permission Denied**
  - Error: "User: ... is not authorized to perform: ec2:CreateVpc"
  - Cause: IAM role lacks permissions
  - Action: Update IAM role with EC2 full access

- ❌ **Subnet CIDR Conflict**
  - Error: "The CIDR '10.0.1.0/24' conflicts with another subnet"
  - Cause: Overlapping CIDR blocks
  - Action: Use different CIDR ranges

- ❌ **IGW Attachment Timeout**
  - Symptom: IGW stuck in "attaching" state
  - Cause: AWS API delay
  - Action: Wait longer or delete and retry

---

## Phase 5: Test Validation - ~1 minute

### What Happens:
1. **Condition Verification** - Test framework checks all defaultConditions met
2. **Resource Count Check** - Verifies expected number of resources created
3. **Status Field Check** - Validates XR status fields populated

### Expected Output:
```
Validating test results ...
✓ All resources Ready
✓ All resources Synced
✓ Expected resource count: 10/10
✓ No error events
Test validation: PASSED ✓
```

### Success Criteria:
- ✅ defaultConditions: ["Ready", "Synced"] - ALL met
- ✅ All managed resources exist
- ✅ No failure conditions
- ✅ XR status populated (if status fields defined)

---

## Phase 6: Cleanup - ~5-10 minutes

This phase is CRITICAL - we must verify NO resources are orphaned in AWS.

### What Happens:
1. **Delete Test Manifests** - Deletes the VPC XR
2. **Crossplane Cascade Delete** - Deletes all managed resources
3. **AWS Resource Deletion** - AWS deletes resources in order:
   - Delete Route Table Associations
   - Delete Routes
   - Delete Route Table
   - Delete Subnets
   - Detach Internet Gateway
   - Delete Internet Gateway
   - Delete VPC
4. **Verify Deletion** - Test framework verifies all resources deleted
5. **Control Plane Cleanup** - Deletes ephemeral control plane

### Expected Output:
```
Cleaning up test resources ...
Deleting VPC/e2e-test-basic-vpc ...
Waiting for resources to be deleted ...
Route table associations deleted ✓
Routes deleted ✓
Route table deleted ✓
Subnets deleted ✓
Internet gateway detached ✓
Internet gateway deleted ✓
VPC deleted ✓
All resources cleaned up ✓
Control plane deleted ✓
```

### Success Criteria:
- ✅ All managed resources deleted from control plane
- ✅ All AWS resources deleted from console
- ✅ No orphaned resources in AWS
- ✅ Control plane deleted from Spaces

### Where to Verify Cleanup:

**Upbound Console**:
- Managed Resources should be empty
- Control plane should be deleted

**AWS Console** (MOST IMPORTANT):
```bash
# Check VPC - MUST be deleted
https://console.aws.amazon.com/vpc → Your VPCs
- Filter by tags: TestName=basic-vpc
- Should return: NO RESULTS

# Check Subnets - MUST be deleted
https://console.aws.amazon.com/vpc → Subnets
- Filter by CIDR: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- Should return: NO RESULTS

# Check Internet Gateway - MUST be deleted
https://console.aws.amazon.com/vpc → Internet Gateways
- Filter by tags: TestName=basic-vpc
- Should return: NO RESULTS

# Check Route Tables - Public table MUST be deleted
https://console.aws.amazon.com/vpc → Route Tables
- Filter by tags: TestName=basic-vpc
- Should return: NO RESULTS (main/default tables are OK)
```

### Common Issues:

- ⚠️ **Resources Not Deleted**
  - Symptom: Resources remain in AWS after test
  - Cause: Dependency blocking deletion, or Crossplane bug
  - Action: Manual cleanup required
  - Commands:
    ```bash
    # Delete route table associations first
    aws ec2 disassociate-route-table --association-id rtbassoc-xxxxx

    # Delete route table
    aws ec2 delete-route-table --route-table-id rtb-xxxxx

    # Detach and delete IGW
    aws ec2 detach-internet-gateway --internet-gateway-id igw-xxxxx --vpc-id vpc-xxxxx
    aws ec2 delete-internet-gateway --internet-gateway-id igw-xxxxx

    # Delete subnets
    aws ec2 delete-subnet --subnet-id subnet-xxxxx

    # Delete VPC
    aws ec2 delete-vpc --vpc-id vpc-xxxxx
    ```

- ⚠️ **Deletion Timeout**
  - Symptom: Test times out during cleanup
  - Cause: AWS resources slow to delete
  - Action: Verify in AWS console if actually deleted

- ⚠️ **Cost Alert**
  - If resources NOT deleted: You will be charged!
  - NAT Gateway: ~$0.045/hour ($32/month)
  - EIP: $0.005/hour if unattached
  - Always verify cleanup!

---

## Phase 7: Test Result - ~1 second

### What Happens:
- Test framework reports final result
- Logs written to test output
- Exit code returned (0 = success, 1 = failure)

### Expected Output (Success):
```
Test: e2etest-xvpc-basic
Status: PASSED ✓
Duration: 38m 42s
Resources Created: 10
Resources Cleaned: 10
```

### Expected Output (Failure):
```
Test: e2etest-xvpc-basic
Status: FAILED ✗
Duration: 40m 00s (timeout)
Error: Resource VPC/e2e-test-basic-vpc failed to reach Ready condition
Reason: IAM permissions denied
```

---

## Complete Phase Timeline (Test 1 - Basic VPC)

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

---

## Resources Created by Each Test

### Test 1: Basic VPC
- 1 VPC
- 3 Subnets (public)
- 1 Internet Gateway
- 1 Route Table
- 1 Route
- 3 Route Table Associations
- **Total: 10 resources**

### Test 2: NAT Single
- 1 VPC
- 3 Public Subnets
- 3 Private Subnets
- 1 Internet Gateway
- 1 EIP
- 1 NAT Gateway
- 1 Public Route Table + 1 Route + 3 Associations
- 1 Private Route Table + 1 Route + 3 Associations
- **Total: 21 resources**

### Test 3: NAT Per AZ
- 1 VPC
- 3 Public Subnets
- 3 Private Subnets
- 1 Internet Gateway
- 3 EIPs
- 3 NAT Gateways
- 1 Public Route Table + 1 Route + 3 Associations
- 3 Private Route Tables + 3 Routes + 3 Associations (one per AZ)
- **Total: 27 resources**

### Test 4: Complete VPC
- 1 VPC
- 18 Subnets (3 public, 3 private, 3 database, 3 elasticache, 3 redshift, 3 intra)
- 1 Internet Gateway
- 1 EIP
- 1 NAT Gateway
- 1 Public Route Table + 1 Route + 3 Associations
- 1 Private Route Table + 1 Route + 3 Associations
- 1 Database Route Table + 1 Route + 3 Associations
- 3 Isolated Route Tables (elasticache, redshift, intra) + 9 Associations
- **Total: 45 resources**

---

## Monitoring During Test Execution

### Real-time Progress Checks

**Check every 5 minutes:**
```bash
# Local - Check test output
up test run tests/e2etest-e2etest-xvpc-basic --e2e

# Or if running in background
cat /tmp/claude/<path>/tasks/<task-id>.output
```

**Check Upbound Console:**
1. Login: https://console.upbound.io
2. Navigate: Organizations → solutions → Spaces
3. Look for: Development control plane (e2etest-xvpc-basic)
4. Click: Control Plane → Managed Resources
5. Filter: By Kind (VPC, Subnet, etc.)
6. Watch: Status progression

**Check AWS Console:**
1. Login: https://console.aws.amazon.com
2. Region: us-west-2
3. Service: VPC
4. Filter: By tags (TestName=basic-vpc)
5. Watch: Resources being created

---

## Success Indicators

### ✅ Test Passed Successfully
- All phases completed
- All resources reached Ready/Synced
- All resources cleaned up
- No errors in logs
- AWS console shows no orphaned resources
- Exit code: 0

### ❌ Test Failed
- Timeout reached
- Resources failed to reach Ready
- Error events in resource status
- IAM permission denied
- AWS resource creation failed
- Exit code: 1

---

## Troubleshooting Guide

### Issue: Test Hangs at "Waiting for package to be ready"
**Diagnosis**: Package installation failing or provider not ready
**Check**: Upbound Console → Control Plane → Packages
**Solution**: Wait 5 minutes, if still stuck, check provider logs

### Issue: "IAM role cannot be assumed"
**Diagnosis**: Provider can't authenticate with AWS
**Check**: ProviderConfig IAM role ARN correct
**Solution**: Verify role exists and has trust policy for Upbound

### Issue: "VPC creation failed"
**Diagnosis**: AWS API error or permission issue
**Check**: AWS CloudTrail for denied API calls
**Solution**: Update IAM role permissions

### Issue: Resources not cleaning up
**Diagnosis**: Dependencies blocking deletion
**Check**: AWS Console for resources in "deleting" state
**Solution**: Manual cleanup (see Phase 6)

---

## After All Tests Complete

### Verification Checklist
- [ ] All 4 tests passed
- [ ] No AWS resources orphaned (check us-west-2)
- [ ] No active NAT Gateways (expensive!)
- [ ] No unattached EIPs (billable)
- [ ] Control planes deleted from Spaces
- [ ] Test results documented

### Cost Verification
```bash
# Check AWS Cost Explorer
# Filter: us-west-2, Last 1 day
# Services: EC2, VPC
# Expected cost: ~$0.00 - $0.10 (if cleanup worked)
# Concerning cost: >$1.00 (resources not cleaned up!)
```

### Next Steps
1. Document results in e2e-test-notes.md
2. Update tasks.md - mark Task 0.1 complete
3. Commit all E2E tests
4. Update TESTING.md with actual results
5. Run composition tests to verify no regressions
