# Upbound Coding Patterns and Standards

This document outlines coding patterns and best practices observed in the [platform-ref-upbound](https://github.com/upbound/platform-ref-upbound) project, specifically focusing on how to structure composition functions using KCL.

## Project Structure Overview

The platform-ref-upbound project demonstrates a well-organized structure for building Upbound configurations with composition functions:

```
project-root/
├── upbound.yaml              # Project manifest
├── apis/                     # XRD (Composite Resource Definition) files
├── examples/                 # Example XR/Claim files for testing
├── functions/                # Composition functions (KCL)
│   ├── function-1/
│   │   ├── main.k           # Entry point for composition logic
│   │   ├── kcl.mod          # Module metadata and dependencies
│   │   ├── kcl.mod.lock     # Locked dependencies
│   │   └── utils/           # Utility functions
│   │       └── *.k          # Helper modules
│   ├── function-2/
│   │   └── ...
│   └── function-3/
│       └── ...
└── tests/                    # Test configurations
```

## Composition Function Structure

### 1. Entry Point Pattern (main.k)

Every composition function starts with a standard structure in `main.k`:

```kcl
"""
Module docstring explaining:
- What this composition does
- Key resources it creates
- Integration points with other systems
"""

# Import XRD models
import models.io.upbound.sa.v1 as sav1
import models.io.crossplane.kubernetes.v1alpha2 as kubernetesv1alpha2

# System modules
import base64
import yaml
import regex

# Local modules
import utils
import submodule1
import submodule2

# Access composition function parameters
oxr = option("params").oxr      # observed composite resource
ocds = option("params").ocds    # observed composed resources
dxr = option("params").dxr      # desired composite resource
dcds = option("params").dcds    # desired composed resources

# Extract typed metadata and spec
oxrMeta = sav1.XMyResource.metadata{**oxr.metadata}
oxrSpec = sav1.XMyResource.spec{**oxr.spec}

# Main composition logic
items = [
    # Resource definitions here
]
```

### Key Concepts:

**Composition Parameters:**
- `oxr` (observed XR): The current state of the composite resource
- `ocds` (observed composed): Currently existing managed resources
- `dxr` (desired XR): The desired state of the composite resource
- `dcds` (desired composed): The desired managed resources to create/update

**Type Safety:**
Import XRD models and use them to ensure type-safe access to spec/metadata.

### 2. Module Organization Pattern

Split complex logic into focused modules:

```
function-name/
├── main.k                    # Entry point, orchestration
├── kcl.mod                   # Dependencies
├── resourceType1.k           # VPC-specific logic
├── resourceType2.k           # Subnet-specific logic
├── resourceType3.k           # Gateway-specific logic
└── utils/
    ├── metadata.k            # Metadata helpers
    └── helpers.k             # Common utilities
```

**Example: utils/metadata.k**
```kcl
_metadata = lambda name: str -> any {
    """
    Creates metadata with a standardized composition resource name.

    Args:
        name: The name to include in the annotations

    Returns:
        A metadata object with annotations for composition resource naming
    """
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}
```

**Usage in main.k:**
```kcl
import utils

items = [
    kubernetesv1alpha2.Object{
        metadata = utils._metadata("my-vpc") | {
            name = "vpc-${oxrMeta.name}"
        }
        spec = { /* ... */ }
    }
]
```

### 3. Resource Naming Convention

Use the metadata pattern for consistent resource tracking:

```kcl
kubernetesv1alpha2.Object{
    metadata = utils._metadata("vpc") | {
        name = "vpc-${oxrMeta.name}"
    }
    # ...
}
```

The annotation `"krm.kcl.dev/composition-resource-name"` uniquely identifies resources in the composition.

### 4. Conditional Resource Creation

Use conditional expressions for optional resources:

```kcl
items = [
    # Always create VPC
    kubernetesv1alpha2.Object{
        metadata = utils._metadata("vpc") | {name = "my-vpc"}
        # ...
    }

    # Conditionally create NAT gateway
    if oxrSpec.parameters.enableNatGateway:
        kubernetesv1alpha2.Object{
            metadata = utils._metadata("nat-gateway") | {name = "my-nat"}
            # ...
        }

    # Conditionally create multiple subnets
    *[
        kubernetesv1alpha2.Object{
            metadata = utils._metadata("subnet-${i}") | {
                name = "subnet-${i}"
            }
            # ...
        }
        for i, az in enumerate(oxrSpec.parameters.availabilityZones)
    ] if oxrSpec.parameters.createSubnets else []
]
```

### 5. Status-Based Initialization Pattern

For resources that depend on observed state:

```kcl
# Check if initialization is complete
_statusReady = oxr.status?.initialization != Undefined and \
    oxr.status.initialization.completed == True

_initItems = [
    # Resources needed for initialization
    sav1.XMyResource{
        status = {
            initialization = {
                completed = True
                timestamp = "..."
            }
        }
    }
]

_mainItems = []

if _statusReady:
    # Only create main resources after initialization
    _mainItems = [
        # Main resources here
    ]

# Return combined items
items = _initItems + _mainItems
```

This pattern ensures resources are created in the correct order and prevents partial states.

### 6. Observing Existing Resources

To read existing resources (e.g., secrets):

```kcl
_initItems = [
    kubernetesv1alpha2.Object{
        metadata = utils._metadata("observed-secret") | {
            name = "observed-secret"
        }
        spec = {
            forProvider = {
                manifest = {
                    apiVersion = "v1"
                    kind = "Secret"
                    metadata = {
                        name = oxrSpec.parameters.secretRef.name
                        namespace = oxrSpec.parameters.secretRef.namespace
                    }
                }
            }
            providerConfigRef = {
                name = oxrSpec.parameters.providerConfigName
            }
            managementPolicies = ["Observe"]  # Key: Only observe, don't manage
        }
    }
]

# Later, access the observed data
_secretData = base64.decode(
    ocds["observed-secret"]?.Resource?.status?.atProvider?.manifest?.data?.token
)
```

### 7. Cross-Resource References

**By Selector (Recommended):**
```kcl
spec = {
    forProvider = {
        # Reference VPC by labels
        vpcIdSelector = {
            matchControllerRef = True  # References parent composite
        }
        # Or match specific labels
        vpcIdSelector = {
            matchLabels = {
                type = "production"
                environment = "prod"
            }
        }
    }
}
```

**By Name:**
```kcl
spec = {
    forProvider = {
        vpcIdRef = {
            name = "my-vpc"
        }
    }
}
```

**Selector Pattern is Preferred** because it's more dynamic and resilient to naming changes.

### 8. Modular Functions Pattern

Break logic into reusable functions:

```kcl
# In vpc.k
schema VPCInput:
    name: str
    cidrBlock: str
    region: str
    tags?: {str: str}

lambda generateVPC(input: VPCInput) -> [any] {
    """
    Generates VPC managed resource.

    Args:
        input: VPC configuration parameters

    Returns:
        List of managed resources for VPC
    """
    [
        kubernetesv1alpha2.Object{
            metadata = utils._metadata("vpc") | {
                name = input.name
            }
            spec = {
                forProvider = {
                    manifest = {
                        apiVersion = "ec2.aws.upbound.io/v1beta1"
                        kind = "VPC"
                        metadata = {
                            name = input.name
                            labels = input.tags or {}
                        }
                        spec = {
                            forProvider = {
                                cidrBlock = input.cidrBlock
                                region = input.region
                                enableDnsHostnames = True
                                enableDnsSupport = True
                            }
                        }
                    }
                }
            }
        }
    ]
}
```

**Usage in main.k:**
```kcl
import vpc

items = vpc.generateVPC(vpc.VPCInput{
    name = oxrMeta.name
    cidrBlock = oxrSpec.parameters.cidrBlock
    region = oxrSpec.parameters.region
    tags = oxrSpec.parameters.tags
})
```

### 9. Configuration Merging Pattern

Use KCL's merge operator `|` for layering configurations:

```kcl
# Base configuration
base = {
    apiVersion = "ec2.aws.upbound.io/v1beta1"
    kind = "VPC"
    metadata = {
        name = "my-vpc"
    }
}

# Environment-specific overrides
prod_config = {
    metadata = {
        labels = {
            environment = "production"
        }
    }
    spec = {
        forProvider = {
            enableFlowLogs = True
        }
    }
}

# Merge configurations
final = base | prod_config
```

### 10. List Spreading Pattern

Combine multiple resource lists:

```kcl
_vpcItems = generateVPC(...)
_subnetItems = generateSubnets(...)
_routeItems = generateRoutes(...)

# Spread all lists into a single items list
items = [
    *_vpcItems,
    *_subnetItems,
    *_routeItems
]
```

### 11. Delegation to Child Compositions

For complex resources, delegate to specialized XRs:

```kcl
items = [
    # Delegate subnet management to specialized composition
    sav1.XSubnetSet{
        metadata = utils._metadata("subnet-set") | {
            name = "${oxrMeta.name}-subnets"
        }
        spec = {
            parameters = {
                vpcName = oxrMeta.name
                subnets = oxrSpec.parameters.subnets
                availabilityZones = oxrSpec.parameters.availabilityZones
            }
        }
    }
]
```

This pattern keeps compositions focused and maintainable.

### 12. Tag Management Pattern

Consistent tagging across resources:

```kcl
lambda mergeTags(
    commonTags: {str: str},
    resourceTags: {str: str},
    resourceName: str
) -> {str: str} {
    """
    Merges common tags with resource-specific tags.
    Adds Name tag automatically.
    """
    {
        Name = resourceName
        **commonTags      # Spread common tags
        **resourceTags    # Spread resource tags (overrides common)
    }
}

# Usage
vpc_tags = mergeTags(
    oxrSpec.parameters.commonTags or {},
    oxrSpec.parameters.vpcTags or {},
    "my-vpc"
)
```

### 13. Provider Configuration Pattern

Separate provider configs by scope:

```kcl
# Space-level provider config
lambda spaceProviderConfig(org: str, space: str) -> any {
    kubernetesv1alpha2.ProviderConfig{
        metadata = {
            name = "${space}-provider"
        }
        spec = {
            credentials = {
                source = "Upbound"
                upbound = {
                    organization = org
                    space = space
                }
            }
        }
    }
}

# Control plane-level provider config
lambda ctpProviderConfig(org: str, group: str, ctp: str) -> any {
    kubernetesv1alpha2.ProviderConfig{
        metadata = {
            name = "${ctp}-provider"
        }
        spec = {
            credentials = {
                source = "Upbound"
                upbound = {
                    organization = org
                    group = group
                    controlPlane = ctp
                }
            }
        }
    }
}
```

## kcl.mod Structure

The `kcl.mod` file defines module metadata and dependencies:

```toml
[package]
name = "compose-vpc"
version = "0.1.0"

[dependencies]
# Local model dependencies (generated from XRDs)
models = { path = "./model" }

# External KCL modules from OCI registries
spaces = {
    oci = "oci://xpkg.upbound.io/upbound/kcl-modules_spaces",
    tag = "1.12.0",
    package = "kcl-modules_spaces",
    version = "1.12.0"
}
```

## Best Practices Summary

### Organization
1. **One function per directory** with `main.k` as entry point
2. **Split complex logic** into focused modules (vpc.k, subnet.k, etc.)
3. **Use utils/** directory for shared helpers
4. **Document modules** with comprehensive docstrings

### Code Structure
1. **Import dependencies** at top (models, system, local)
2. **Access parameters** via `option("params")`
3. **Extract typed objects** from oxr/ocds early
4. **Validate readiness** before creating resources
5. **Return items list** at the end

### Resource Management
1. **Use metadata pattern** for resource naming (`utils._metadata()`)
2. **Prefer selectors** over hardcoded references
3. **Implement conditional creation** with if expressions
4. **Use status fields** for cross-reconciliation data
5. **Set managementPolicies** appropriately (["Observe"] for read-only)

### Code Quality
1. **Define schemas** for input/output types
2. **Write reusable functions** with clear signatures
3. **Use descriptive names** for variables and resources
4. **Add docstrings** to all functions and modules
5. **Keep functions focused** on single responsibility

### Testing
1. **Create example claims** in examples/ directory
2. **Write test configurations** in tests/ directory
3. **Use `up project run`** for local testing
4. **Validate outputs** match expectations

## Advanced Patterns

### Pattern: Multi-Stage Initialization

```kcl
# Stage 1: Bootstrap (always runs)
_stage1_ready = True
_stage1_items = [/* bootstrap resources */]

# Stage 2: Core (requires bootstrap data)
_stage2_ready = oxr.status?.bootstrap?.completed == True
_stage2_items = [/* core resources */] if _stage2_ready else []

# Stage 3: Optional features (requires core)
_stage3_ready = _stage2_ready and oxr.status?.core?.ready == True
_stage3_items = [/* optional resources */] if _stage3_ready else []

items = _stage1_items + _stage2_items + _stage3_items
```

### Pattern: Dynamic Resource Generation

```kcl
# Generate resources based on input list
schema SubnetSpec:
    name: str
    cidrBlock: str
    availabilityZone: str
    type: str  # "public" or "private"

lambda generateSubnets(specs: [SubnetSpec]) -> [any] {
    [
        kubernetesv1alpha2.Object{
            metadata = utils._metadata("subnet-${spec.name}") | {
                name = spec.name
            }
            spec = {
                forProvider = {
                    manifest = {
                        apiVersion = "ec2.aws.upbound.io/v1beta1"
                        kind = "Subnet"
                        spec = {
                            forProvider = {
                                cidrBlock = spec.cidrBlock
                                availabilityZone = spec.availabilityZone
                                mapPublicIpOnLaunch = spec.type == "public"
                                vpcIdSelector.matchControllerRef = True
                            }
                        }
                    }
                }
            }
        }
        for spec in specs
    ]
}
```

### Pattern: Error Handling and Validation

```kcl
schema VPCParams:
    cidrBlock: str
    name: str

    # Validation rules
    check:
        len(name) > 0, "Name cannot be empty"
        len(name) <= 63, "Name too long (max 63 characters)"
        regex.match(cidrBlock, r"^\d+\.\d+\.\d+\.\d+/\d+$"), \
            "Invalid CIDR format"

# Usage validates automatically
params = VPCParams{
    name = oxrSpec.parameters.name
    cidrBlock = oxrSpec.parameters.cidrBlock
}
```

## Common Gotchas

### 1. Undefined vs None
```kcl
# Undefined means not set at all
value = oxrSpec.parameters?.optionalField  # May be Undefined

# Check for Undefined before using
if value != Undefined:
    # Use value
```

### 2. Base64 Decoding Secrets
```kcl
# Secrets are base64-encoded in Kubernetes
import base64

secret_value = base64.decode(
    ocds["my-secret"]?.Resource?.status?.atProvider?.manifest?.data?.key
)
```

### 3. Resource Dependencies
```kcl
# Resources are created in parallel unless dependencies exist
# Use status checks for ordering:

_vpc_ready = ocds["vpc"]?.Resource?.status?.atProvider?.id != Undefined

_subnet_items = [
    # Subnets only created when VPC is ready
    # ...
] if _vpc_ready else []
```

### 4. List Comprehension in Items
```kcl
# Spread operator required to flatten list comprehensions
items = [
    # Single resource
    my_vpc_resource,

    # Multiple resources from comprehension (need *)
    *[subnet_resource for subnet in subnets]
]
```

## File Organization Example

For a VPC module:

```
functions/vpc/
├── main.k                  # Orchestration and oxr/ocds handling
├── kcl.mod                 # Dependencies
├── kcl.mod.lock           # Locked versions
├── vpc.k                   # VPC resource generation
├── subnet.k                # Subnet logic
├── gateway.k               # IGW/NAT gateway logic
├── route.k                 # Route table logic
├── utils/
│   ├── metadata.k          # Resource naming
│   ├── cidr.k             # CIDR calculations
│   └── tags.k             # Tag management
└── README.md              # Function documentation
```

## Testing Strategy

1. **Unit-level**: Test individual functions in isolation
2. **Integration**: Test full composition with example claims
3. **Simulation**: Use `up project simulate` against real control plane
4. **End-to-end**: Deploy to development environment

## Resources

- [KCL Language Documentation](https://kcl-lang.io/docs)
- [Crossplane Composition Functions](https://docs.crossplane.io/latest/concepts/composition-functions/)
- [Upbound Functions](https://docs.upbound.io/functions/)
- [Platform Ref Upbound](https://github.com/upbound/platform-ref-upbound)

---

**Summary**: Follow these patterns to create maintainable, testable, and idiomatic Upbound composition functions using KCL. Prioritize readability, type safety, and modularity.
