# KCL Testing Patterns for Upbound

## Overview

This document describes patterns for writing tests in KCL for Upbound projects based on the up-cli source code analysis.

## CompositionTest Schema

### Key Fields

Based on `/tmp/up/pkg/apis/compositiontest/v1alpha1/compositiontest_types.go`:

```kcl
CompositionTest {
    metadata: {
        name: string  // Test name
    }
    spec: {
        // REQUIRED: At least 60 seconds recommended
        timeoutSeconds: int  // Default: 30

        // Optional: Validate managed resources against schemas
        validate: bool  // Default: False

        // XR Definition: Choose ONE of these two options
        xr: {}          // Define XR inline (runtime.RawExtension)
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
}
```

### Defining XR Inline

**Pattern**: Use the `xr` field instead of `xrPath` to define the composite resource directly in KCL:

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
                    assert: {
                        "spec.forProvider.cidrBlock": "10.0.0.0/16"
                        "spec.forProvider.region": "us-west-2"
                    }
                },
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    count: 2  # Expect 2 subnets
                    assert: {
                        "spec.forProvider.region": "us-west-2"
                    }
                }
            ]
        }
    }
]
items = _items
```

### Assert Resources Pattern

**Purpose**: Validate that composition creates expected managed resources with correct specifications.

```kcl
assertResources: [
    {
        # Resource type to assert
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"

        # Optional: Expected count (omit for exactly 1)
        count: 1

        # Field assertions using dot notation
        assert: {
            # Check forProvider fields
            "spec.forProvider.cidrBlock": "10.0.0.0/16"
            "spec.forProvider.region": "us-west-2"
            "spec.forProvider.enableDnsHostnames": True

            # Check tags
            "spec.forProvider.tags.Environment": "test"
            "spec.forProvider.tags.Name": "my-vpc"

            # Check selectors
            "spec.forProvider.vpcIdSelector.matchControllerRef": True
        }
    },
    {
        # Multiple resources of same type
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        count: 3  # Expect exactly 3 subnets
        assert: {
            "spec.forProvider.vpcIdSelector.matchControllerRef": True
            "spec.forProvider.mapPublicIpOnLaunch": True
        }
    }
]
```

### Observed Resources Pattern

**Purpose**: Check status conditions on existing resources.

```kcl
observedResources: [
    {
        apiVersion: "kubernetes.crossplane.io/v1alpha1"
        kind: "ProviderConfig"
        metadata.name: "default"
        status: {
            conditions: [
                {
                    type: "Ready"
                    status: "True"
                }
            ]
        }
    }
]
```

## E2ETest Schema

### Key Fields

Based on `/tmp/up/pkg/apis/e2etest/v1alpha1/e2etest_types.go`:

```kcl
E2ETest {
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
}
```

### E2E Test Pattern

```kcl
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_items = [
    metav1alpha1.E2ETest {
        metadata.name: "e2etest-xvpc-simple"
        spec: {
            # Crossplane configuration
            crossplane: {
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts (in seconds)
            timeoutSeconds: 1800       # 30 minutes
            cleanupTimeoutSeconds: 600 # 10 minutes
            skipDelete: False          # Clean up after test

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Main test resources
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"  # Using Claim
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

            # Additional resources (ProviderConfig, etc.)
            extraResources: [
                {
                    apiVersion: "aws.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                    }
                    spec: {
                        # IMPORTANT: Use IAM role, NEVER static credentials
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
items = _items
```

## Important Patterns

### 1. Always Define XR Inline for Composition Tests

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

### 2. Use Descriptive Test Names

```kcl
# Pattern: test-<resource-type>-<scenario>
metadata.name: "test-xvpc-simple"
metadata.name: "test-xvpc-public-subnets"
metadata.name: "test-xvpc-nat-per-az"

# E2E tests: e2etest-<resource-type>-<scenario>
metadata.name: "e2etest-xvpc-basic"
```

### 3. Add Comments Linking to Spec

```kcl
assertResources: [
    {
        # Spec: terraform-vpc-analysis.md - Basic VPC creation
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        assert: {
            # Spec: VPC should have correct CIDR block
            "spec.forProvider.cidrBlock": "10.0.0.0/16"
        }
    }
]
```

### 4. Set Appropriate Timeouts

```kcl
# Composition tests: 60-120 seconds (no real resources)
timeoutSeconds: 60

# E2E tests: 1800+ seconds (creates real AWS resources)
timeoutSeconds: 1800  # 30 minutes
cleanupTimeoutSeconds: 600  # 10 minutes
```

### 5. Use IAM Roles for E2E Tests

**✅ ALWAYS** use assumeRoleChain:
```kcl
extraResources: [
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
]
```

**❌ NEVER** use static credentials in tests.

## Test Organization

### Directory Structure

```
tests/
├── test-xvpc-simple/           # Composition test
│   ├── kcl.mod
│   ├── kcl.mod.lock
│   ├── main.k                  # Test with inline XR
│   └── model -> ../../.up/kcl/models
├── test-xvpc-multi-az/         # Another composition test
│   ├── main.k
│   └── ...
└── e2etest-xvpc-basic/         # E2E test
    ├── main.k
    └── ...
```

### Generating Tests

```bash
# Generate composition test (with inline XR support)
up test generate test-xvpc-simple --language=kcl

# Generate E2E test
up test generate e2etest-xvpc-basic --e2e --language=kcl
```

### Running Tests

```bash
# Run all composition tests (fast, no cluster)
up test run tests/test-*

# Run specific composition test
up test run tests/test-xvpc-simple

# Run E2E test (requires up login, creates real resources)
up test run tests/e2etest-xvpc-basic --e2e
```

## Common Patterns

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
        count: 1  # Should exist
    }
]

# Test that IGW is NOT created when createIgw: false
xr: {
    spec: {
        createIgw: False
        publicSubnets: ["10.0.1.0/24"]
    }
}
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "InternetGateway"
        count: 0  # Should NOT exist
    }
]
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
        count: 3  # Expect exactly 3 subnets
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
        assert: {
            "spec.forProvider.tags.Environment": "production"
            "spec.forProvider.tags.Team": "platform"
        }
    }
]
```

## Terraform Test Case Mapping

When creating tests based on Terraform module examples:

1. **Simple Example** → `test-xvpc-simple` composition test
2. **Complete Example** → `test-xvpc-complete` composition test + `e2etest-xvpc-complete`
3. **NAT Strategies** → `test-xvpc-nat-single`, `test-xvpc-nat-per-az`
4. **VPC Endpoints** → `test-xvpc-endpoints-gateway`, `test-xvpc-endpoints-interface`
5. **Network ACLs** → `test-xvpc-nacl`
6. **Flow Logs** → `test-xvpc-flow-logs`

## Summary

- **Use `xr` field** to define composite resources inline in KCL tests
- **Add spec comments** to link test assertions back to requirements
- **Use appropriate timeouts**: 60s for composition tests, 1800s+ for E2E tests
- **Always use IAM roles** in E2E tests, never static credentials
- **Test both positive and negative cases** (resource created vs not created)
- **Reference Terraform examples** to ensure feature parity coverage
