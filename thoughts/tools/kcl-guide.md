# KCL (KusionStack Configuration Language) Guide

A comprehensive guide for using KCL to build Upbound composition functions and Crossplane configurations.

## Overview

**KCL (KusionStack Configuration Language)** is a purpose-built configuration and policy language developed by KusionStack. It's specifically designed for:

- Cloud infrastructure configuration
- Crossplane composition functions
- Policy as code
- Configuration composition and validation

### Why KCL for Upbound/Crossplane?

- **Type Safety**: Strong static typing prevents configuration errors
- **Validation**: Built-in schema validation ensures correctness
- **Composition**: Native support for merging and composing configurations
- **Readability**: Clean, Python-like syntax
- **Integration**: First-class support in Upbound composition functions

## Language Fundamentals

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

## Schema Definitions

Schemas are KCL's way of defining types and structures:

### Basic Schema

```kcl
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
        # CIDR validation (simplified)
        cidrBlock.endswith("/16") or cidrBlock.endswith("/20"), \
            "CIDR must be /16 or /20"
```

### Schema Inheritance

```kcl
schema Resource:
    """Base resource schema"""
    name: str
    tags?: {str: str}

schema NetworkResource(Resource):
    """Network resource extends Resource"""
    cidrBlock: str
    region: str

schema VPC(NetworkResource):
    """VPC extends NetworkResource"""
    enableDnsHostnames?: bool = True
    enableDnsSupport?: bool = True

# VPC now has: name, tags, cidrBlock, region, enableDnsHostnames, enableDnsSupport
```

### Mixins

```kcl
schema TagMixin:
    """Mixin for tagging"""
    tags?: {str: str}

    mixin [tags_with_name]:
        tags: {str: str} = {
            Name: self.name
            **(self.tags or {})
        }

schema VPC(TagMixin):
    name: str
    cidrBlock: str

    # Apply mixin
    mixin [tags_with_name]

vpc = VPC {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
    tags: {
        Environment: "prod"
    }
}
# vpc.tags will be {Name: "my-vpc", Environment: "prod"}
```

## Configuration Composition

### Override and Merge

KCL has powerful composition operators:

```kcl
# Base configuration
base_vpc = {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
    enableDnsHostnames: True
}

# Override specific fields (: operator)
prod_vpc = base_vpc | {
    name: "prod-vpc"
    tags: {Environment: "production"}
}

# Merge configurations (+ operator for dicts)
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

## Functions

### Built-in Functions

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

### User-Defined Functions

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

## Working with Crossplane Resources

### Generating Managed Resources

```kcl
# Import Crossplane resource definitions
import crossplane.v1 as cp

schema VPCConfig:
    name: str
    cidrBlock: str
    region: str
    tags?: {str: str}

lambda generateVPC(config: VPCConfig) -> {str:} {
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        metadata: {
            name: config.name
            labels: config.tags or {}
        }
        spec: {
            forProvider: {
                cidrBlock: config.cidrBlock
                region: config.region
                enableDnsHostnames: True
                enableDnsSupport: True
                tags: config.tags or {}
            }
        }
    }
}

# Generate VPC resource
vpc_resource = generateVPC(VPCConfig {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
    region: "us-east-1"
    tags: {
        Environment: "production"
    }
})
```

### Composition Function Pattern

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

## Common Patterns for Infrastructure

### Pattern 1: Parameterized Resource Generation

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

### Pattern 2: Resource References

```kcl
# Reference VPC in subnet
subnet = {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "Subnet"
    spec.forProvider: {
        cidrBlock: "10.0.1.0/24"

        # Reference by selector
        vpcIdSelector.matchControllerRef: True

        # Or reference by name
        # vpcIdRef.name: "my-vpc"
    }
}

# Cross-resource references
route_table_association = {
    apiVersion: "ec2.aws.upbound.io/v1beta1"
    kind: "RouteTableAssociation"
    spec.forProvider: {
        routeTableIdSelector.matchLabels: {
            type: "public"
        }
        subnetIdSelector.matchLabels: {
            name: "public-subnet-1"
        }
    }
}
```

### Pattern 3: Conditional Resource Creation

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

### Pattern 4: Tag Management

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

## Debugging and Testing

### Print Statements

```kcl
# Debug output
config = {name: "my-vpc", cidr: "10.0.0.0/16"}
print("Config:", config)

# Print with formatting
azs = ["us-east-1a", "us-east-1b"]
print("Creating subnets in AZs: ${azs}")
```

### Assertions

```kcl
schema VPC:
    name: str
    cidrBlock: str

    # Assertions for debugging
    assert len(name) > 0, "Name must not be empty"
    assert cidrBlock, "CIDR block is required"
```

### Type Checking

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

## File Organization

### Project Structure

```
project/
├── kcl.mod                 # Module metadata
├── main.kcl               # Entry point
├── schemas/
│   ├── vpc.kcl            # VPC schema definitions
│   ├── subnet.kcl         # Subnet schemas
│   └── common.kcl         # Common schemas
├── functions/
│   ├── generators.kcl     # Resource generator functions
│   └── helpers.kcl        # Helper functions
├── config/
│   ├── defaults.kcl       # Default configurations
│   └── validation.kcl     # Validation rules
└── examples/
    ├── simple-vpc.kcl     # Example configurations
    └── complex-vpc.kcl
```

### Imports

```kcl
# Import from local files
import schemas.vpc
import functions.generators as gen

# Import specific items
from schemas.vpc import VPC, VPCConfig

# Use imported items
vpc = VPC {
    name: "my-vpc"
    cidrBlock: "10.0.0.0/16"
}

resources = gen.generateVPC(vpc)
```

## Best Practices

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

## Troubleshooting

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

## Resources and Documentation

- **Official Documentation**: https://kcl-lang.io/docs
- **GitHub Repository**: https://github.com/KusionStack/KCLVM
- **Crossplane Integration**: https://docs.crossplane.io/latest/concepts/composition-functions/
- **Upbound Functions**: https://docs.upbound.io/functions/
- **KCL Playground**: https://kcl-lang.io/docs/user_docs/getting-started/playground

## Quick Reference

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

---

**Note**: KCL is actively developed. Check the official documentation for the latest features and best practices.
