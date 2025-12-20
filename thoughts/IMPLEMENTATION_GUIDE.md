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

### Test-Driven Development (TDD) - MANDATORY

**CRITICAL**: This project follows strict TDD. ALL features require tests BEFORE implementation.

The workflow is: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

#### Step-by-Step Process

1. **🔴 RED Phase - Write Test FIRST**
   ```bash
   # Generate composition test
   up test generate test-xvpc-<feature> --language=kcl

   # Edit tests/test-xvpc-<feature>/main.k
   # - Define input XR with parameters
   # - Assert expected managed resources
   # - Assert resource configuration
   # - Assert tags, labels, relationships

   # Run test (MUST fail)
   up test run tests/test-xvpc-<feature>
   # Expected: ❌ FAIL - feature not implemented
   ```

2. **🟢 GREEN Phase - Make Test Pass**
   ```bash
   # Implement minimum code to pass test
   # Edit functions/vpc/main.k or module file

   # Run test until it passes
   up test run tests/test-xvpc-<feature>
   # Expected: ✅ PASS

   # Run ALL tests (check for regressions)
   up test run tests/test-*
   # Expected: ✅ ALL PASS
   # If ANY test fails: FIX THEM NOW
   ```

3. **🔵 REFACTOR Phase - Improve Code**
   ```bash
   # Refactor for clarity/modularity
   # - Extract to modules if needed
   # - Improve naming
   # - Simplify logic

   # Keep ALL tests passing during refactoring
   up test run tests/test-*
   # Expected: ✅ ALL PASS
   ```

4. **🧪 E2E TEST Phase - MANDATORY Real AWS Validation**
   ```bash
   # Generate E2E test (MANDATORY for ALL major features)
   up test generate e2etest-xvpc-<feature> --e2e --language=kcl

   # Edit test: tests/e2etest-xvpc-<feature>/main.k
   # Configure:
   # - ProviderConfig with IAM role
   # - Set timeout: 1800-3000 seconds
   # - Set skipDelete: false (ensure cleanup)
   # - Set validate: true
   # - Add defaultConditions: ["Ready", "Synced"]

   # Run E2E test
   up login
   up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing
   # Wait 30+ minutes for AWS resource creation
   # Expected: ✅ PASS - Resources created, reached Ready/Synced, cleaned up

   # CRITICAL: E2E tests are MANDATORY
   ```

5. **✅ COMMIT Phase - Only When ALL Tests Pass**
   ```bash
   # Final checks - EVERYTHING must be green
   up project build                    # ✅ MUST pass
   up test run tests/test-*            # ✅ ALL composition tests MUST pass
   up test run tests/e2etest-* --e2e --control-plane-group=claude-testing  # ✅ ALL E2E tests MUST pass

   # Only commit when everything is green
   git add .
   git commit -m "feat: implement <feature>

   - Add composition test for <feature>
   - Implement <feature> in functions/vpc/
   - Add E2E test validating real AWS behavior
   - All tests passing
   "
   ```

**NEVER commit failing tests. NEVER skip E2E tests for major features.**

### Feature Implementation - 10-Step Process

For ANY new feature:

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

9. **Write E2E test** (MANDATORY for major features)
   ```bash
   up test generate e2etest-xvpc-<feature> --e2e --language=kcl
   up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing
   ```

10. **Commit**
    ```bash
    git add .
    git commit -m "feat: implement <feature>"
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

# 7. Write E2E test (MANDATORY)
up test generate e2etest-xvpc-nat-single --e2e --language=kcl
up test run tests/e2etest-xvpc-nat-single --e2e --control-plane-group=claude-testing
# ✅ PASS (after 30+ minutes)

# 8. Commit
git add .
git commit -m "feat: implement single NAT Gateway strategy

- Add composition test for single NAT Gateway
- Implement NAT Gateway generation in gateway.k
- Add E2E test validating real AWS NAT behavior
- All tests passing (17 composition + 1 E2E)
"
```

## Testing Strategy

### Test Hierarchy

#### Level 1: Composition Tests (Unit)
Fast, isolated tests validating composition logic.

**Purpose**: Validate that composition generates correct managed resources

**Characteristics**:
- Fast (< 10 seconds)
- No AWS calls
- 100% feature coverage
- Run frequently during development

**Example**:
```bash
up test generate test-xvpc-public-subnets --language=kcl
up test run tests/test-xvpc-public-subnets
```

Test that public subnets are created with `mapPublicIpOnLaunch: true`

#### Level 2: Integration Tests
Test multiple modules working together.

**Purpose**: Validate that modules integrate correctly

**Example**:
```bash
up test run tests/test-xvpc-routing-complete
```

Test that subnets + route tables + routes work together

#### Level 3: E2E Tests (MANDATORY)
Real AWS resources, full lifecycle.

**Purpose**: Validate behavior matches Terraform module in real AWS

**Characteristics**:
- Slow (10-30 minutes)
- Real AWS resources
- MANDATORY for all major features
- Validates actual AWS behavior
- Ensures cleanup

**Example**:
```bash
up test run tests/e2etest-xvpc-complete --e2e --control-plane-group=claude-testing
```

Create VPC in AWS, verify all resources reach Ready/Synced, clean up

**CRITICAL**: Composition tests validate KCL logic, E2E tests validate real AWS behavior. Both are required.

### Test Coverage Requirements

- **100% feature coverage**: Every feature has composition test
- **MANDATORY E2E**: All major features have E2E tests
- **Critical path validation**: All 12 test case scenarios covered
- **Parity validation**: Side-by-side comparison with Terraform outputs

## Commit Policy

**CRITICAL CHECKS - Before Every Commit**

```bash
# 1. Project builds
up project build
# ✅ MUST pass

# 2. All composition tests pass
up test run tests/test-*
# ✅ ALL MUST pass

# 3. All E2E tests pass (MANDATORY)
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing
# ✅ ALL MUST pass

# If ANY test fails: DO NOT COMMIT - fix tests first!

# Only commit when everything is green
git add .
git commit -m "feat: implement <feature>

- Description of changes
- All tests passing (N composition + M E2E)
"
```

**NEVER commit if ANY test fails (composition OR E2E). Fix tests first.**

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
- [thoughts/SPECIFICATION.md](SPECIFICATION.md) - What to build
- [thoughts/KCL_PATTERNS.md](KCL_PATTERNS.md) - Code reference
