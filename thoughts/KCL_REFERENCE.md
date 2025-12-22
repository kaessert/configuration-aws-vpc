# KCL Reference for Crossplane Composition Functions

A comprehensive reference guide for using KCL (KusionStack Configuration Language) to build Upbound composition functions and Crossplane configurations.

## Table of Contents

- [Part 1: Language Fundamentals](#part-1-language-fundamentals)
- [Part 2: Crossplane Resource Patterns](#part-2-crossplane-resource-patterns)
- [Part 3: Typed Models (CRITICAL)](#part-3-typed-models-critical)
- [Part 4: Function Development](#part-4-function-development)
- [Part 5: Best Practices](#part-5-best-practices)
- [Part 6: Troubleshooting](#part-6-troubleshooting)
- [Part 7: Quick Reference](#part-7-quick-reference)

---

## Related Documentation

This document focuses on KCL language syntax, patterns, and Crossplane-specific usage.

For related topics, see:
- **up CLI Commands**: [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)
- **Testing Workflows**: [TESTING_REFERENCE.md](TESTING_REFERENCE.md)
- **Git Commands**: [GIT_REFERENCE.md](GIT_REFERENCE.md)

---

## Part 1: Language Fundamentals

### Overview

**KCL (KusionStack Configuration Language)** is a purpose-built configuration and policy language developed by KusionStack, specifically designed for:

- Cloud infrastructure configuration
- Crossplane composition functions
- Policy as code
- Configuration composition and validation

**Why KCL for Upbound/Crossplane?**
- **Type Safety**: Strong static typing prevents configuration errors
- **Validation**: Built-in schema validation ensures correctness
- **Composition**: Native support for merging and composing configurations
- **Readability**: Clean, Python-like syntax
- **Integration**: First-class support in Upbound composition functions

### Basic Syntax

KCL uses Python-like syntax with strong typing:

```kcl
# Comments start with #

# Variable assignment
name = "my-vpc"
cidrBlock = "10.0.0.0/16"
enabled = True
count = 3

# Lists
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
]

# Dictionaries (maps)
tags = {
    Name: "production-vpc"
    Environment: "prod"
    Team: "platform"
}
```

### Data Types

KCL supports these primitive types:

```kcl
# String
name: str = "my-resource"
multi_line: str = """
This is a
multi-line string
"""

# Integer
count: int = 5
port: int = 443

# Float
price: float = 29.99
ratio: float = 0.5

# Boolean
enabled: bool = True
debug: bool = False

# None (null)
optional_value = None
```

### Collections

```kcl
# List
availability_zones: [str] = ["us-east-1a", "us-east-1b"]
numbers: [int] = [1, 2, 3, 4, 5]

# Dictionary (unordered key-value pairs)
metadata: {str: str} = {
    name: "my-app"
    version: "1.0.0"
}

# Nested structures
config = {
    vpc: {
        cidr: "10.0.0.0/16"
        subnets: [
            {name: "public-1", cidr: "10.0.1.0/24"},
            {name: "public-2", cidr: "10.0.2.0/24"}
        ]
    }
}
```

### Schema Definitions

Schemas are KCL's way of defining types and structures:

```kcl
# Basic Schema
schema VPC:
    """VPC configuration schema"""
    name: str
    cidrBlock: str
    region: str
    enableDnsHostnames?: bool = True
    enableDnsSupport?: bool = True
    tags?: {str: str}

# Using the schema
myVpc = VPC {
    name: "production-vpc"
    cidrBlock: "10.0.0.0/16"
    region: "us-east-1"
    tags: {
        Environment: "production"
    }
}
```

### Optional and Default Values

```kcl
schema Subnet:
    name: str
    cidrBlock: str
    availabilityZone: str
    mapPublicIpOnLaunch?: bool = False    # Optional with default
    tags?: {str: str}                      # Optional, no default

# Question mark (?) makes field optional
```

### Schema Validation Rules

```kcl
schema VPC:
    name: str
    cidrBlock: str
    maxAzCount: int = 3

    # Validation rules
    check:
        len(name) > 0, "Name cannot be empty"
        len(name) <= 255, "Name too long"
        maxAzCount >= 1 and maxAzCount <= 5, "AZ count must be 1-5"
```

### Configuration Composition

KCL has powerful composition operators:

```kcl
# Base configuration
base_vpc = {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
    enableDnsHostnames: True
}

# Override specific fields (| operator)
prod_vpc = base_vpc | {
    name: "prod-vpc"
    tags: {Environment: "production"}
}

# Merge configurations
extra_config = {
    enableDnsSupport: True
    tags: {Team: "platform"}
}

final_vpc = prod_vpc | extra_config
```

### Conditional Configuration

```kcl
environment = "production"

vpc_config = {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"

    # Conditional fields
    if environment == "production":
        enableFlowLogs: True
        natGatewayCount: 3
    else:
        enableFlowLogs: False
        natGatewayCount: 1
}
```

### List Comprehensions

```kcl
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Create subnet for each AZ
subnets = [
    {
        name: "subnet-${az}"
        availabilityZone: az
        cidrBlock: "10.0.${i}.0/24"
    }
    for i, az in enumerate(azs)
]
```

### Functions

#### Built-in Functions

```kcl
# String functions
name = "my-vpc"
upper_name = name.upper()              # "MY-VPC"
lower_name = name.lower()              # "my-vpc"
replaced = name.replace("-", "_")      # "my_vpc"
split_name = name.split("-")           # ["my", "vpc"]

# List functions
numbers = [1, 2, 3, 4, 5]
total = sum(numbers)                   # 15
length = len(numbers)                  # 5
sorted_nums = sorted(numbers)          # [1, 2, 3, 4, 5]

# Dictionary functions
config = {name: "vpc", region: "us-east-1"}
keys = list(config.keys())             # ["name", "region"]
values = list(config.values())         # ["vpc", "us-east-1"]

# Type conversions
str_num = str(42)                      # "42"
int_str = int("42")                    # 42
float_int = float(10)                  # 10.0

# Range
indices = range(5)                     # [0, 1, 2, 3, 4]
range_2_5 = range(2, 5)               # [2, 3, 4]
```

#### User-Defined Functions

```kcl
# Define a function
lambda calculateCidr(baseIp: str, index: int) -> str {
    "${baseIp}.${index}.0/24"
}

# Use the function
subnet_cidr = calculateCidr("10.0", 1)  # "10.0.1.0/24"

# Function with default parameters
lambda createSubnet(
    name: str,
    cidr: str,
    public: bool = False
) -> {str:} {
    {
        name: name
        cidrBlock: cidr
        mapPublicIpOnLaunch: public
    }
}

public_subnet = createSubnet("public-1", "10.0.1.0/24", True)
private_subnet = createSubnet("private-1", "10.0.10.0/24")
```

---

## Part 2: Crossplane Resource Patterns

### Resource Creation Pattern

KCL composition functions return **plain objects/dictionaries** representing Crossplane managed resources. Do NOT wrap them in `kubernetesv1alpha2.Object`.

```kcl
items = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        metadata = _metadata("vpc") | {
            name = "vpc-name"
            labels = { key = "value" }
        }
        spec = {
            forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                enableDnsHostnames = true
                enableDnsSupport = true
                tags = { Name = "my-vpc" }
            }
        }
    }
]
```

### Resource Structure Breakdown

1. **apiVersion**: The API group and version from the provider
   - Format: `<resource-group>.<provider>.upbound.io/<version>`
   - Example: `ec2.aws.upbound.io/v1beta1`

2. **kind**: The resource type (capitalized)
   - Examples: `VPC`, `Subnet`, `InternetGateway`

3. **metadata**: Resource metadata
   - **MUST** include `_metadata("resource-name")` annotation for composition tracking
   - Merge with `|` operator to add name and labels
   - The annotation `"krm.kcl.dev/composition-resource-name"` is critical for resource identity

4. **spec.forProvider**: The actual resource configuration
   - Matches the provider's CRD spec
   - See provider documentation for available fields

### Metadata Annotation Pattern

Always use the `_metadata()` helper function:

```kcl
_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}
```

This annotation:
- Uniquely identifies resources within the composition
- Enables resource tracking and updates
- Required for composition function to work correctly

Usage:
```kcl
metadata = _metadata("unique-resource-name") | {
    name = "actual-k8s-name"
    labels = {...}
}
```

### Resource Dependencies and References

To reference one resource from another, use selectors:

```kcl
spec.forProvider = {
    # Reference by name
    vpcIdRef = {
        name = "vpc-name"
    }

    # Or by selector (preferred)
    vpcIdSelector = {
        matchControllerRef = True  # Matches parent composite
    }
}
```

### Common Resource Patterns

#### Pattern 1: Parameterized Resource Generation

```kcl
schema SubnetConfig:
    name: str
    cidrBlock: str
    availabilityZone: str
    type: str  # "public" or "private"

lambda generateSubnetResources(configs: [SubnetConfig]) -> {str:} {
    {
        [config.name]: {
            apiVersion: "ec2.aws.upbound.io/v1beta1"
            kind: "Subnet"
            metadata.name: config.name
            spec.forProvider: {
                cidrBlock: config.cidrBlock
                availabilityZone: config.availabilityZone
                mapPublicIpOnLaunch: config.type == "public"
                vpcIdSelector.matchControllerRef: True
            }
        }
        for config in configs
    }
}
```

#### Pattern 2: Conditional Resource Creation

```kcl
lambda generateNATGateway(
    enabled: bool,
    subnetName: str,
    name: str
) -> {str:} | None {
    if enabled:
        {
            name: {
                apiVersion: "ec2.aws.upbound.io/v1beta1"
                kind: "NATGateway"
                metadata.name: name
                spec.forProvider: {
                    subnetIdSelector.matchLabels: {
                        name: subnetName
                    }
                    allocationIdSelector.matchControllerRef: True
                }
            }
        }
    else:
        None
}
```

#### Pattern 3: Tag Management

```kcl
lambda mergeTags(
    baseTags: {str: str},
    resourceTags: {str: str},
    name: str
) -> {str: str} {
    {
        Name: name
        **baseTags
        **resourceTags
    }
}

# Usage
common_tags = {
    Environment: "production"
    ManagedBy: "crossplane"
}

vpc_tags = mergeTags(
    common_tags,
    {Type: "networking"},
    "my-vpc"
)
# Result: {Name: "my-vpc", Environment: "production", ManagedBy: "crossplane", Type: "networking"}
```

### Common Mistakes

1. ❌ Wrapping in `kubernetesv1alpha2.Object`
   ```kcl
   # WRONG
   kubernetesv1alpha2.Object{
       spec.forProvider.manifest = {...}
   }
   ```

2. ❌ Forgetting the `_metadata()` annotation
   ```kcl
   # WRONG
   metadata = {
       name = "my-resource"
   }
   ```

3. ❌ Wrong API group format
   ```kcl
   # WRONG
   apiVersion = "v1beta1"  # Missing group
   ```

4. ✅ Correct pattern
   ```kcl
   {
       apiVersion = "ec2.aws.upbound.io/v1beta1"
       kind = "VPC"
       metadata = _metadata("vpc") | { name = "my-vpc" }
       spec.forProvider = {...}
   }
   ```

---

## Part 3: Typed Models (CRITICAL)

### Provider Version Requirements

**CRITICAL**: KCL typed models for EC2 managed resources require **provider-aws-ec2 v2.x or later**. Version v1.x does not properly generate KCL models.

**Required configuration** in `upbound.yaml`:
```yaml
spec:
  dependsOn:
  - apiVersion: pkg.crossplane.io/v1
    kind: Provider
    package: xpkg.upbound.io/upbound/provider-aws-ec2
    version: v2.3.0  # v2.x required
```

After updating dependencies: `up dep update-cache && up project build`

### Workflow for Typed Models

1. **Declare provider dependencies** in `upbound.yaml`
2. **Update cache**: `up dep update-cache`
3. **Build project**: `up project build`
4. **Check models**: `.up/kcl/models/` should contain typed schemas for all CRDs
5. **Import and use** typed models in composition functions:
   ```kcl
   import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

   vpc = ec2v1beta1.VPC{
       metadata = {...}
       spec = {...}
   }
   ```

### Key Learning About Import Paths

**CRITICAL**: The typed models import path follows the **directory structure** in `.up/kcl/models/`, NOT the Kubernetes API group convention.

**Correct Import Path**:
```kcl
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
```

**NOT**:
```kcl
# WRONG - This follows K8s convention but is incorrect for KCL
import models.ec2.aws.upbound.io.v1beta1 as ec2v1beta1
```

The import path maps directly to:
```
.up/kcl/models/io/upbound/aws/ec2/v1beta1/
```

### Benefits of Typed Models

**ALWAYS prefer typed objects over untyped dictionaries!**

For detailed examples and best practices, see [Part 5: Best Practice #6 - Use Typed Objects Everywhere](#6-use-typed-objects-everywhere).

**Key benefits**:
- Type safety and compile-time validation
- IDE autocomplete and documentation
- Prevents typos in apiVersion/kind fields
- Enforces correct schema structure

### Required Fields in Assertions

When using typed objects in test assertions, all required fields (especially `spec`) must be provided, even if you're only checking for resource existence. A minimal spec with required fields is sufficient for assertions.

Example:
```kcl
# In test assertions
assertResources = [
    ec2v1beta1.VPC{
        metadata.name = "vpc-name"
        spec.forProvider = {
            cidrBlock = "10.0.0.0/16"  # Required
            region = "us-west-2"       # Required
        }
    }
]
```

### Models Are Always Auto-Generated

**Key Principle**: Models are ALWAYS auto-generated by up-cli. If EC2 resource models (VPC, Subnet, etc.) are not appearing in `.up/kcl/models/`, something is wrong with:
- Provider version (use v2.x, not v1.x)
- Dependency cache (run `up dep update-cache`)
- Build process (run `up project build`)

You should NEVER manually create model files - they are generated from provider CRDs.

---

## Part 4: Function Development

### Generating Functions

**DO NOT** manually create function directories and files. Use `up function generate` instead.

**For command details, see [UPBOUND_REFERENCE.md → Function Management](UPBOUND_REFERENCE.md#function-management)**

The `up function generate` command automatically:
- Creates the `functions/<function-name>/` directory
- Generates `main.k` with proper imports and structure
- Creates `kcl.mod` with local model dependencies
- Sets up model symlink to `../../.up/kcl/models`
- Updates the composition.yaml to reference the function
- Configures the function in the pipeline

**CRITICAL**: After running `up function generate`, you MUST verify that `function-auto-ready` is included as the LAST pipeline step in your composition.yaml:

```yaml
# apis/vpc/composition.yaml
spec:
  mode: Pipeline
  pipeline:
  - functionRef:
      name: <your-function>
    step: <resource-generation>
  - functionRef:
      name: crossplane-contrib-function-auto-ready  # MANDATORY LAST STEP
    step: crossplane-contrib-function-auto-ready
```

**Why This Matters**: Without function-auto-ready, XRs never reach "Ready" status and E2E tests will timeout. This is a COMPOSITION PIPELINE REQUIREMENT for all Crossplane v2 compositions.

### KCL Module Dependencies

When using `up function generate`, the generated `kcl.mod` uses **local path dependencies**:

```toml
[package]
name = "vpc"
version = "0.0.1"

[dependencies]
models = { path = "./model" }
```

The `model` directory is actually a symlink to `../../.up/kcl/models`, which contains all the generated type models from:
- The XRD definitions in `apis/`
- The provider APIs from `dependsOn` in `upbound.yaml`

**DO NOT** use OCI registry dependencies in `kcl.mod`.

### Generated Model Imports

After running `up function generate`, the models are available as imports in your KCL code:

```kcl
# AWS Provider models
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Your XRD models (automatically generated from apis/ definitions)
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1

# Crossplane/Kubernetes models
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
```

The XRD namespace `io.upbound.platform.aws.v1alpha1` comes from the XRD definition:
- Group: `aws.platform.upbound.io` (reversed becomes `io.upbound.platform.aws`)
- Version: `v1alpha1`
- Kind: `XVPC`

### Composition Function Structure

```kcl
# Main composition function structure
import crossplane.fn as fn

# Get desired composed resources
items = fn.desired_composed_resources()

# Access observed resources
observed = fn.observed_composite_resource()

# Access input parameters
params = fn.input()

# Example: Create VPC and subnets based on input
vpc_name = params.name
vpc_cidr = params.cidrBlock
subnet_count = params.subnetCount or 3

# Generate VPC
items["vpc"] = {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "VPC"
    metadata.name: vpc_name
    spec.forProvider: {
        cidrBlock: vpc_cidr
        region: params.region
    }
}

# Generate subnets
for i in range(subnet_count):
    items["subnet-${i}"] = {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "Subnet"
        metadata.name: "${vpc_name}-subnet-${i}"
        spec.forProvider: {
            cidrBlock: "10.0.${i}.0/24"
            vpcIdSelector.matchControllerRef: True
            availabilityZone: params.azs[i]
        }
    }

# Return composed resources
fn.set_desired_composed_resources(items)
```

### Composition Pipeline Configuration

The generated composition.yaml includes the function in the pipeline:

```yaml
spec:
  mode: Pipeline
  pipeline:
  - functionRef:
      name: solutions-configuration-aws-vpcvpc  # Auto-generated function package name
    step: vpc
  - functionRef:
      name: function-kcl  # KCL runtime function
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLInput
      spec:
        source: oci://ghcr.io/upbound/configuration-aws-vpc/functions-vpc:latest
    step: vpc-resources
```

### Project Build Process

**See [UPBOUND_REFERENCE.md → Project Management](UPBOUND_REFERENCE.md#project-management) for build commands.**

After schema changes, run `up project build` to update language schemas (requires Docker).

---

## Part 5: Best Practices

### 1. Use Schemas for Type Safety

```kcl
# Good: Define schema first
schema VPCInput:
    name: str
    cidrBlock: str
    region: str

lambda createVPC(input: VPCInput) -> {str:} {
    # Implementation
}

# Bad: Using untyped dicts
lambda createVPC(input: {str:}) -> {str:} {
    # Less safe
}
```

### 2. Validate Input Early

```kcl
schema VPCConfig:
    name: str
    cidrBlock: str

    check:
        len(name) > 0, "Name required"
        len(name) <= 63, "Name too long"
        cidrBlock, "CIDR required"
```

### 3. Use Descriptive Names

```kcl
# Good
lambda generatePublicSubnet(name: str, cidr: str, az: str) -> {str:} {
    # Clear intent
}

# Bad
lambda gen(n: str, c: str, a: str) -> {str:} {
    # Unclear
}
```

### 4. Document Schemas

```kcl
schema VPC:
    """
    VPC configuration schema.

    Defines the structure for creating an AWS VPC with Crossplane.
    Includes validation rules for CIDR blocks and naming.
    """
    name: str
    """VPC name (max 63 characters)"""

    cidrBlock: str
    """VPC CIDR block (e.g., 10.0.0.0/16)"""
```

### 5. Modularize Code

```kcl
# Separate concerns into different files
# schemas/vpc.kcl - Type definitions
# functions/vpc.kcl - VPC-related functions
# compositions/vpc.kcl - Composition logic
```

### 6. Use Typed Objects Everywhere

**ALWAYS** prefer typed objects over untyped dictionaries when provider models are available:

```kcl
# Good - Typed objects
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

vpc = ec2v1beta1.VPC{
    metadata = {...}
    spec = {...}
}

# Bad - Untyped dictionaries
vpc = {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "VPC"
    metadata = {...}
    spec = {...}
}
```

### 7. File Organization

Follow the structure from platform-ref-upbound:

```
functions/vpc/
├── main.k              # Entry point, orchestration
├── kcl.mod             # Dependencies
├── vpc.k               # VPC resource generation
├── subnet.k            # Subnet logic
├── gateway.k           # Gateway logic
├── route.k             # Routing logic
└── utils/
    ├── metadata.k      # Metadata helpers
    └── tags.k          # Tag management
```

---

## Part 6: Troubleshooting

### Common Errors

**Type Mismatch**
```kcl
# Error: expected int, got str
# count: int = "5"

# Fix: Use correct type
count: int = 5
```

**Missing Required Field**
```kcl
schema VPC:
    name: str
    cidrBlock: str

# Error: missing required field 'cidrBlock'
# vpc = VPC {name: "my-vpc"}

# Fix: Provide all required fields
vpc = VPC {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
}
```

**Validation Failure**
```kcl
schema VPC:
    name: str
    check:
        len(name) > 0, "Name cannot be empty"

# Error: Name cannot be empty
# vpc = VPC {name: ""}

# Fix: Provide valid value
vpc = VPC {name: "my-vpc"}
```

**Models Not Generated**
```kcl
# Error: Cannot import models.io.upbound.awsm.ec2.v1beta1

# Causes:
# 1. Using old provider version (v1.x instead of v2.x)
# 2. Didn't run up dep update-cache
# 3. Didn't run up project build

# Fix:
# 1. Update upbound.yaml to use provider v2.x
# 2. Run: up dep update-cache
# 3. Run: up project build
# 4. Check: .up/kcl/models/ directory exists and contains models
```

### Debugging and Testing

#### Print Statements

```kcl
# Debug output
config = {name: "my-vpc", cidr: "10.0.0.0/16"}
print("Config:", config)

# Print with formatting
azs = ["us-east-1a", "us-east-1b"]
print("Creating subnets in AZs: ${azs}")
```

#### Assertions

```kcl
schema VPC:
    name: str
    cidrBlock: str

    # Assertions for debugging
    assert len(name) > 0, "Name must not be empty"
    assert cidrBlock, "CIDR block is required"
```

#### Type Checking

KCL provides strong type checking at compile time:

```kcl
schema VPC:
    name: str
    cidrBlock: str
    maxAzCount: int

# This will error - type mismatch
# vpc = VPC {
#     name: "my-vpc"
#     cidrBlock: "10.0.0.0/16"
#     maxAzCount: "three"  # Error: expected int, got str
# }
```

### Testing Resources

**See [TESTING_REFERENCE.md](TESTING_REFERENCE.md) for complete testing workflow and [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md) for command reference.**

---

## Part 7: Quick Reference

### Basic Syntax

```kcl
# Basic types
name: str = "value"
count: int = 5
enabled: bool = True
optional?: str

# Collections
list: [str] = ["a", "b", "c"]
dict: {str: str} = {key: "value"}

# Schema
schema MyType:
    field: str
    optional?: int = 10
    check:
        len(field) > 0

# Functions
lambda myFunc(param: str) -> str {
    "result-${param}"
}

# Conditionals
if condition:
    value: "yes"
else:
    value: "no"

# List comprehension
items = [x * 2 for x in range(5)]

# Imports
import module
from module import Item
```

### Resource Pattern

```kcl
# Untyped (fallback only)
{
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "VPC"
    metadata = _metadata("vpc") | {
        name = "my-vpc"
    }
    spec.forProvider = {
        cidrBlock = "10.0.0.0/16"
        region = "us-west-2"
    }
}

# Typed (PREFERRED)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

ec2v1beta1.VPC{
    metadata = _metadata("vpc") | {
        name = "my-vpc"
    }
    spec.forProvider = {
        cidrBlock = "10.0.0.0/16"
        region = "us-west-2"
    }
}
```

### Metadata Helper

```kcl
_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}
```

### Platform Commands

**See [UPBOUND_REFERENCE.md → Quick Reference](UPBOUND_REFERENCE.md#quick-reference) for all `up` CLI commands.**

### Finding Provider Information

Use the [Upbound Marketplace](https://marketplace.upbound.io/) to find:
- Provider package names
- API groups
- Available resources
- Resource schemas

Example for AWS EC2 resources:
- Provider: `xpkg.upbound.io/upbound/provider-aws-ec2`
- API Group: `ec2.aws.upbound.io`
- Version: `v1beta1`

---

## Part 8: Testing Patterns

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

## Resources and Documentation

- **Official Documentation**: https://kcl-lang.io/docs
- **GitHub Repository**: https://github.com/KusionStack/KCLVM
- **Crossplane Integration**: https://docs.crossplane.io/latest/concepts/composition-functions/
- **Upbound Functions**: https://docs.upbound.io/functions/
- **KCL Playground**: https://kcl-lang.io/docs/user_docs/getting-started/playground
- **Upbound Documentation**: https://docs.upbound.io/
- **Upbound Marketplace**: https://marketplace.upbound.io/

---

**Note**: This reference guide consolidates information from multiple sources. KCL is actively developed - check the official documentation for the latest features and best practices.
