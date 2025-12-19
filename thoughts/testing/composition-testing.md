# Composition Testing Guide

## Overview

Composition tests are **fast unit tests** that validate composition function logic without requiring a live control plane or cloud resources. They simulate the composition controller's behavior locally.

**Speed**: Seconds (typically < 10 seconds per test)

**Purpose**: Validate KCL logic, resource generation, conditional branching, and resource specifications

**When to use**: Development (fast feedback), CI on every PR, before E2E tests

---

## Table of Contents

1. [What is Composition Testing](#what-is-composition-testing)
2. [Test Structure](#test-structure)
3. [Test Generation](#test-generation)
4. [Writing Tests in KCL](#writing-tests-in-kcl)
5. [assertResources](#assertresources)
6. [observedResources](#observedresources)
7. [Running Tests](#running-tests)
8. [Test Scenarios](#test-scenarios)
9. [Best Practices](#best-practices)
10. [Examples](#examples)

---

## What is Composition Testing

**Definition**: Composition tests validate that your KCL composition function generates the correct managed resources for given inputs.

**How it works**:
- Models a single composition controller loop
- Uses mock data instead of live Kubernetes resources
- No control plane required
- No cloud resources created
- Tests KCL logic in isolation

**Benefits**:
- ✅ **Fast**: Seconds vs 20-40 minutes for E2E
- ✅ **Free**: No cloud costs
- ✅ **Isolated**: Tests logic without external dependencies
- ✅ **Deterministic**: Same input always produces same output
- ✅ **Iterable**: Rapid test-fix-test cycle

**Trade-offs**:
- ✅ Fast feedback on logic errors
- ✅ Catch syntax and schema errors early
- ❌ Doesn't validate real AWS behavior
- ❌ Doesn't test provider integration
- ❌ Can't test resource lifecycle (Ready/Synced)

**Use cases**:
- Verify correct number of resources created
- Validate resource specifications match inputs
- Test conditional logic (feature flags, strategies)
- Test resource naming and tagging
- Verify dependencies and ordering
- Catch KCL syntax errors

---

## Test Structure

### Schema Definition

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

test = metav1alpha1.CompositionTest {
    # Paths to composition files
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/simple-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"

    # Test configuration
    timeoutSeconds = 60           # Usually 60s is enough
    validate = True               # Enable schema validation

    # Assert that these resources are created
    assertResources = [
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "VPC"
            name = "test-vpc"
            # Specify expected spec fields...
        }
    ]

    # Observe resource conditions
    observedResources = [
        {
            name = "test-vpc"
            conditions = [
                { type = "Ready", status = "True" }
            ]
        }
    ]
}
```

### Key Fields

| Field | Purpose | Example | Required |
|-------|---------|---------|----------|
| `compositionPath` | Path to composition YAML | `"../../apis/vpc/composition.yaml"` | ✅ YES |
| `xrPath` | Path to example XR | `"../../examples/simple-vpc.yaml"` | ✅ YES |
| `xrdPath` | Path to XRD definition | `"../../apis/vpc/definition.yaml"` | ✅ YES |
| `timeoutSeconds` | Max execution time | `60` | ❌ Optional (default: 60) |
| `validate` | Enable schema validation | `True` | ❌ Optional (default: True) |
| `assertResources` | Expected resources | Array of resources | ❌ Optional (but recommended) |
| `observedResources` | Expected conditions | Array of observations | ❌ Optional |

---

## Test Generation

### Generate Test Structure

Use `up test generate` to create test scaffolding:

```bash
# Generate KCL composition test
up test generate test-xvpc-basic --language=kcl

# Generate Python composition test
up test generate test-xvpc-complex --language=python

# Generate YAML composition test (default)
up test generate test-xvpc-subnets
```

**What this creates**:
```
tests/
└── test-xvpc-basic/
    ├── kcl.mod           # KCL dependencies
    ├── kcl.mod.lock      # Dependency lock file
    └── main.k            # Test definition (edit this!)
```

### Dependencies (kcl.mod)

The generated `kcl.mod` includes necessary dependencies:

```toml
[package]
name = "test-xvpc-basic"

[dependencies]
# Add your dependencies here
```

---

## Writing Tests in KCL

### Basic Test Template

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

# Test definition
test = metav1alpha1.CompositionTest {
    # File paths (relative to test directory)
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/simple-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"

    # Timeout (usually 60 seconds is enough for composition tests)
    timeoutSeconds = 60

    # Enable validation
    validate = True

    # Assert expected resources
    assertResources = [
        # Add your assertions here
    ]
}

# Export the test
items = [test]
```

### Testing Different Scenarios

**Test with different XR inputs**:

```kcl
# Option 1: Point to different example files
xrPath = "../../examples/vpc-with-nat.yaml"

# Option 2: Inline XR definition
# (Advanced - requires understanding XR schema)
```

### Multiple Tests in One File

```kcl
# Test 1: Basic VPC
test_basic = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/basic-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"
    # ...
}

# Test 2: VPC with NAT
test_nat = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/vpc-with-nat.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"
    # ...
}

# Export both tests
items = [test_basic, test_nat]
```

---

## assertResources

**Purpose**: Validate that composition function generates expected managed resources.

### Basic Assertion

```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test-vpc"  # Expected resource name
        # The test validates this resource exists in output
    }
]
```

### Assert with Spec Fields

```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test-vpc"
        spec = {
            forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                enableDnsSupport = True
                enableDnsHostnames = True
            }
        }
    }
]
```

### Assert Multiple Resources

```kcl
assertResources = [
    # VPC
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test-vpc"
    },
    # Subnet 1
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        name = "subnet-public-test-vpc-us-west-2a"
        spec.forProvider = {
            availabilityZone = "us-west-2a"
            cidrBlock = "10.0.1.0/24"
        }
    },
    # Subnet 2
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        name = "subnet-public-test-vpc-us-west-2b"
        spec.forProvider = {
            availabilityZone = "us-west-2b"
            cidrBlock = "10.0.2.0/24"
        }
    }
]
```

### Assert Resource Metadata

```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test-vpc"
        metadata = {
            labels = {
                "crossplane.io/claim-name" = "test-vpc"
            }
            # Can also assert annotations
        }
    }
]
```

### Important: assertResources Expectations

**CRITICAL**: `assertResources` expects **FULL resource definitions**, not partial matches!

**Wrong** (will fail):
```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test"
        # Missing spec - test will fail!
    }
]
```

**Correct**:
```kcl
assertResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        name = "vpc-test"
        spec = {
            forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                # Include all fields your function generates
            }
        }
    }
]
```

---

## observedResources

**Purpose**: Validate resource status and conditions (simulated).

### Basic Condition Check

```kcl
observedResources = [
    {
        name = "vpc-test-vpc"
        conditions = [
            { type = "Ready", status = "True" }
        ]
    }
]
```

### Multiple Conditions

```kcl
observedResources = [
    {
        name = "vpc-test-vpc"
        conditions = [
            { type = "Ready", status = "True" },
            { type = "Synced", status = "True" }
        ]
    }
]
```

### Observe Multiple Resources

```kcl
observedResources = [
    {
        name = "vpc-test-vpc"
        conditions = [
            { type = "Ready", status = "True" }
        ]
    },
    {
        name = "subnet-public-test-vpc-us-west-2a"
        conditions = [
            { type = "Ready", status = "True" }
        ]
    }
]
```

---

## Running Tests

### Run All Tests

```bash
# Run all composition tests
up test run tests/test-*

# Run all tests (composition + E2E)
up test run tests/*
```

### Run Specific Test

```bash
# Run specific test directory
up test run tests/test-xvpc-basic

# Run specific test file
up test run tests/test-xvpc-basic/main.k
```

### Run with Pattern Matching

```bash
# Run all VPC tests
up test run tests/test-xvpc-*

# Run all subnet tests
up test run tests/test-*-subnets
```

### Verbose Output

```bash
# Show detailed output
up test run tests/test-xvpc-basic --verbose

# Show debug information
up test run tests/test-xvpc-basic --debug
```

### Expected Output

**Success**:
```
Running test: test-xvpc-basic
  Loading composition: ../../apis/vpc/composition.yaml ✓
  Loading XR: ../../examples/simple-vpc.yaml ✓
  Loading XRD: ../../apis/vpc/definition.yaml ✓
  Executing composition function ✓
  Validating resources (10 resources) ✓
  All assertions passed ✓

Test: PASSED ✓
Duration: 3.2s
```

**Failure**:
```
Running test: test-xvpc-basic
  Loading composition: ../../apis/vpc/composition.yaml ✓
  Loading XR: ../../examples/simple-vpc.yaml ✓
  Loading XRD: ../../apis/vpc/definition.yaml ✓
  Executing composition function ✓
  Validating resources (8 resources) ✗

Error: Expected 10 resources, got 8
Missing resources:
  - Subnet/subnet-public-test-vpc-us-west-2c
  - RouteTableAssociation/rta-public-test-vpc-us-west-2c

Test: FAILED ✗
Duration: 2.8s
```

---

## Test Scenarios

### Test Scenarios to Cover

For each major feature, create composition tests for:

1. **Basic scenario**: Minimal required inputs
   - Example: VPC with single public subnet

2. **Complex scenario**: All options enabled
   - Example: VPC with all 6 subnet types, NAT, endpoints

3. **Conditional logic**: Features enabled/disabled
   - Example: VPC with `enableNatGateway: false` vs `true`

4. **Strategy variations**: Different implementation strategies
   - Example: Single NAT vs NAT per AZ

5. **Edge cases**: Boundary conditions
   - Example: Single AZ vs 6 AZs

6. **Multiple resources**: Test resource generation
   - Example: 3 subnets × 3 AZs = 9 subnets

7. **Dependencies**: Resources that depend on others
   - Example: Route table associations depend on subnets

### Example Test Matrix for VPC

| Test | What It Validates | Resources Expected |
|------|-------------------|-------------------|
| `test-xvpc-basic` | Minimal VPC | 1 VPC |
| `test-xvpc-public-subnets` | Public subnets across AZs | 1 VPC + 3 Subnets |
| `test-xvpc-private-subnets` | Private subnets | 1 VPC + 6 Subnets (3 public, 3 private) |
| `test-xvpc-igw` | Internet Gateway | 1 VPC + 3 Subnets + 1 IGW |
| `test-xvpc-nat-single` | Single NAT Gateway | 1 VPC + 6 Subnets + 1 IGW + 1 NAT + 1 EIP |
| `test-xvpc-nat-per-az` | NAT per AZ | 1 VPC + 6 Subnets + 1 IGW + 3 NAT + 3 EIP |
| `test-xvpc-routes` | Routing logic | Above + Route Tables + Routes + Associations |
| `test-xvpc-complete` | All features | 40+ resources |

---

## Best Practices

### DO:
- ✅ **Write tests first** (TDD: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR)
- ✅ **Test each feature independently** (one feature per test)
- ✅ **Use descriptive test names** (`test-xvpc-nat-single`, not `test1`)
- ✅ **Assert all generated resources** (don't skip resources)
- ✅ **Test conditional logic** (feature enabled vs disabled)
- ✅ **Test edge cases** (single AZ, many AZs, empty inputs)
- ✅ **Keep tests fast** (< 10 seconds each)
- ✅ **Run tests frequently** (every code change)
- ✅ **Include README in test directory** (explain what's tested)

### DON'T:
- ❌ **Skip composition tests** ("E2E is enough")
- ❌ **Test too much in one test** (split complex scenarios)
- ❌ **Forget to test feature flags** (test both enabled/disabled)
- ❌ **Use partial assertions** (assertResources needs full specs)
- ❌ **Ignore test failures** (fix immediately)
- ❌ **Write tests after implementation** (TDD: test first!)
- ❌ **Forget to update tests** (when changing composition logic)

---

## Examples

### Example 1: Test VPC Creation

**File**: `tests/test-xvpc-basic/main.k`

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

test = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/basic-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"

    timeoutSeconds = 60
    validate = True

    assertResources = [
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "VPC"
            name = "vpc-basic-vpc"
            spec.forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                enableDnsSupport = True
                enableDnsHostnames = True
                tags = {
                    Name = "basic-vpc"
                    ManagedBy = "crossplane"
                }
            }
        }
    ]
}

items = [test]
```

---

### Example 2: Test Subnets Across Multiple AZs

**File**: `tests/test-xvpc-subnets/main.k`

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

test = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/vpc-with-subnets.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"

    timeoutSeconds = 60
    validate = True

    assertResources = [
        # VPC
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "VPC"
            name = "vpc-test-vpc"
        },
        # Subnet in AZ-a
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "Subnet"
            name = "subnet-public-test-vpc-us-west-2a"
            spec.forProvider = {
                availabilityZone = "us-west-2a"
                cidrBlock = "10.0.1.0/24"
                mapPublicIpOnLaunch = True
            }
        },
        # Subnet in AZ-b
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "Subnet"
            name = "subnet-public-test-vpc-us-west-2b"
            spec.forProvider = {
                availabilityZone = "us-west-2b"
                cidrBlock = "10.0.2.0/24"
                mapPublicIpOnLaunch = True
            }
        },
        # Subnet in AZ-c
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "Subnet"
            name = "subnet-public-test-vpc-us-west-2c"
            spec.forProvider = {
                availabilityZone = "us-west-2c"
                cidrBlock = "10.0.3.0/24"
                mapPublicIpOnLaunch = True
            }
        }
    ]
}

items = [test]
```

---

### Example 3: Test Conditional Logic (NAT Gateway)

**File**: `tests/test-xvpc-nat-conditional/main.k`

```kcl
import models.io.upbound.sa.v1alpha1 as metav1alpha1

# Test 1: NAT Gateway DISABLED
test_no_nat = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/vpc-no-nat.yaml"  # enableNatGateway: false
    xrdPath = "../../apis/vpc/definition.yaml"

    assertResources = [
        # Should NOT create NAT Gateway or EIP
        # Only VPC, Subnets, IGW, Route Tables
    ]
}

# Test 2: NAT Gateway ENABLED (single)
test_single_nat = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/vpc-single-nat.yaml"  # enableNatGateway: true, singleNatGateway: true
    xrdPath = "../../apis/vpc/definition.yaml"

    assertResources = [
        # Should create 1 NAT Gateway and 1 EIP
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "EIP"
            name = "eip-nat-test-vpc-us-west-2a"
        },
        {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "NATGateway"
            name = "nat-test-vpc-us-west-2a"
        }
    ]
}

# Test 3: NAT Gateway PER AZ
test_nat_per_az = metav1alpha1.CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/vpc-nat-per-az.yaml"  # oneNatGatewayPerAz: true
    xrdPath = "../../apis/vpc/definition.yaml"

    assertResources = [
        # Should create 3 NAT Gateways and 3 EIPs (one per AZ)
        { kind = "EIP", name = "eip-nat-test-vpc-us-west-2a" },
        { kind = "EIP", name = "eip-nat-test-vpc-us-west-2b" },
        { kind = "EIP", name = "eip-nat-test-vpc-us-west-2c" },
        { kind = "NATGateway", name = "nat-test-vpc-us-west-2a" },
        { kind = "NATGateway", name = "nat-test-vpc-us-west-2b" },
        { kind = "NATGateway", name = "nat-test-vpc-us-west-2c" }
    ]
}

items = [test_no_nat, test_single_nat, test_nat_per_az]
```

---

## Debugging Test Failures

### Common Issues

**Issue 1: Resource not found**
```
Error: Expected resource not found: VPC/vpc-test
```
**Solution**: Check resource name matches what your function generates. Print generated resources to debug.

**Issue 2: Spec mismatch**
```
Error: Resource spec doesn't match assertion
Expected: cidrBlock="10.0.0.0/16"
Got: cidrBlock="10.0.0.0/24"
```
**Solution**: Verify your XR input and composition logic. Check CIDR calculation.

**Issue 3: Wrong resource count**
```
Error: Expected 10 resources, got 8
```
**Solution**: Debug composition function. Some resources not being generated. Check conditional logic.

**Issue 4: KCL syntax error**
```
Error: Syntax error in main.k:45
```
**Solution**: Fix KCL syntax. Check for missing commas, brackets, or type errors.

### Debugging Techniques

**1. Print generated resources**:
```bash
# Render composition to see what resources are generated
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml
```

**2. Run test with verbose output**:
```bash
up test run tests/test-xvpc-basic --verbose
```

**3. Check XRD schema**:
Ensure your XR input matches the XRD schema.

**4. Simplify assertions**:
Start with minimal assertions, then add more as tests pass.

---

## See Also

- [E2E Implementation Guide](e2e-implementation-guide.md) - Writing E2E tests
- [E2E Testing Reference](e2e-testing.md) - Complete E2E documentation
- [Testing Overview](TESTING_OVERVIEW.md) - Testing strategy
- [TDD Strategy](../development/TDD_STRATEGY.md) - Test-driven development workflow
- [KCL Guide](../development/kcl-guide.md) - KCL language reference

---

## Summary

Composition tests are **essential** for fast feedback during development. They validate KCL logic without the overhead of E2E tests.

**Key points**:
- Fast (seconds), free, isolated testing
- Validate resource generation and specifications
- Test conditional logic and edge cases
- Run on every commit in CI
- Write tests BEFORE implementing features (TDD)
- Assert all generated resources for complete coverage

**Workflow**:
1. Generate test: `up test generate test-xvpc-<feature> --language=kcl`
2. Write assertions in `main.k`
3. Run test: `up test run tests/test-xvpc-<feature>`
4. Fix issues, repeat
5. All tests pass → Write E2E test

**Remember**: Composition tests validate KCL logic. E2E tests validate AWS behavior. **Both are required!**
