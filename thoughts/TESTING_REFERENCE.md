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

## Related Documentation

This document focuses on test schemas, patterns, and debugging strategies.

**For TDD workflow, test strategy, and test pyramid**: See [TDD_STRATEGY.md](TDD_STRATEGY.md)

For related topics, see:
- **up CLI Commands**: [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)
- **KCL Language**: [KCL_REFERENCE.md](KCL_REFERENCE.md)
- **Control Plane Architecture**: [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md#platform-architecture)

---

## Overview

This comprehensive guide covers all aspects of testing Upbound projects, including composition tests, E2E tests, control plane configuration, and testing patterns from production Upbound projects.

### Quick Reference

| Task | Command | Speed | Requires Cluster |
|------|---------|-------|------------------|
| Preview | `up composition render` | Fast | No |
| Composition Test | `up test run tests/test-*` | Fast (< 10s) | No |
| E2E Test | `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing` | Slow (30+ min) | Yes (auto-created) |

**IMPORTANT**: E2E tests use Upbound's web identity federation for AWS authentication. NO static AWS credentials are required - authentication is handled automatically via IAM role assumption through Upbound's identity provider.

### When to Use What

- **Development**: Composition render + composition tests
- **Pre-commit**: Composition tests (ALL must pass)
- **CI on all PRs**: Composition tests
- **CI on labeled PRs**: E2E tests
- **Pre-release**: Full E2E test suite

### Test Scenarios

The test suite covers these primary scenarios:

1. **COMPLETE VPC** - Full VPC with all subnet types, NAT, endpoints, ACLs, DHCP, flow logs
2. **MINIMAL VPC** - Single public subnet, basic IGW, minimal routing
3. **MULTIPLE AZs** - Subnets across AZs, NAT per AZ, proper routing
4. **PRIVATE ONLY** - Database/app subnets, no IGW, optional NAT
5. **CUSTOM ROUTES** - Routes to Transit Gateway, VPN connections
6. **VPC ENDPOINTS** - S3/DynamoDB gateway endpoints, interface endpoints
7. **NETWORK ACLs** - Custom inbound/outbound rules
8. **DHCP OPTIONS** - Custom DNS, domain name, NTP servers
9. **DNS CONFIG** - DNS hostnames/resolution enabled
10. **FLOW LOGS** - CloudWatch and S3 destinations
11. **NAT STRATEGIES** - One per AZ, single shared, or none
12. **SECONDARY CIDRs** - Multiple CIDR blocks on single VPC

### Feature Coverage

The test suite validates:

1. **Resource Count** - Correct number of resources created
2. **Outputs** - All outputs populated correctly
3. **CIDR Assignment** - Subnets get correct CIDR allocations
4. **Routing** - Routes properly configured
5. **Gateway Association** - Gateways properly associated
6. **Tags** - Tags applied correctly
7. **IPv6** - IPv6 configuration when enabled
8. **Conditional Creation** - Resources only created when needed
9. **High Availability** - Multi-AZ resilience
10. **Network Segmentation** - Proper isolation of subnets

---

## KCL Testing Patterns

### XR Definition - Always Inline

**✅ GOOD** - XR defined inline (recommended):
```kcl
spec: {
    xr: {
        apiVersion: "awsm.upbound.io/v1alpha1"
        kind: "VPC"
        metadata: { name: "test-vpc" }
        spec: {
            cidr: "10.0.0.0/16"
            azs: ["us-west-2a", "us-west-2b"]
        }
    }
}
```

**❌ AVOID** - Separate XR file (adds complexity):
```kcl
spec: {
    xrPath: "xr.yaml"  # Avoid unless necessary
}
```

### Test Naming Conventions

```kcl
# Composition tests: test-<resource-type>-<scenario>
metadata.name: "test-xvpc-simple"
metadata.name: "test-xvpc-public-subnets"
metadata.name: "test-xvpc-nat-per-az"

# E2E tests: e2etest-<resource-type>-<scenario>
metadata.name: "e2etest-xvpc-basic"
metadata.name: "e2etest-xvpc-complete"
```

### Timeout Configuration

```kcl
# Composition tests (no real resources)
timeoutSeconds: 60  # 1 minute sufficient

# E2E tests (creates real AWS resources)
timeoutSeconds: 1800  # 30 minutes
cleanupTimeoutSeconds: 600  # 10 minutes for cleanup
```

### Testing Conditional Resources

```kcl
# Test resource IS created when flag is true
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
        metadata: { name: "igw-test-vpc" }
    }
]

# Test resource is NOT created when flag is false
# (simply omit from assertResources)
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
    # List each expected subnet explicitly
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
                    # Name tag added automatically
                }
            }
        }
    }
]
```

---

## Testing Types

**For test pyramid, test strategy, and TDD workflow, see [TDD_STRATEGY.md](TDD_STRATEGY.md)**

This reference covers the technical details of writing and running tests.

### Composition Rendering

Preview composed resources locally:

```bash
# Preview what resources will be created
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Save output for inspection
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml > /tmp/rendered.yaml
```

---

## Test Organization

### Directory Structure

```
tests/
├── test-xvpc-basic/              # VPC creation
├── test-xvpc-subnets-public/     # Public subnets
├── test-xvpc-subnets-private/    # Private subnets
├── test-xvpc-subnets-database/   # Database subnets
├── test-xvpc-igw-enabled/        # Internet Gateway enabled
├── test-xvpc-igw-disabled/       # Internet Gateway disabled
├── test-xvpc-nat-single/         # Single NAT Gateway
├── test-xvpc-nat-per-az/         # NAT per AZ
├── test-xvpc-nat-disabled/       # No NAT Gateway
├── test-xvpc-routes-public/      # Public routing
├── test-xvpc-routes-private-single-nat/  # Private routing (single NAT)
├── test-xvpc-routes-private-per-az/      # Private routing (NAT per AZ)
├── test-xvpc-routes-isolated/            # Isolated routing
├── test-xvpc-routes-database-nat/        # Database routing with NAT
├── e2etest-xvpc-basic/           # E2E: Basic VPC
├── e2etest-xvpc-nat-single/      # E2E: VPC with single NAT
├── e2etest-xvpc-nat-per-az/      # E2E: VPC with NAT per AZ
└── e2etest-xvpc-complete/        # E2E: All features
```

### Naming Convention

**Composition Tests**:
```
test-xvpc-<feature>[-<variant>]

Examples:
- test-xvpc-basic
- test-xvpc-nat-single
- test-xvpc-routes-private-single-nat
```

**E2E Tests**:
```
e2etest-xvpc-<scenario>

Examples:
- e2etest-xvpc-basic
- e2etest-xvpc-complete
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

### Test Scenarios

**See [TDD_STRATEGY.md → Test Content Standards](TDD_STRATEGY.md#test-content-standards) for complete test scenario guidance.**

---

## E2E Tests

### Authentication: No AWS Credentials Required

**CRITICAL UNDERSTANDING**: E2E tests in this project do NOT require AWS static credentials (access keys/secret keys).

**How it works**:
1. E2E tests use Upbound's web identity federation
2. ProviderConfig specifies `source: "Upbound"` with `webIdentity.roleARN`
3. Upbound's identity provider authenticates to AWS using the specified IAM role
4. NO secrets need to be stored or managed locally
5. This is more secure than static credentials and follows AWS best practices

**Example ProviderConfig** (always use this pattern):
```kcl
extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"
        kind: "ProviderConfig"
        metadata: {
            name: "default"
            namespace: "default"
        }
        spec: {
            credentials: {
                source: "Upbound"  # Uses Upbound's web identity federation
                upbound: {
                    webIdentity: {
                        roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                    }
                }
            }
        }
    }
]
```

**Test Duration**: E2E tests typically take 30-40 minutes due to AWS resource provisioning times. This is expected and acceptable - do not skip E2E tests due to time concerns.

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
            # See "Authentication: No AWS Credentials Required" section for ProviderConfig details
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"  # REQUIRED for namespaced claims
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"
                            upbound: {
                                webIdentity: {
                                    roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
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

1. **Accept test duration**: E2E tests are slow (see Test Duration above) - do NOT skip E2E tests due to time concerns.
2. **Run on Upbound Cloud**: Always use dedicated control plane group
3. **Clean up resources**: Ensure skipDelete=false in CI
4. **Use web identity for authentication**: ProviderConfig with `source: "Upbound"` and `webIdentity.roleARN` (NO static credentials needed)
5. **Test critical paths**: E2E validates real cloud integration that composition tests cannot
6. **Run in CI with labels**: Use "run-e2e-tests" label to trigger
7. **ALWAYS specify control plane group**: Never rely on default context

---

## Control Plane Configuration

### CRITICAL: Always Use Dedicated Control Plane Group

**For control plane architecture (org/space/group hierarchy), see [UPBOUND_REFERENCE.md → Platform Architecture](UPBOUND_REFERENCE.md#platform-architecture)**

**IMPORTANT**: E2E tests should ALWAYS run on a dedicated control plane group for testing, NOT on production control plane groups.

### Local E2E Testing

**ALWAYS specify control plane group explicitly:**

```bash
# ✅ CORRECT - Run E2E tests locally
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# ❌ WRONG - Uses current context (might be production!)
up test run tests/e2etest-* --e2e
```

**Available group**: `claude-testing` (in organization "solutions", space "upbound-gcp-us-central-1")

**For complete E2E test execution flow, see [E2E Test Execution Flow](#e2e-test-execution-flow) section above.**

### Useful E2E Flags

```bash
--control-plane-group=STRING         # Which group to use (REQUIRED for local testing)
--skip-control-plane-cleanup         # Keep control plane for debugging
--use-current-context                # Use existing control plane instead of creating new
--organization=STRING                # Override organization (default: solutions)
```

**For complete control plane management commands, see [UPBOUND_REFERENCE.md → Control Plane Management](UPBOUND_REFERENCE.md#control-plane-management)**

### Debugging Failed E2E Tests

**Keep control plane for investigation:**

```bash
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=claude-testing \
  --skip-control-plane-cleanup
```

**Then inspect:**

```bash
up ctx <control-plane-name>
kubectl get composite
kubectl get managed
kubectl describe vpc <name>
```

### Complete E2E Workflow

```bash
# 1. Run E2E tests
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing

# 2. If test fails and you need to debug, keep control plane:
up test run tests/e2etest-xvpc-simple \
  --e2e \
  --control-plane-group=claude-testing \
  --skip-control-plane-cleanup

# 3. Inspect the control plane
up ctx <control-plane-name>
kubectl get all
```

### Best Practices

- ✅ **ALWAYS** use `--control-plane-group=claude-testing` for local E2E tests
- ✅ **NEVER** run E2E tests without specifying control plane group
- ✅ **NEVER** run E2E tests on production control plane groups
- ✅ E2E tests create temporary control planes automatically
- ✅ Control planes are cleaned up automatically (unless `--skip-control-plane-cleanup`)

### IAM Role for E2E Tests

**CRITICAL**: Use this IAM role for E2E tests:
```
arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
```

**See [Authentication: No AWS Credentials Required](#authentication-no-aws-credentials-required) section above for complete ProviderConfig setup and authentication details.**

---

## KCL Testing Patterns

For KCL-specific assertion patterns, test structure, and examples, see [KCL_REFERENCE.md → Part 8: Testing Patterns](KCL_REFERENCE.md#part-8-testing-patterns).

**Quick reference**:
- Always define XR inline for composition tests
- Use descriptive test names: `test-<resource>-<scenario>`
- Set appropriate timeouts: 60-120s for composition, 1800s+ for E2E
- See KCL_REFERENCE.md for complete patterns and examples

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

## Success Metrics

### Code Coverage
- ✅ 100% of features have composition tests
- ✅ 100% of critical paths have E2E tests
- ✅ All tests documented with expected behavior

### Test Health
- ✅ All tests pass before every commit
- ✅ No flaky tests (99.9% pass rate)
- ✅ Fast tests (< 10s per composition test)
- ✅ E2E tests clean up resources (no orphans)

### Feature Parity
- ✅ All Terraform inputs tested
- ✅ All Terraform outputs tested
- ✅ Side-by-side validation passes
- ✅ Behavior matches Terraform module

---

## CI/CD Integration

**See [TDD_STRATEGY.md → CI/CD Integration](TDD_STRATEGY.md#cicd-integration) for GitHub workflows, local testing commands, and cost considerations.**

---

## Debugging

### Quick Debugging Tips

**Composition Tests**:
- Render to see output: `up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml`
- Check error message for missing fields or type mismatches
- Verify `metadata.name` is set in assertResources

**E2E Tests**:
- Check resource status: `kubectl describe xvpc my-vpc`
- View events: `kubectl get events --sort-by='.lastTimestamp'`
- Monitor with kubectl: `kubectl get managed`, `kubectl describe <resource>`

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

**See [Authentication: No AWS Credentials Required](#authentication-no-aws-credentials-required) section above for complete ProviderConfig configuration and requirements.**

#### Console Troubleshooting (E2E Tests)

**Problem: Package stuck "Installing"**

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

**Problem: Resource stuck "Creating"**

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

**Problem: All resources stuck**

**Steps:**
1. Navigate to: Control Plane → Managed Resources
2. Filter by: ProviderConfig kind
3. Check: ProviderConfig status
4. If not Ready: IAM auth failed
5. Verify: IAM role ARN is correct


**Key Rules**:
- Namespaced claims (kind: VPC with namespace) → ProviderConfig MUST have namespace
- Cluster-scoped composites (kind: XVPC, no namespace) → ProviderConfig can be cluster-scoped
- Crossplane v2 uses `.m.` suffix for namespaced managed resource providers

---

## Testing Strategy

**See [TDD_STRATEGY.md](TDD_STRATEGY.md) for complete testing strategy, test coverage goals, and phase-by-phase testing approach.**

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
