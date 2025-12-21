# Testing Reference for Upbound Projects

## Table of Contents

- [Overview](#overview)
- [Testing Types](#testing-types)
- [Composition Tests](#composition-tests)
- [E2E Tests](#e2e-tests)
- [Control Plane Configuration](#control-plane-configuration)
- [KCL Testing Patterns](#kcl-testing-patterns)
- [Key Learnings](#key-learnings)
- [Platform Ref Testing Patterns](#platform-ref-testing-patterns)
- [CI/CD Integration](#cicd-integration)
- [Debugging](#debugging)
- [References](#references)

---

## Overview

This comprehensive guide covers all aspects of testing Upbound projects, including composition tests, E2E tests, control plane configuration, and testing patterns from production Upbound projects.

### Quick Reference

| Task | Command | Speed | Requires Cluster |
|------|---------|-------|------------------|
| Preview | `up composition render` | Fast | No |
| Composition Test | `up test run tests/test-*` | Fast (< 10s) | No |
| E2E Test | `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing` | Slow (30+ min) | Yes (auto-created) |

### When to Use What

- **Development**: Composition render + composition tests
- **Pre-commit**: Composition tests (ALL must pass)
- **CI on all PRs**: Composition tests
- **CI on labeled PRs**: E2E tests
- **Pre-release**: Full E2E test suite

---

## Testing Types

### 1. Composition Tests (Unit Tests)

**Purpose**: Validate composition logic without requiring a live Kubernetes environment by simulating the composition controller's behavior.

**When to use**:
- Testing resource creation logic
- Validating conditional resource generation
- Testing resource dependencies and ordering
- Verifying resource specifications match inputs
- Fast feedback during development

**Key characteristics**:
- Models a single composition controller loop
- Uses mock data instead of live resources
- Fast execution (seconds, no cluster required)
- Can test with various XR inputs
- Validates resource structure and relationships
- Run with: `up test run tests/test-*`

### 2. End-to-End (E2E) Tests

**Purpose**: Validate compositions in real cloud environments, ensuring resources are actually created, configured, and can be deleted properly.

**When to use**:
- Verifying actual AWS resource creation
- Testing provider authentication
- Validating resource readiness conditions
- Testing complete lifecycle (create, update, delete)
- Final validation before release

**Key characteristics**:
- Requires real control plane (auto-provisioned)
- Creates actual cloud resources
- Slower execution (10-30 minutes)
- Tests complete system integration
- Requires cloud credentials and Upbound account
- Run with: `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`

### 3. Composition Rendering (Preview)

**Purpose**: Preview composed resources locally before deployment.

**When to use**:
- Quick validation during development
- Understanding what resources will be created
- Debugging composition logic
- Documentation and examples

```bash
# Preview what resources will be created
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Save output for inspection
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml > /tmp/rendered.yaml
```

---

## Composition Tests

### Test Structure

**Languages supported**: KCL, Python, YAML

**Test directory structure**:
```
tests/
├── test-xvpc-simple/
│   ├── kcl.mod
│   ├── kcl.mod.lock
│   ├── main.k
│   └── model/ (symbolic link to shared models)
├── test-xvpc-multi-az/
│   └── main.k
└── test-xvpc-nat-single/
    └── main.k
```

### Generating Composition Tests

```bash
# Generate KCL test (recommended)
up test generate test-xvpc-simple --language=kcl

# Generate Python test
up test generate test-xvpc-complex --language=python

# Generate YAML test (default)
up test generate test-xvpc-basic
```

### CompositionTest Schema (KCL)

```kcl
schema CompositionTest:
    metadata: {
        name: string  // Test name
    }
    spec: {
        // REQUIRED: At least 60 seconds recommended
        timeoutSeconds: int  // Default: 30

        // Optional: Validate managed resources against schemas
        validate: bool  // Default: False

        // XR Definition: Choose ONE of these two options
        xr: {}          // Define XR inline (RECOMMENDED)
        xrPath: string  // Path to XR file (mutually exclusive with xr)

        // XRD Definition: Optional, choose one
        xrd: {}         // Define XRD inline
        xrdPath: string // Path to XRD file

        // Composition: Optional, choose one
        composition: {}      // Define composition inline
        compositionPath: string // Path to composition file

        // Assertions: Validate composed resources
        assertResources: []  // Array of resource assertions

        // Observed resources: Check existing resource states
        observedResources: [] // Array of resources to observe

        // Extra resources: Additional resources for test
        extraResources: []  // Array of extra resources

        // Context: Pass context to function pipeline
        context: {}  // Map of context key-value pairs

        // Credentials: Optional path to credentials file
        functionCredentialsPath: string
    }
```

### Complete Working Example

```kcl
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.CompositionTest {
        metadata.name: "test-xvpc-simple"
        spec: {
            timeoutSeconds: 60
            validate: True

            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"

            # Define XR inline - no separate file needed!
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "XVPC"
                metadata: {
                    name: "test-vpc"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    tags: {
                        Environment: "test"
                    }
                }
            }

            # Assert that resources are created correctly
            assertResources: [
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "VPC"
                    metadata: {
                        name: "vpc-test-vpc"  # Must match generated name
                    }
                    spec: {
                        forProvider: {
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                            enableDnsHostnames: True
                            enableDnsSupport: True
                            tags: {
                                Environment: "test"
                                Name: "test-vpc"
                            }
                        }
                    }
                },
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    metadata: {
                        name: "subnet-public-test-vpc-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.1.0/24"
                            mapPublicIpOnLaunch: True
                            region: "us-west-2"
                        }
                    }
                }
            ]
        }
    }
]
items = _items
```

### Running Composition Tests

```bash
# Run all composition tests
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-simple/main.k

# Run tests matching pattern
up test run tests/test-xvpc-*/main.k

# Verbose output
up test run tests/* --verbose

# Before committing (CRITICAL)
up project build && up test run tests/test-*
```

### Test Scenarios to Cover

For each major feature, create tests for:

1. **Basic scenario**: Minimal required inputs
2. **Complex scenario**: All options enabled
3. **Conditional logic**: Features enabled/disabled
4. **Edge cases**: Boundary conditions, unusual inputs
5. **Multiple resources**: Multiple subnets, AZs, etc.
6. **Dependencies**: Resources that depend on others

---

## E2E Tests

### E2ETest Schema (KCL)

```kcl
schema E2ETest:
    metadata: {
        name: string  // Test name
    }
    spec: {
        // REQUIRED: Crossplane configuration
        crossplane: {
            autoUpgrade: {
                channel: "Rapid" | "Stable" | "None"
            }
        }

        // Timeouts (in seconds)
        timeoutSeconds: int        // Default: varies, 1800+ recommended
        cleanupTimeoutSeconds: int // Default: 600

        // Control resource lifecycle
        skipDelete: bool  // Default: False - should cleanup after test

        // Validation conditions for manifests
        defaultConditions: []  // e.g., ["Ready", "Synced"]

        // REQUIRED: Resources to test (Claims, XRs, etc.)
        manifests: []  // Array of test resources

        // Optional: Additional resources applied after config
        extraResources: []  // e.g., ProviderConfig, Secrets

        // Optional: Prerequisite resources applied before config
        initResources: []  // e.g., ImageConfigs, DeploymentRuntimeConfigs
    }
```

### Complete E2E Test Example

```kcl
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.E2ETest {
        metadata.name: "e2etest-xvpc-simple"
        spec: {
            # Crossplane configuration
            crossplane: {
                # CRITICAL: Always specify version explicitly for Crossplane v2
                # Without this, tests may use v1 by default and fail with package errors
                version: "2.0.2-up.5"
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts (in seconds)
            timeoutSeconds: 1800       # 30 minutes for AWS resources
            cleanupTimeoutSeconds: 600 # 10 minutes
            skipDelete: False          # Clean up after test

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Additional resources (ProviderConfig, etc.)
            extraResources: [
                {
                    # CRITICAL: Use aws.m.upbound.io (note the .m. suffix) for namespaced providers
                    # Parent provider: aws.upbound.io
                    # Namespaced provider: aws.m.upbound.io
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        # REQUIRED: namespace field is MANDATORY for namespaced claims
                        # Without this, E2E test will hang on "Applying Extra Resources"
                        namespace: "default"
                    }
                    spec: {
                        # REQUIRED: credentials.source field for Upbound Spaces
                        credentials: {
                            source: "Upbound"  # Integrates with Upbound identity injection
                        }
                        # Use IAM role, NEVER static credentials
                        assumeRoleChain: [
                            {
                                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        ]
                    }
                }
            ]

            # Main test resources
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "test-vpc-e2e"
                    }
                    spec: {
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a"]
                        publicSubnets: ["10.0.1.0/24"]
                    }
                }
            ]
        }
    }
]
items = _items
```

### Generating E2E Tests

```bash
# Generate KCL E2E test
up test generate e2etest-xvpc-simple --e2e --language=kcl

# Generate Python E2E test
up test generate e2etest-xvpc-complex --e2e --language=python
```

### Running E2E Tests

```bash
# CRITICAL: ALWAYS specify control plane group for local testing
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Run specific E2E test
up test run tests/e2etest-xvpc-simple --e2e --control-plane-group=claude-testing

# Keep control plane for debugging (skip cleanup)
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=claude-testing \
  --skip-control-plane-cleanup
```

### E2E Test Execution Flow

1. Detects test language and converts to unified format
2. Builds and pushes the project to Upbound registry
3. Creates a development control plane with specified Crossplane version
4. Sets kubectl context to new control plane
5. Applies extra resources (ProviderConfig, etc.) in order
6. Waits for extra resources to reach expected conditions
7. Applies test manifests (your XRs)
8. Waits for resources to reach expected conditions (Ready, Synced)
9. Validates assertions
10. Exports resources for debugging if failures occur
11. Deletes resources (unless skipDelete=true)
12. Cleans up control plane

**Duration**: 10-30 minutes for AWS resources

### E2E Test Best Practices

1. **Use realistic timeouts**: AWS resources can take 5-30 minutes
2. **Run on Upbound Cloud**: Always use dedicated control plane group
3. **Clean up resources**: Ensure skipDelete=false in CI
4. **Use IAM role for credentials**: `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws` (NEVER static credentials)
5. **Test critical paths**: E2E validates real cloud integration
6. **Run in CI with labels**: Use "run-e2e-tests" label to trigger
7. **ALWAYS specify control plane group**: Never rely on default context

---

## Control Plane Configuration

### CRITICAL: Always Use Dedicated Control Plane Group

**IMPORTANT**: E2E tests should ALWAYS run on a dedicated control plane group for testing, NOT on production control plane groups.

### Local Testing (Manual Runs)

For local testing, use the **`claude-testing`** control plane group (in the `upbound-gcp-us-central-1` space):

```bash
# ✅ CORRECT - Run E2E tests locally on claude-testing control plane group
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# ❌ WRONG - Uses current context (might be production!)
up test run tests/e2etest-* --e2e
```

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

--organization=STRING
    Override organization (default: solutions)
```

### How E2E Tests Work with Control Planes

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

### Current Context vs Explicit Group

#### Default Behavior (Uses Current Context)

```bash
# Check current context
up ctx .
# Output: Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske

# ❌ DON'T RUN without specifying group - uses current context group!
up test run tests/e2etest-* --e2e
```

#### Explicit Group (Required for Local Testing)

```bash
# ✅ CORRECT - Run test on claude-testing control plane group for local testing
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# This overrides the context and creates control plane in "claude-testing" group
# (which lives in the upbound-gcp-us-central-1 space)
```

### Control Plane Groups in Upbound

**What is a Control Plane Group?**

A control plane group is a logical grouping of control planes within an Upbound organization. It provides:
- **Isolation**: Separate test control planes from production
- **Resource organization**: Group related control planes
- **Access control**: Different permissions per group
- **Cost tracking**: Separate billing/usage by group

**Typical Organization Structure:**

```
Organization: solutions
  ├── Control Plane Group: production
  │   ├── control plane: prod-us-east (in some space)
  │   └── control plane: prod-eu-west (in some space)
  ├── Control Plane Group: staging
  │   └── control plane: staging-us-east (in some space)
  └── Control Plane Group: claude-testing (for local E2E tests)
      ├── space: upbound-gcp-us-central-1
      │   ├── control plane: e2e-test-1 (auto-created by tests)
      │   ├── control plane: e2e-test-2 (auto-created by tests)
      │   └── ... (cleaned up automatically after tests)
```

### Checking Current Configuration

```bash
# View current profile and organization
up profile list

# View current context (shows org/group/control-plane/space)
up ctx .

# Example output format:
# Kubeconfig context "upbound": Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske
#                                       ↓         ↓                        ↓     ↓
#                                       org       group                    cp    space
#
# Components:
# - Organization: solutions
# - Control Plane Group: upbound-aws-us-east-1
# - Control Plane: upbox
# - Space: upbox-danske
```

### Debugging Failed E2E Tests

#### Keep Control Plane for Investigation

```bash
# Skip cleanup to investigate issues
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=claude-testing \
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

#### Run on Existing Control Plane

```bash
# Use current kubeconfig context instead of creating new
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --use-current-context
```

### Complete E2E Test Workflow (Local Testing)

```bash
# 1. Ensure logged into Upbound
up login

# 2. Check current context
up ctx .
# Output: Upbound solutions/upbound-aws-us-east-1/upbox/upbox-danske

# 3. Run E2E tests on claude-testing control plane group (for local testing)
up test run tests/e2etest-* \
  --e2e \
  --control-plane-group=claude-testing \
  --organization=solutions

# 4. Tests will:
#    - Create temporary control plane in "claude-testing" group
#    - Control plane will run in upbound-gcp-us-central-1 space
#    - Run tests
#    - Clean up control plane
#    - Report results

# 5. If test fails and you need to debug:
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=claude-testing \
  --skip-control-plane-cleanup

# 6. Then inspect the control plane:
kubectl get controlplanes -n upbound-system
up ctx <failed-test-control-plane-name>
kubectl get all
```

### Control Plane Best Practices

**Local Testing:**
- ✅ **ALWAYS** use `--control-plane-group=claude-testing` for local E2E tests
- ✅ Control plane will run in `upbound-gcp-us-central-1` space
- ✅ **NEVER** run E2E tests without specifying control plane group
- ✅ **NEVER** run E2E tests on production control plane groups
- ✅ E2E tests create temporary control planes automatically
- ✅ Control planes are cleaned up automatically (unless `--skip-control-plane-cleanup`)

**Terminology:**
- **Control Plane Group**: Logical grouping (use with `--control-plane-group` flag)
- **Space**: Physical location where control plane runs (specified at group level)

**CI/CD Testing:**
- ⏸️ GitHub workflows will be configured separately later
- ⏸️ Do not modify `.github/workflows/` files yet

### IAM Role for E2E Tests

**CRITICAL**: Use this role for running e2e tests on Upbound Cloud:

```
arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
```

**IMPORTANT**: E2E tests MUST use IAM role assumption, NEVER static credentials.

This role should be configured in the ProviderConfig:

```kcl
{
    apiVersion: "aws.upbound.io/v1beta1"
    kind: "ProviderConfig"
    metadata.name: "default"
    spec: {
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

---

## KCL Testing Patterns

### Always Define XR Inline for Composition Tests

**✅ GOOD** - XR defined inline:
```kcl
spec: {
    xr: {
        apiVersion: "..."
        kind: "XVPC"
        metadata: { name: "test" }
        spec: { ... }
    }
}
```

**❌ BAD** - Separate XR file (adds complexity):
```kcl
spec: {
    xrPath: "xr.yaml"  # Avoid unless necessary
}
```

### Use Descriptive Test Names

```kcl
# Pattern: test-<resource-type>-<scenario>
metadata.name: "test-xvpc-simple"
metadata.name: "test-xvpc-public-subnets"
metadata.name: "test-xvpc-nat-per-az"

# E2E tests: e2etest-<resource-type>-<scenario>
metadata.name: "e2etest-xvpc-basic"
```

### Set Appropriate Timeouts

```kcl
# Composition tests: 60-120 seconds (no real resources)
timeoutSeconds: 60

# E2E tests: 1800+ seconds (creates real AWS resources)
timeoutSeconds: 1800  # 30 minutes
cleanupTimeoutSeconds: 600  # 10 minutes
```

### Testing Conditional Resources

```kcl
# Test that IGW is created when createIgw: true
xr: {
    spec: {
        createIgw: True
        publicSubnets: ["10.0.1.0/24"]
    }
}
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "InternetGateway"
        metadata: { name: "igw-test-vpc" }  # Must match generated name
    }
]

# Test that IGW is NOT created when createIgw: false
# (assertResources should NOT include InternetGateway)
```

### Testing Resource Counts

```kcl
# Test correct number of subnets across AZs
xr: {
    spec: {
        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    }
}
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        metadata: { name: "subnet-public-test-vpc-us-west-2a" }
    },
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        metadata: { name: "subnet-public-test-vpc-us-west-2b" }
    },
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        metadata: { name: "subnet-public-test-vpc-us-west-2c" }
    }
]
```

### Testing Tag Propagation

```kcl
xr: {
    spec: {
        tags: {
            Environment: "production"
            Team: "platform"
        }
    }
}
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        metadata: { name: "vpc-test-vpc" }
        spec: {
            forProvider: {
                tags: {
                    Environment: "production"
                    Team: "platform"
                }
            }
        }
    }
]
```

---

## Key Learnings

### CRITICAL: AssertResources Structure

**IMPORTANT**: The `assertResources` field expects FULL Kubernetes resource definitions, not a special "assert" syntax.

#### ❌ WRONG Pattern (Does NOT Work)

```kcl
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        assert: {  # ← This field doesn't exist!
            "spec.forProvider.cidrBlock": "10.0.0.0/16"
        }
    }
]
```

#### ✅ CORRECT Pattern (Works!)

```kcl
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        metadata: {
            name: "vpc-test-vpc"  # ← MUST match the actual generated resource name
        }
        spec: {
            forProvider: {
                cidrBlock: "10.0.0.0/16"  # ← Fields you want to assert
                region: "us-west-2"
                enableDnsHostnames: True
                tags: {
                    Environment: "test"
                }
            }
        }
    }
]
```

### How AssertResources Works

1. The test framework uses Chainsaw (Kubernetes testing framework) under the hood
2. It matches resources by: `apiVersion`, `kind`, and `metadata.name`
3. Once it finds a match, it checks if the specified fields in your assertion match the rendered resource
4. You only need to specify the fields you want to assert - partial matching is supported
5. The resource name MUST be the exact name that your composition generates

### Finding Resource Names

To find the correct resource names for your assertions:

```bash
# Render the composition to see what names are generated
up composition render apis/vpc/composition.yaml examples/xr-simple-vpc.yaml --xrd apis/vpc/definition.yaml

# Output will show the exact metadata.name values:
# metadata:
#   name: vpc-test-vpc          ← Use this in your assertion
# metadata:
#   name: subnet-public-test-vpc-us-west-2a  ← Use this for subnet assertions
```

### Troubleshooting

#### Error: "no actual resource found: ec2.aws.upbound.io/v1beta1/VPC/"

**Cause**: Empty name in the resource lookup (note the trailing "/")

**Solution**: Add `metadata.name` to your assertResources with the exact name your composition generates

#### How to Debug

1. First, render your composition to see what it generates:
   ```bash
   up composition render apis/vpc/composition.yaml examples/xr.yaml --xrd apis/vpc/definition.yaml
   ```

2. Copy the exact metadata.name values from the output

3. Use those names in your assertResources

### Partial Field Matching

You don't need to specify ALL fields - only the ones you want to assert:

```kcl
# This works! You only assert the fields you care about
{
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "VPC"
    metadata: {
        name: "vpc-test-vpc"
    }
    spec: {
        forProvider: {
            cidrBlock: "10.0.0.0/16"  # Only checking CIDR, not all fields
        }
    }
}
```

### Summary

**Composition Tests:**
- ✅ Always use FULL resource definitions in `assertResources`
- ✅ Always specify `metadata.name` that matches generated names
- ✅ Use `up composition render` to find correct resource names
- ✅ Partial field matching is supported - only assert what matters
- ❌ Never use a fake "assert" field - it doesn't exist
- ❌ Don't leave metadata.name empty or the test will fail

---

## Platform Ref Testing Patterns

### Test Organization Pattern

Tests are organized by **resource type** with a naming convention:

```
tests/
├── test-xenvironment/                    # Basic tests
├── test-xenvironment-deletion-policy-delete/  # Variant tests
├── test-xenvironment-no-cloudprovider-resource/  # Edge case tests
├── test-xsharedawssecret/
├── test-xsharedawssecret-with-data/
└── e2etest-xvpc-basic/  # E2E tests use "e2etest-" prefix
```

**Naming Pattern**: `test-<resource-type>[-variant]`

**For VPC project**:
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
└── e2etest-xvpc-basic/                   # E2E test
```

### Test File Structure

Each test directory contains:

```
test-xvpc-simple/
├── kcl.mod           # KCL module configuration
├── kcl.mod.lock      # Dependency lock file
├── main.k            # Test definition
└── model/            # (optional) Symbolic link to shared models
```

### Key Testing Principles

1. **Resource-Based Organization**
   - One test directory per resource type
   - Variants for different scenarios (basic, with-data, deletion-policy, etc.)
   - Clear naming: `test-<resource>-<variant>`

2. **Composition Tests for Everything**
   - Every composition should have at least one test
   - Test basic scenario first
   - Add variant tests for edge cases
   - Fast feedback loop

3. **E2E Tests for Critical Paths**
   - Not every composition needs E2E test
   - Focus on critical integrations
   - Require real cloud resources
   - Run only when needed (labeled PRs)

4. **Use KCL for Tests**
   - Consistent with composition language
   - Type-safe test definitions
   - Reusable patterns

5. **CI/CD Integration**
   - Composition tests on every PR (fast, no cost)
   - E2E tests on labeled PRs (slow, has cost)
   - Automatic cleanup

---

## CI/CD Integration

### GitHub Workflows

#### Composition Tests (`.github/workflows/composition-test.yaml`)

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
          skip-login: true  # No credentials needed
      - run: up project build
      - run: up test run tests/test-*  # Only composition tests
```

**Key features**:
- Runs on every push and PR
- No credentials required
- Fast feedback (seconds to minutes)
- Only runs composition tests (not E2E)

#### E2E Tests (`.github/workflows/e2e.yaml`)

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
        run: up test run tests/e2etest-* --e2e
```

**Key features**:
- Only runs when PR has "run-e2e-tests" label
- Uses pull_request_target for secret access
- Requires UP_API_TOKEN, UP_ORG
- Switches to Upbound Cloud context before running
- Tests run on real control plane
- Uses robot credentials for registry access

### Running Tests Locally

```bash
# During active development
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Before committing (CRITICAL)
up project build && up test run tests/test-*

# Before creating PR
up test run tests/test-* --verbose

# Local E2E test (careful - creates real resources!)
up login
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Debug specific test
up test run tests/test-xvpc-basic/main.k --verbose
```

### Cost Considerations

E2E tests create real AWS resources. While costs should not prevent running necessary tests, understand what resources are created:

- **VPC**: Free
- **Subnets**: Free
- **Internet Gateway**: Free
- **NAT Gateway**: ~$0.045/hour
- **VPC Endpoints**: ~$0.01/hour per endpoint
- **Elastic IP**: $0.005/hour when not attached
- **Control Plane**: Free (dev control planes are free for 24h)

**Best practices**:
1. Run E2E tests when needed for validation
2. Use skipDelete=false to ensure cleanup
3. Set reasonable timeouts to avoid stuck resources
4. Use composition tests for most validation (faster feedback)

---

## Debugging

### Composition Test Failures

1. **Check rendered output**:
   ```bash
   up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml
   ```

2. **Review error message**: Usually indicates missing fields or wrong types

3. **Validate test inputs**: Ensure XR matches XRD schema

4. **Check assertions**: Verify expected resources and fields

5. **Verify resource names**:
   ```bash
   # Render to see exact names generated
   up composition render apis/vpc/composition.yaml examples/xr.yaml --xrd apis/vpc/definition.yaml
   ```

### E2E Test Failures

1. **Check exported resources**: Failed E2E tests export resources to debug
   ```bash
   kubectl get managed -o yaml > /tmp/managed-resources.yaml
   ```

2. **Check events**:
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

3. **Check resource status**:
   ```bash
   kubectl describe xvpc my-vpc
   ```

4. **Check provider logs**: Look for authentication or API errors

5. **Verify credentials**: Ensure ProviderConfig is correct

6. **Check timeouts**: E2E tests may need longer timeouts for AWS

7. **Keep control plane for investigation**:
   ```bash
   up test run tests/e2etest-xvpc-simple \
     --e2e \
     --control-plane-group=claude-testing \
     --skip-control-plane-cleanup

   # Then inspect
   up ctx <control-plane-name>
   kubectl get all
   ```

### Common Issues

#### Composition Tests

**Issue**: Test fails with "resource not found"
**Solution**: Add new resource to assertResources with correct metadata.name

**Issue**: Test fails with "field validation error"
**Solution**: Update XR example with new required fields

**Issue**: Test fails with "no actual resource found: ec2.aws.upbound.io/v1beta1/VPC/"
**Solution**: Add `metadata.name` to assertResources (empty name causes this)

#### E2E Tests

**Issue**: Test hangs on "Waiting for package to be ready" for 3+ minutes
**Solution**: Check `kubectl get pkgrev -oyaml` - likely missing or wrong Crossplane version. Always specify `version: "2.0.2-up.5"` explicitly in test spec.

**Issue**: Test hangs on "Applying Extra Resources" indefinitely
**Solution**: ProviderConfig is missing `namespace: "default"` field. Namespaced claims REQUIRE namespaced ProviderConfigs.

**Issue**: Error "ProviderConfig.aws.m.upbound.io 'default' not found"
**Solution**: Wrong API version - use `aws.m.upbound.io/v1beta1` (note `.m.` suffix) for namespaced providers, not `aws.upbound.io/v1beta1`

**Issue**: Error "spec.credentials: Required value"
**Solution**: Add `credentials.source: "Upbound"` to ProviderConfig spec

**Issue**: Test times out
**Solution**: Increase timeoutSeconds in test definition

**Issue**: E2E test uses wrong control plane group
**Solution**: Always specify `--control-plane-group=claude-testing` explicitly

#### ProviderConfig Configuration for E2E Tests

**CRITICAL**: For Crossplane v2 with namespaced claims, ProviderConfig must have:

1. API version: `aws.m.upbound.io/v1beta1` (note the `.m.` suffix)
2. Metadata namespace: `namespace: "default"` (MANDATORY)
3. Credentials source: `source: "Upbound"`
4. AssumeRoleChain with IAM role (never static credentials)

**Complete working example**:
```kcl
{
    apiVersion: "aws.m.upbound.io/v1beta1"
    kind: "ProviderConfig"
    metadata: {
        name: "default"
        namespace: "default"  # REQUIRED!
    }
    spec: {
        credentials: {
            source: "Upbound"  # REQUIRED for Spaces
        }
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

**Key Rules**:
- Namespaced claims (kind: VPC with namespace) → ProviderConfig MUST have namespace
- Cluster-scoped composites (kind: XVPC, no namespace) → ProviderConfig can be cluster-scoped
- Crossplane v2 uses `.m.` suffix for namespaced managed resource providers

---

## Testing Strategy for This Project

### Phase-by-Phase Testing

**Phase 1 (Foundation)**:
- Basic composition test for empty project
- Validate XRD schema

**Phase 2 (Core VPC)**:
- Composition tests for each feature:
  - VPC creation
  - Subnet creation (all types)
  - Internet Gateway
  - NAT Gateway (all strategies)
  - Route tables and routes
- E2E test for basic VPC with public subnets
- E2E test for VPC with NAT Gateway

**Phase 3 (Enhanced Networking)**:
- Composition tests for:
  - VPC Endpoints
  - Network ACLs
  - DHCP Options
  - Flow Logs
  - Secondary CIDRs
- E2E test for complete VPC with all features

**Phase 4 (Advanced Features)**:
- Composition tests for VPN Gateway, IPv6
- E2E test for advanced scenarios

### Test Coverage Goals

**Composition Tests**:
- ✅ Every feature should have at least one composition test
- ✅ Test with feature enabled and disabled
- ✅ Test edge cases (single AZ, many AZs, etc.)
- ✅ Fast execution (< 10 seconds per test)
- ✅ Run on every commit in CI

**E2E Tests**:
- ✅ Core scenarios covered (basic VPC, full VPC)
- ✅ Critical paths validated (create, delete, update)
- ✅ Run on labeled PRs or before release
- ✅ Budget for cloud costs (estimate $5-20 per test run)

---

## References

### Official Documentation

- **Upbound Testing Docs**: https://docs.upbound.io/build/control-plane-projects/testing/
- **Unified Testing Blog**: https://blog.upbound.io/unified-testing-with-upbound
- **Composition Testing Patterns**: https://blog.upbound.io/composition-testing-patterns-rendering
- **Example Repository**: https://github.com/upbound/composition-testing
- **Crossplane CLI**: https://docs.crossplane.io/latest/cli/

### Reference Projects

- **Platform Ref Upbound**: https://github.com/upbound/platform-ref-upbound
- **Platform Ref AWS**: https://github.com/upbound/platform-ref-aws

### Project Documentation

- **This Project's Testing Strategy**: See `thoughts/TDD_STRATEGY.md`
- **Architecture Guide**: See `thoughts/ARCHITECTURE.md`
- **User-Facing Testing Guide**: See `TESTING.md`

---

## Summary

### Key Principles

1. **Test early and often** with composition tests
2. **Use E2E tests sparingly** for critical paths
3. **Preview with render** during development
4. **Automate in CI/CD**
5. **Monitor costs** for E2E tests
6. **Document test scenarios**
7. **Keep tests maintainable** and organized

### Quick Commands

```bash
# Preview (no test)
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Composition tests (fast)
up test run tests/test-*

# E2E tests (slow, creates real AWS resources)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# Build before testing
up project build

# Debugging
up composition render apis/vpc/composition.yaml examples/xr.yaml --xrd apis/vpc/definition.yaml
```

### Critical Reminders

1. **AssertResources requires FULL resource definitions** with `metadata.name`
2. **Always specify control plane group** for E2E tests: `--control-plane-group=claude-testing`
3. **Use IAM roles** in E2E tests, NEVER static credentials
4. **All tests must pass** before committing (composition + E2E)
5. **Render compositions first** to find correct resource names for assertions
