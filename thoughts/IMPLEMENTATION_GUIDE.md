# Implementation Guide: Modular & Scalable VPC Configuration

## Overview

This guide defines how to implement the AWS VPC configuration specification using Upbound and KCL. It provides architectural principles, development workflows, testing strategies, and code quality standards.

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

Every module MUST be testable independently:

```
tests/
├── test-vpc-basic/              # VPC creation
├── test-subnets-public/         # Public subnets
├── test-subnets-private/        # Private subnets
├── test-subnets-database/       # Database subnets
├── test-subnets-elasticache/    # Elasticache subnets
├── test-subnets-redshift/       # Redshift subnets
├── test-subnets-intra/          # Intra subnets
├── test-igw/                    # Internet Gateway
├── test-nat-single/             # Single NAT Gateway
├── test-nat-per-az/             # NAT per AZ
├── test-nat-disabled/           # No NAT
├── test-routes-public/          # Public routing
├── test-routes-private/         # Private routing
├── test-routes-isolated/        # Isolated routing
├── test-endpoints-gateway/      # Gateway endpoints
├── test-endpoints-interface/    # Interface endpoints
├── test-nacl/                   # Network ACLs
├── test-dhcp/                   # DHCP options
├── test-flowlogs-cloudwatch/    # Flow logs to CloudWatch
├── test-flowlogs-s3/            # Flow logs to S3
└── e2etest-complete/            # Full E2E test
```

### 4. Scalability

Design for growth:

- **Composable**: Each module can be used independently
- **Extensible**: New features added without breaking existing code
- **Performant**: Resources created in parallel where possible
- **Maintainable**: Clear boundaries, minimal coupling

## Project Structure

### File Organization
```
project-root/
├── upbound.yaml              # Project manifest
├── apis/                     # XRD (Composite Resource Definition) files
│   └── xvpc/
│       └── definition.yaml
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

### Module Responsibilities

**main.k** - Entry point and orchestration:
- Access composition parameters (oxr, ocds, dxr, dcds)
- Extract typed metadata and spec
- Coordinate module calls
- Combine all resources into items list

**vpc.k** - VPC resource generation:
- VPC creation with CIDR
- DNS settings (hostnames, support)
- Secondary CIDR blocks

**subnet.k** - Subnet generation:
- Public subnets (with auto-assign public IP)
- Private subnets
- Database subnets
- Elasticache subnets
- Redshift subnets
- Intra subnets (isolated)

**gateway.k** - Gateway resources:
- Internet Gateway creation
- NAT Gateway creation (single or per-AZ)
- EIP allocation for NAT
- VPN Gateway (optional)

**route.k** - Routing configuration:
- Route table creation (per subnet type)
- Route creation (IGW, NAT, custom)
- Route table associations

**endpoints.k** - VPC endpoints:
- Gateway endpoints (S3, DynamoDB)
- Interface endpoints
- Endpoint policies

**nacl.k** - Network ACL rules:
- Custom inbound rules
- Custom outbound rules

**dhcp.k** - DHCP options:
- Custom DNS servers
- Custom domain name
- NTP servers

**flowlogs.k** - VPC Flow Logs:
- CloudWatch destination
- S3 destination
- Traffic type configuration

**utils/** - Shared utilities:
- Metadata helpers (resource naming)
- Tag merging logic
- CIDR calculation
- Input validation

## Development Workflow

This project follows **strict Test-Driven Development (TDD)**:

🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

> 📖 **Complete TDD Workflow**: See [TDD_STRATEGY.md](TDD_STRATEGY.md) for the detailed step-by-step process

> 📖 **Git & Commits**: See [GIT_WORKFLOW.md](GIT_WORKFLOW.md) for commit conventions and workflow details

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
```

### Testing Coverage

Every module has test:

```
functions/vpc/subnet.k → tests/test-xvpc-subnets-*/main.k
functions/vpc/gateway.k → tests/test-xvpc-gateways/main.k
functions/vpc/route.k → tests/test-xvpc-routes-*/main.k
```

### Success Metrics

#### Code Quality
- ✅ All modules < 300 lines
- ✅ 100% of functions documented
- ✅ No code duplication
- ✅ Clear separation of concerns

#### Test Coverage
- ✅ 100% feature coverage (composition tests)
- ✅ All critical paths (E2E tests - MANDATORY)
- ✅ All tests pass before commit
- ✅ No flaky tests

#### Feature Parity
- ✅ All Terraform inputs supported
- ✅ All Terraform outputs provided
- ✅ Behavior matches Terraform module
- ✅ Side-by-side validation passes

## Maintenance

### Adding New Features

1. Check Terraform module for feature
2. Write composition test FIRST
3. Update XRD if needed
4. Implement in appropriate module
5. Write E2E test (MANDATORY for major features)
6. Update examples
7. Update documentation
8. Commit when ALL tests pass

### Refactoring

1. Ensure tests exist and pass
2. Refactor code
3. Ensure tests still pass
4. Commit

### Bug Fixes

1. Write failing test that reproduces bug
2. Fix bug
3. Ensure test passes
4. Ensure ALL tests still pass
5. Commit

## References

- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Upbound Platform Ref](https://github.com/upbound/platform-ref-upbound)
- [Crossplane Composition Functions](https://docs.crossplane.io/latest/concepts/composition-functions/)
- [KCL Language Documentation](https://kcl-lang.io/docs)
- [SPECIFICATION.md](SPECIFICATION.md) - What to build
- [KCL_REFERENCE.md](KCL_REFERENCE.md) - KCL language reference and patterns
