# Key Learnings from Testing Implementation

## Critical Insight: AssertResources Structure

**IMPORTANT**: The `assertResources` field expects FULL Kubernetes resource definitions, not a special "assert" syntax.

### ❌ WRONG Pattern (Does NOT Work)

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

### ✅ CORRECT Pattern (Works!)

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

## How AssertResources Works

1. The test framework uses Chainsaw (Kubernetes testing framework) under the hood
2. It matches resources by: `apiVersion`, `kind`, and `metadata.name`
3. Once it finds a match, it checks if the specified fields in your assertion match the rendered resource
4. You only need to specify the fields you want to assert - partial matching is supported
5. The resource name MUST be the exact name that your composition generates

## Finding Resource Names

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

## Complete Working Test Example

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

            # Define XR inline
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

            # Assert resources with FULL resource definitions
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
                            tags: {
                                Environment: "test"
                                Type: "public"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items = _items
```

## Troubleshooting

### Error: "no actual resource found: ec2.aws.upbound.io/v1beta1/VPC/"

**Cause**: Empty name in the resource lookup (note the trailing "/")

**Solution**: Add `metadata.name` to your assertResources with the exact name your composition generates

### How to Debug

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

## Composition vs E2E Tests

### Composition Tests (Fast)
- Use `CompositionTest` type
- Use `assertResources` for validation
- No real AWS resources created
- Runs in seconds
- Perfect for TDD and rapid iteration

### E2E Tests (Slow)
- Use `E2ETest` type
- Use `manifests` for test resources
- Creates real AWS resources
- Uses `defaultConditions: ["Ready", "Synced"]` for validation
- Runs in minutes
- Use for final validation before release

## Summary

- ✅ Always use FULL resource definitions in `assertResources`
- ✅ Always specify `metadata.name` that matches generated names
- ✅ Use `up composition render` to find correct resource names
- ✅ Partial field matching is supported - only assert what matters
- ❌ Never use a fake "assert" field - it doesn't exist
- ❌ Don't leave metadata.name empty or the test will fail
