# Upbound Console Guide - Monitoring E2E Tests

A visual guide for using the Upbound Cloud web console to monitor control planes, packages, resources, and E2E test execution.

## Quick Access

**Upbound Console URL**: https://console.upbound.io

**Organization**: solutions

**Current Profile**: solutions (cloud)

## Related Documentation

For CLI-based management of groups and control planes, see: [upbound-platform.md](./upbound-platform.md)

For understanding the platform hierarchy (Organization → Space → Group → Control Plane), see: [upbound-platform.md](./upbound-platform.md) Part 1: Platform Architecture

---

## Step-by-Step: Monitoring E2E Test Progress

### Step 1: Login to Upbound Console

1. Open browser: https://console.upbound.io
2. You should already be logged in (via `up profile list` shows "solutions")
3. If not logged in, run: `up login` in terminal

### Step 2: Navigate to Spaces

```
Home → Organizations (sidebar) → solutions → Spaces
```

Or direct link: https://console.upbound.io/solutions/spaces

### Step 3: Find Your Development Control Plane

Look for control planes with names like:
- `dev-<test-name>-<random-id>`
- Example: `dev-e2etest-xvpc-basic-abc123`

**Status indicators:**
- 🟢 Green: Healthy and running
- 🟡 Yellow: Provisioning or updating
- 🔴 Red: Error or failed

### Step 4: Click on the Control Plane

Click the control plane name to open the details view.

You'll see:
- **Overview** tab - General status and metadata
- **Packages** tab - Installed configuration packages
- **Managed Resources** tab - AWS resources being managed
- **Events** tab - Event log and errors

---

## Monitoring Package Installation (Phase 2)

### Navigate: Control Plane → Packages

**What to Look For:**

1. **Configuration Package**
   - Name: `configuration-aws-vpc`
   - Version: `v0.0.0-<timestamp>`
   - Status: Should show "Healthy" or "Installed"
   - Icon: 🟢 (green checkmark)

2. **Function Package**
   - Name: `configuration-aws-vpc_vpc`
   - Type: KCL function
   - Status: Should show "Healthy"
   - Icon: 🟢 (green checkmark)

3. **Provider Package** (Auto-installed)
   - Name: `provider-aws-ec2`
   - Version: v2.x.x
   - Status: Should show "Healthy"
   - Icon: 🟢 (green checkmark)

### Troubleshooting Package Issues:

**If package shows "Installing..." for >5 minutes:**
- Click on the package name
- Check "Conditions" section for errors
- Look for "HealthyPackageRevision" condition

**Common errors:**
- "Failed to install dependencies" → Check kcl.mod dependencies
- "Image pull failed" → Package not pushed correctly
- "Provider not ready" → Wait for AWS provider to finish installing

---

## Monitoring Resource Creation (Phase 4)

### Navigate: Control Plane → Managed Resources

**What to Look For:**

### Filter by Kind:
Use the filter dropdown to see specific resource types:

1. **VPC**
   - Name: `vpc-e2e-test-basic-vpc`
   - Kind: `VPC`
   - Provider: `ec2.aws.upbound.io`
   - Status: Creating → Syncing → Ready

2. **Subnet** (should see 3 for Test 1)
   - Names:
     - `subnet-public-e2e-test-basic-vpc-us-west-2a`
     - `subnet-public-e2e-test-basic-vpc-us-west-2b`
     - `subnet-public-e2e-test-basic-vpc-us-west-2c`
   - Kind: `Subnet`
   - Status: Creating → Syncing → Ready

3. **InternetGateway**
   - Name: `igw-e2e-test-basic-vpc`
   - Kind: `InternetGateway`
   - Status: Creating → Syncing → Ready

4. **RouteTable**
   - Name: `rt-public-e2e-test-basic-vpc`
   - Kind: `RouteTable`
   - Status: Creating → Syncing → Ready

5. **Route**
   - Name: `route-public-igw-e2e-test-basic-vpc`
   - Kind: `Route`
   - Status: Creating → Syncing → Ready

6. **RouteTableAssociation** (should see 3)
   - Names: `rta-public-e2e-test-basic-vpc-us-west-2{a,b,c}`
   - Kind: `RouteTableAssociation`
   - Status: Creating → Syncing → Ready

### Resource Status Progression:

**1. Initial State** (first ~1 minute)
- Status: Empty or "Creating"
- Conditions: None yet

**2. Creating State** (AWS provisioning)
- Status: "Creating"
- Synced: False
- Ready: False
- Last Activity: "Creating resource in AWS"

**3. Syncing State** (Crossplane monitoring)
- Status: "Syncing"
- Synced: False
- Ready: False
- Last Activity: "Waiting for AWS to report ready"

**4. Ready State** (Success!)
- Status: "Ready"
- Synced: True ✅
- Ready: True ✅
- Last Activity: "Successfully reconciled"

### Viewing Resource Details:

**Click on any resource to see:**

1. **Overview Tab**
   - Resource metadata
   - Creation timestamp
   - Owner references

2. **Spec Tab**
   - Desired state (what you requested)
   - Example for VPC:
     ```yaml
     spec:
       forProvider:
         cidrBlock: 10.0.0.0/16
         enableDnsHostnames: true
         enableDnsSupport: true
         region: us-west-2
         tags:
           Environment: e2e-test
           TestName: basic-vpc
     ```

3. **Status Tab**
   - Actual state (what AWS reports)
   - AWS Resource ID (e.g., `vpc-0a1b2c3d4e5f`)
   - Conditions:
     - Ready: True/False
     - Synced: True/False
     - LastAsyncOperation: Success/InProgress/Failed

4. **Events Tab**
   - Recent events for this resource
   - Success messages: "Successfully created resource"
   - Error messages: "Failed to create: IAM permission denied"

### Expected Timeline for Resources:

| Resource Type | Creation Time | Notes |
|---------------|---------------|-------|
| VPC | 30-60 seconds | Usually fast |
| Subnet | 1-2 minutes | Per subnet |
| Internet Gateway | 2-3 minutes | Includes attachment |
| Route Table | 1 minute | Usually fast |
| Route | 1-2 minutes | Depends on target |
| Route Table Association | 1-2 minutes | Per association |
| NAT Gateway | 5-10 minutes | SLOWEST resource |
| EIP | 30 seconds | Fast |

---

## Monitoring Events

### Navigate: Control Plane → Events

**Event Types:**

1. **Normal Events** (Info/Success)
   - "Successfully reconciled"
   - "Resource created"
   - "Resource synced"

2. **Warning Events** (Non-critical)
   - "Reconciliation delayed"
   - "Waiting for dependency"
   - "Rate limit encountered"

3. **Error Events** (Critical)
   - "Failed to create resource"
   - "IAM permission denied"
   - "Resource limit exceeded"

### Filtering Events:

Use filters to find specific events:
- **By Type**: Normal, Warning, Error
- **By Resource**: VPC, Subnet, etc.
- **By Time**: Last hour, last day, etc.

### Example Events Timeline:

```
[12:00:00] Normal   VPC          Creating VPC with CIDR 10.0.0.0/16
[12:00:30] Normal   VPC          Successfully created VPC (vpc-123abc)
[12:00:35] Normal   Subnet       Creating subnet subnet-public-us-west-2a
[12:01:00] Normal   Subnet       Successfully created subnet (subnet-456def)
[12:01:05] Normal   IGW          Creating Internet Gateway
[12:03:00] Normal   IGW          Successfully attached IGW to VPC
[12:03:10] Normal   RouteTable   Creating route table
[12:03:45] Normal   Route        Creating route to Internet Gateway
[12:04:30] Normal   Route        Successfully created route
```

---

## Monitoring Composite Resources (XR)

### Navigate: Control Plane → Composite Resources

**Or use the search bar:** Search for `VPC` kind

**What to See:**

1. **VPC Composite Resource**
   - Name: `e2e-test-basic-vpc`
   - Namespace: `default`
   - Kind: `VPC`
   - API Version: `aws.platform.upbound.io/v1alpha1`

2. **Click on the VPC XR to see:**

   **Overview Tab:**
   - Shows high-level status
   - Conditions: Ready, Synced

   **Spec Tab:**
   - Your input configuration:
     ```yaml
     spec:
       region: us-west-2
       cidr: 10.0.0.0/16
       azs:
         - us-west-2a
         - us-west-2b
         - us-west-2c
       publicSubnets:
         - 10.0.1.0/24
         - 10.0.2.0/24
         - 10.0.3.0/24
       createIgw: true
       enableDnsHostnames: true
       enableDnsSupport: true
     ```

   **Status Tab:**
   - Composed resource references
   - List of all managed resources created
   - Status conditions

   **Composition Tab:**
   - Shows which composition was used
   - Function pipeline configuration

---

## Checking AWS Provider Configuration

### Navigate: Control Plane → Managed Resources → Filter: ProviderConfig

**What to Check:**

1. **ProviderConfig/default**
   - Status: Should be "Ready"
   - Spec should show:
     ```yaml
     spec:
       assumeRoleChain:
         - roleARN: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
     ```

2. **If ProviderConfig shows errors:**
   - Click to see details
   - Check Events tab for:
     - "AssumeRole failed"
     - "Invalid IAM role"
     - "Access denied"

---

## Real-Time Monitoring Commands (CLI Alternative)

If you prefer CLI over UI:

### Watch all managed resources:
```bash
# This would work if connected to the control plane
# Note: E2E tests run in ephemeral control planes

# If you had kubectl access:
kubectl get managed
kubectl get vpc,subnet,internetgateway,routetable,route
watch -n 5 'kubectl get vpc,subnet -o wide'
```

### Check package status:
```bash
# Via up CLI
up ctp package list

# Watch package installation
watch -n 5 'up ctp package list'
```

---

## Screenshots Guide

### Key Screens to Monitor:

1. **Spaces Overview**
   - Shows all control planes
   - See test control plane status

2. **Control Plane Dashboard**
   - High-level health
   - Resource counts
   - Recent events

3. **Managed Resources List**
   - All AWS resources
   - Status at a glance
   - Quick filtering

4. **Resource Detail View**
   - Deep dive into single resource
   - Conditions and events
   - Spec vs Status comparison

5. **Events Stream**
   - Real-time event log
   - Error tracking
   - Debug information

---

## Troubleshooting via Console

### Problem: Package stuck "Installing"

**Steps:**
1. Navigate to: Control Plane → Packages
2. Click on: configuration-aws-vpc package
3. Check: Conditions section
4. Look for: "HealthyPackageRevision: False"
5. Read: Message field for error details

**Common causes:**
- Missing dependency
- Invalid KCL syntax
- Image pull failure

### Problem: Resource stuck "Creating"

**Steps:**
1. Navigate to: Control Plane → Managed Resources
2. Filter by: Kind (e.g., VPC)
3. Click on: The stuck resource
4. Check: Status → Conditions
5. Look for: "LastAsyncOperation: Failed"
6. Read: Message for AWS error

**Common causes:**
- IAM permission denied
- AWS quota exceeded
- Invalid configuration

### Problem: All resources stuck

**Steps:**
1. Navigate to: Control Plane → Managed Resources
2. Filter by: ProviderConfig kind
3. Check: ProviderConfig status
4. If not Ready: IAM auth failed
5. Verify: IAM role ARN is correct

---

## Quick Reference: Status Colors

### In Upbound Console:

- 🟢 **Green / Checkmark**: Ready, Healthy, Success
- 🟡 **Yellow / Clock**: Creating, Installing, In Progress
- 🔴 **Red / X**: Failed, Error, Unhealthy
- ⚪ **Gray / Dash**: Unknown, Not Started, Pending

### Resource Conditions:

- **Ready: True** ✅ - Resource is fully operational
- **Ready: False** ❌ - Resource has issues
- **Ready: Unknown** ⚪ - Status not yet determined

- **Synced: True** ✅ - Matches desired state
- **Synced: False** ❌ - Drifted or updating
- **Synced: Unknown** ⚪ - Not yet synced

---

## What "Success" Looks Like

### During Test Execution:

**Packages Tab:**
- ✅ configuration-aws-vpc: Healthy
- ✅ configuration-aws-vpc_vpc: Healthy
- ✅ provider-aws-ec2: Healthy

**Managed Resources Tab:**
- ✅ All resources showing "Ready" and "Synced"
- ✅ No error events
- ✅ Resource count matches expected (10 for Test 1)

**Events Tab:**
- ✅ All Normal events
- ✅ No Error events
- ✅ Latest: "Successfully reconciled"

**Composite Resources Tab:**
- ✅ VPC XR shows Ready: True, Synced: True
- ✅ All composed resources healthy

### After Test Cleanup:

**Control Plane:**
- ✅ Control plane deleted (no longer in Spaces list)

**Managed Resources:**
- ✅ No resources remaining

---

## Useful Console URLs

### Direct Links (replace with actual control plane ID):

```
# Control plane dashboard
https://console.upbound.io/solutions/spaces/<control-plane-id>

# Managed resources
https://console.upbound.io/solutions/spaces/<control-plane-id>/resources

# Packages
https://console.upbound.io/solutions/spaces/<control-plane-id>/packages

# Events
https://console.upbound.io/solutions/spaces/<control-plane-id>/events

# Configuration
https://console.upbound.io/solutions/spaces/<control-plane-id>/configuration
```

---

## Monitoring Checklist

Use this checklist while test is running:

**Every 5 minutes, check:**
- [ ] Control plane still healthy (green)
- [ ] Packages installed (all green checkmarks)
- [ ] New resources appearing in Managed Resources
- [ ] Resources progressing: Creating → Syncing → Ready
- [ ] No error events in Events tab
- [ ] VPC XR conditions improving

**When test should be done (40 min mark):**
- [ ] All managed resources Ready: True
- [ ] All managed resources Synced: True
- [ ] VPC XR Ready: True and Synced: True
- [ ] No error events
- [ ] Test output shows "PASSED"

**After test completes:**
- [ ] Control plane deleted from Spaces
- [ ] No managed resources remaining
- [ ] AWS Console shows no orphaned resources

---

## Pro Tips

### Tip 1: Use Browser Tabs
Open multiple tabs for efficient monitoring:
- Tab 1: Managed Resources (auto-refresh)
- Tab 2: Events (see errors immediately)
- Tab 3: AWS Console (verify actual resources)

### Tip 2: Browser Auto-Refresh
Some browsers support auto-refresh extensions. Set to refresh every 30-60 seconds.

### Tip 3: Filter Smartly
Use filters to focus:
- Filter by Ready: False (see what's not ready)
- Filter by Kind: VPC (see specific resource type)
- Sort by: Age (newest first)

### Tip 4: Bookmark
Bookmark the Spaces page for quick access:
https://console.upbound.io/solutions/spaces

### Tip 5: Compare with AWS
Keep AWS Console open side-by-side:
- Upbound: Shows desired state and Crossplane status
- AWS: Shows actual infrastructure state
- Both should match!

---

## Next Steps

Now that you know how to monitor via console, you can:

1. Watch the current test progress in real-time
2. Verify resources are being created in AWS
3. Troubleshoot issues if they occur
4. Confirm cleanup happened successfully
5. Monitor the next 3 tests when we run them
