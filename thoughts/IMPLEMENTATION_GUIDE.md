# Implementation Guide: Modular & Scalable VPC Configuration


## Related Documentation

For related topics, see:
- **TDD Workflow**: [TDD_STRATEGY.md](TDD_STRATEGY.md)
- **Testing Patterns**: [TESTING_REFERENCE.md](TESTING_REFERENCE.md)
- **KCL Language**: [KCL_REFERENCE.md](KCL_REFERENCE.md)
- **Feature Specification**: [SPECIFICATION.md](SPECIFICATION.md)

---

## Overview

This guide defines **HOW to implement** the AWS VPC configuration using Upbound and KCL. It provides architectural principles, development workflows, testing strategies, and code quality standards.

**For WHAT to build** (features, requirements, AWS resources), see [SPECIFICATION.md](SPECIFICATION.md).

## Architectural Principles

### 1. Modularity First

Code MUST be organized into discrete, reusable modules:

```
functions/vpc/
├── main.k              # Entry point - orchestration only
├── kcl.mod             # Dependencies
├── vpc.k               # VPC resource generation
├── subnet.k            # Subnet logic (all types)
├── gateway.k           # IGW, NAT, VPN gateways
├── route.k             # Route tables and routes
├── endpoints.k         # VPC endpoints
├── nacl.k              # Network ACLs
├── dhcp.k              # DHCP options
├── flowlogs.k          # VPC Flow Logs
└── utils/
    ├── metadata.k      # Metadata helpers
    ├── tags.k          # Tag merging logic
    ├── cidr.k          # CIDR calculation helpers
    └── validation.k    # Input validation
```

### 2. Separation of Concerns

Each module has a **single responsibility**:

- **vpc.k**: VPC creation, DNS settings, secondary CIDRs
- **subnet.k**: All subnet types (public, private, database, elasticache, redshift, intra)
- **gateway.k**: All gateway types (IGW, NAT, VPN)
- **route.k**: Route table creation, route creation, route table associations
- **endpoints.k**: Gateway and interface VPC endpoints
- **nacl.k**: Network ACL rules
- **dhcp.k**: DHCP options sets
- **flowlogs.k**: VPC Flow Logs configuration
- **utils/**: Reusable helper functions

### 3. Testability

Every module MUST be testable independently.

### 4. Scalability

Design for growth:

- **Composable**: Each module can be used independently
- **Extensible**: New features added without breaking existing code
- **Performant**: Resources created in parallel where possible
- **Maintainable**: Clear boundaries, minimal coupling

## Implementation Patterns

### 1. Conditional Resource Creation
- Resources created based on feature flags (enable_nat_gateway, create_igw, etc.)
- Subnet types only created when CIDR blocks provided
- Example: `_igw = [InternetGateway{...}] if oxrSpec.createIgw else []`

### 2. Looping and Distribution
- Subnets created for each AZ using list comprehensions
- NAT gateways created per AZ based on strategy
- Route tables created per subnet type
- Example: `[Subnet{...} for i, cidr in enumerate(publicSubnets)]`

### 3. Dependencies and Relationships
- Use selectors, not hardcoded references: `vpcIdSelector.matchControllerRef`
- Subnets depend on VPC via label matching
- Route tables depend on gateways
- Routes depend on route tables
- Subnet associations depend on route tables

### 4. Dynamic Routing
- Public subnets route to IGW (0.0.0.0/0 → IGW)
- Private subnets route to NAT gateway (0.0.0.0/0 → NAT)
- Specialized subnets have isolated routing (local VPC only)
- Route table associations link subnets to tables

### 5. Naming Conventions
- Resources named with pattern: `${name}-{type}-{az}`
- Example: `my-vpc-public-us-west-2a`
- Consistent naming across regions/accounts
- Metadata helpers ensure consistency

### 6. Default Values and Validation
- Sensible defaults for optional parameters
- Validate inputs early (AZ count, CIDR format)
- Document assumptions clearly
- Example: `assert len(azs) >= len(publicSubnets)`

### 7. Tagging Strategy
- Common tags merged with resource-specific tags
- Type-specific tags for resource categorization (subnet-type: "public")
- Name tags automatically generated
- Tag merging utilities in `utils/tags.k`

### 5. Architecture Decisions

**CRITICAL**: This project uses Crossplane v2 with **namespaced claims**. Use `kind: VPC` (NOT `XVPC`) for all claims.

**For complete architectural decisions and rationale, see [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)**

## Composition Pipeline Requirements

**CRITICAL**: All compositions MUST include `function-auto-ready` as the last pipeline step.

**See [KCL_REFERENCE.md → Generating Functions](KCL_REFERENCE.md#generating-functions) for complete details and troubleshooting.**

Without this, XRs never reach Ready status and E2E tests timeout.

## Project Structure

### File Organization
```
project-root/
├── upbound.yaml              # Project manifest
├── apis/                     # XRD (Composite Resource Definition) files
│   └── xvpc/
│       ├── definition.yaml
│       └── composition.yaml  # MUST include function-auto-ready
├── examples/                 # Example XR/Claim files for testing
│   ├── simple-vpc.yaml
│   ├── multi-az-vpc.yaml
│   └── complete-vpc.yaml
├── functions/                # Composition functions (KCL)
│   └── vpc/
│       ├── main.k           # Entry point
│       ├── kcl.mod          # Dependencies
│       ├── vpc.k            # VPC module
│       ├── subnet.k         # Subnet module
│       ├── gateway.k        # Gateway module
│       ├── route.k          # Route module
│       └── utils/           # Utilities
└── tests/                   # Test configurations
    ├── test-vpc-basic/
    └── e2etest-complete/
```

**AWS Resources**: See [SPECIFICATION.md → AWS Resources Created](SPECIFICATION.md#aws-resources-created) for complete list of managed resources.

## Development Workflow

This project follows **strict Test-Driven Development (TDD)**. See [TDD_STRATEGY.md](TDD_STRATEGY.md) for complete workflow.

## Dependencies and Performance

### Resource Dependencies

Use `vpcIdSelector`, not hardcoded references:

```kcl
# ✅ CORRECT: Use selector
ec2v1beta1.Subnet{
    spec.forProvider.vpcIdSelector = {
        matchControllerRef: True
    }
}

# ❌ WRONG: Hardcoded reference
ec2v1beta1.Subnet{
    spec.forProvider.vpcId = "vpc-123456"  # Never do this
}
```

### Module Dependencies

Clear dependency chain:

```
vpc.k (no dependencies)
  ↓
subnet.k (depends on VPC)
  ↓
gateway.k (depends on VPC, subnets)
  ↓
route.k (depends on gateway, subnets)
  ↓
endpoints.k (depends on VPC, subnets)
```

### Parallel Resource Creation

Crossplane creates resources in parallel when possible:

```kcl
# All subnets created in parallel (no dependencies between them)
items = _generatePublicSubnets(oxrSpec) + \
        _generatePrivateSubnets(oxrSpec)

# NAT Gateways created in parallel
items = items + _generateNATGateways(oxrSpec)
```

### Conditional Creation

Only create resources when needed:

```kcl
# Only create IGW if requested
_igw = [
    ec2v1beta1.InternetGateway{ ... }
] if oxrSpec.createIgw else []

# Only create NAT if private subnets exist
_nat = _generateNATGateways(oxrSpec) if oxrSpec.privateSubnets else []
```

## Code Quality Standards

### Documentation

Every function documented:

```kcl
"""
Generate public subnets across availability zones

Args:
    oxrSpec: XR spec containing:
        - publicSubnets: List of CIDR blocks
        - azs: List of availability zones
        - region: AWS region
        - tags: Common tags to apply

Returns:
    List[Subnet]: Subnet managed resources

Example:
    oxrSpec = {
        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
        azs: ["us-west-2a", "us-west-2b"]
        region: "us-west-2"
    }
    subnets = _generatePublicSubnets(oxrSpec)
    # Returns 2 Subnet resources
"""
```

### Error Handling

Validate inputs early:

```kcl
# Validate AZ count matches subnet count
assert len(oxrSpec.azs) >= len(oxrSpec.publicSubnets), \
    "Must have at least as many AZs as subnets"

# Validate CIDR blocks
assert all cidr in oxrSpec.publicSubnets satisfies \
    "/" in cidr, "Invalid CIDR block format"
### Testing Coverage

Every module has corresponding tests. See [TDD_STRATEGY.md](TDD_STRATEGY.md) for complete testing workflow.

**Code Quality Requirements**: See [SPECIFICATION.md → Code Quality Requirements](SPECIFICATION.md#code-quality-requirements) for quality standards and success metrics.

## References

- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Upbound Platform Ref](https://github.com/upbound/platform-ref-upbound)
- [Crossplane Composition Functions](https://docs.crossplane.io/latest/concepts/composition-functions/)
- [KCL Language Documentation](https://kcl-lang.io/docs)
- [SPECIFICATION.md](SPECIFICATION.md) - What to build
- [KCL_REFERENCE.md](KCL_REFERENCE.md) - KCL language reference and patterns
