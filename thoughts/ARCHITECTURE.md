# Architecture Guide: Modular & Scalable VPC Configuration

## Overview

This document defines the architectural principles for building a **drop-in replacement** for the terraform-aws-modules/vpc module using Upbound and KCL.

## Core Principle: Feature Parity

**CRITICAL**: This project is a drop-in replacement for the Terraform AWS VPC module. We must:
- ✅ Support **all** input variables (minor capitalization differences acceptable)
- ✅ Provide **all** output values
- ✅ Match **exact behavior** of Terraform module
- ✅ Pass validation tests comparing outputs side-by-side

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

## Module Design Pattern

Each module follows this pattern:

```kcl
"""
Module: subnet.k
Responsibility: Generate all subnet types for VPC
Inputs: XR spec (from oxrSpec)
Outputs: List of Subnet resources
"""

import models.ec2.aws.upbound.io.v1beta1 as ec2v1beta1
import utils

# Generate public subnets
_generatePublicSubnets = lambda oxrSpec: Object -> [Object] {
    """
    Generate public subnets across AZs

    Args:
        oxrSpec: XR spec containing publicSubnets, azs, region, etc.

    Returns:
        List of Subnet managed resources
    """
    [
        ec2v1beta1.Subnet{
            # ... implementation
        }
        for _, subnet in oxrSpec.publicSubnets if oxrSpec.publicSubnets
    ]
}

# Generate private subnets
_generatePrivateSubnets = lambda oxrSpec: Object -> [Object] {
    # ... implementation
}

# Public API
generateSubnets = lambda oxrSpec: Object -> [Object] {
    """
    Main entry point - generates all subnet types

    Returns all subnets: public, private, database, elasticache, redshift, intra
    """
    _generatePublicSubnets(oxrSpec) + \
    _generatePrivateSubnets(oxrSpec) + \
    _generateDatabaseSubnets(oxrSpec) + \
    _generateElasticacheSubnets(oxrSpec) + \
    _generateRedshiftSubnets(oxrSpec) + \
    _generateIntraSubnets(oxrSpec)
}
```

## Testing Strategy

### Test-Driven Development (TDD)

**MANDATORY WORKFLOW**:

1. **Write test FIRST** (before any implementation code)
2. **Run test** (it should fail - red)
3. **Write minimum code** to pass test (green)
4. **Refactor** while keeping tests passing
5. **Commit** only when all tests pass

### Test Hierarchy

#### Level 1: Composition Tests (Unit)

Fast, isolated tests validating composition logic:

```bash
# Generate test
up test generate test-xvpc-public-subnets --language=kcl

# Run test
up test run tests/test-xvpc-public-subnets
```

**Purpose**: Validate that composition generates correct managed resources

**Example**: Test that public subnets are created with `mapPublicIpOnLaunch: true`

#### Level 2: Integration Tests

Test multiple modules working together:

```bash
up test run tests/test-xvpc-routing-complete
```

**Purpose**: Validate that modules integrate correctly

**Example**: Test that subnets + route tables + routes work together

#### Level 3: E2E Tests

Real AWS resources, full lifecycle:

```bash
up test run tests/e2etest-xvpc-complete --e2e
```

**Purpose**: Validate behavior matches Terraform module in real AWS

**Example**: Create VPC in AWS, verify all resources, clean up

### Test Coverage Requirements

- **100% feature coverage**: Every feature has composition test
- **Critical path E2E**: All major scenarios have E2E tests
- **Parity validation**: Side-by-side comparison with Terraform outputs

## Commit Policy

**NEVER commit failing tests**:

```bash
# Before committing
up project build                    # Must pass
up test run tests/test-*            # All composition tests must pass
# up test run tests/e2etest-* --e2e  # E2E tests (run before major releases)

# Only commit when green
git add .
git commit -m "feat: implement public subnets"
```

## Feature Implementation Workflow

### Standard Process for ANY Feature

1. **Read Terraform module behavior**
   - Check terraform-aws-vpc module code
   - Check terraform-aws-vpc examples
   - Understand exact behavior

2. **Write composition test FIRST**
   ```bash
   up test generate test-xvpc-<feature> --language=kcl
   # Edit tests/test-xvpc-<feature>/main.k
   ```

3. **Define expected resources** in test
   - Assert exact resource structure
   - Assert all required fields
   - Assert tag merging
   - Assert conditional creation

4. **Run test (should fail)**
   ```bash
   up test run tests/test-xvpc-<feature>
   # Expected: FAIL (feature not implemented yet)
   ```

5. **Implement minimum code** to pass test
   - Edit functions/vpc/main.k or module file
   - Follow existing patterns
   - Keep it simple

6. **Run test until green**
   ```bash
   up test run tests/test-xvpc-<feature>
   # Expected: PASS
   ```

7. **Run ALL tests**
   ```bash
   up test run tests/test-*
   # Expected: ALL PASS (no regressions)
   ```

8. **Refactor** if needed
   - Improve code clarity
   - Extract to modules
   - Keep tests passing

9. **Commit**
   ```bash
   git add .
   git commit -m "feat: implement <feature>"
   ```

10. **Write E2E test** (for critical features)
    ```bash
    up test generate e2etest-xvpc-<feature> --e2e --language=kcl
    # Run locally: up test run tests/e2etest-xvpc-<feature> --e2e
    ```

### Example: Implementing NAT Gateway

```bash
# 1. Write test first
up test generate test-xvpc-nat-single --language=kcl

# Edit tests/test-xvpc-nat-single/main.k
# Assert:
# - 1 NAT Gateway created
# - 1 EIP allocated
# - NAT placed in public subnet
# - Private subnets route to NAT

# 2. Run test (fails)
up test run tests/test-xvpc-nat-single
# ❌ FAIL: No NAT Gateway resources generated

# 3. Implement in functions/vpc/gateway.k
# Add _generateNATGateways() function

# 4. Update main.k to include NAT resources
# items = vpc + subnets + igw + nat + ...

# 5. Run test (passes)
up test run tests/test-xvpc-nat-single
# ✅ PASS

# 6. Run all tests (ensure no regressions)
up test run tests/test-*
# ✅ ALL PASS

# 7. Commit
git add .
git commit -m "feat: implement single NAT Gateway strategy"
```

## Feature Parity Validation

### Input Variable Mapping

Terraform → Upbound XRD (capitalization differences acceptable):

```
terraform_input          →  xrd_field
---------------------------------------------
name                     →  metadata.name (Kubernetes standard)
cidr                     →  cidr
azs                      →  azs
public_subnets           →  publicSubnets
private_subnets          →  privateSubnets
database_subnets         →  databaseSubnets
elasticache_subnets      →  elasticacheSubnets
redshift_subnets         →  redshiftSubnets
intra_subnets            →  intraSubnets
enable_dns_hostnames     →  enableDnsHostnames
enable_dns_support       →  enableDnsSupport
single_nat_gateway       →  singleNatGateway
one_nat_gateway_per_az   →  oneNatGatewayPerAz
create_igw               →  createIgw
tags                     →  tags
public_subnet_tags       →  publicSubnetTags
private_subnet_tags      →  privateSubnetTags
# ... (complete mapping)
```

### Output Validation

Test that outputs match Terraform module:

```kcl
# In composition tests, assert status fields
assertXR: {
    status: {
        vpcId: "vpc-xxxxx"              # Must be set
        publicSubnets: ["subnet-a", "subnet-b"]  # Must match count
        igwId: "igw-xxxxx"              # When IGW created
        natGatewayIds: ["nat-xxxxx"]    # When NAT created
        # ... all outputs
    }
}
```

### Behavior Validation

E2E tests compare against Terraform:

1. Deploy with Terraform
2. Deploy with Upbound (same inputs)
3. Compare outputs
4. Validate resources match

## Dependency Management

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

## Performance Considerations

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

### Testing

Every module has test:

```
functions/vpc/subnet.k → tests/test-xvpc-subnets-*/main.k
functions/vpc/gateway.k → tests/test-xvpc-gateways/main.k
functions/vpc/route.k → tests/test-xvpc-routes-*/main.k
```

## Maintenance

### Adding New Features

1. Check Terraform module for feature
2. Write composition test
3. Update XRD if needed
4. Implement in appropriate module
5. Update examples
6. Update documentation
7. Add E2E test for critical features
8. Commit when tests pass

### Refactoring

1. Ensure tests exist and pass
2. Refactor code
3. Ensure tests still pass
4. Commit

### Bug Fixes

1. Write failing test that reproduces bug
2. Fix bug
3. Ensure test passes
4. Commit

## Success Metrics

### Code Quality
- ✅ All modules < 300 lines
- ✅ 100% of functions documented
- ✅ No code duplication
- ✅ Clear separation of concerns

### Test Coverage
- ✅ 100% feature coverage (composition tests)
- ✅ All critical paths (E2E tests)
- ✅ All tests pass before commit
- ✅ No flaky tests

### Feature Parity
- ✅ All Terraform inputs supported
- ✅ All Terraform outputs provided
- ✅ Behavior matches Terraform module
- ✅ Side-by-side validation passes

## References

- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Upbound Platform Ref](https://github.com/upbound/platform-ref-upbound)
- [thoughts/coding/upbound-patterns.md](../coding/upbound-patterns.md)
- [thoughts/tools/testing-guide.md](../tools/testing-guide.md)
