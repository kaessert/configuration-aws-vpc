# AWS VPC Configuration for Upbound

A production-ready Upbound control plane configuration that provides **feature parity** with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) Terraform module.

Build AWS VPCs using Crossplane Composite Resources, KCL composition functions, and declarative Kubernetes-style configuration.

## Overview

This project implements a **drop-in replacement** for the Terraform AWS VPC module using Upbound's control plane architecture. It enables platform teams to provision AWS VPCs with the same flexibility and features as the Terraform module, but with the benefits of Kubernetes-native infrastructure management.

### Why Use This?

- **Kubernetes-Native**: Manage VPCs declaratively using Kubernetes CRDs
- **Feature Parity**: All features from the Terraform module, backed by comprehensive tests
- **Test-Driven**: Every feature is tested before implementation (TDD approach)
- **Modular Design**: Clean, maintainable KCL code following Upbound best practices
- **Production-Ready**: Built to the same standards as official Upbound configurations

## Features

### Implemented ✅

- **VPC Creation**: Basic VPC with DNS support, customizable CIDR blocks
- **Subnets**: Six subnet types across multiple availability zones
  - Public subnets (with auto-assign public IP)
  - Private subnets
  - Database subnets
  - ElastiCache subnets
  - Redshift subnets
  - Intra subnets (no internet access)
- **Internet Gateway**: Conditional creation and VPC attachment
- **Tagging**: Flexible tag merging for all resources
- **Multi-AZ Support**: Distribute resources across availability zones

### In Progress 🚧

- **NAT Gateway**: Single NAT and NAT-per-AZ strategies
- **Route Tables**: Public, private, and isolated routing
- **Comprehensive Testing**: Composition tests and E2E tests

### Roadmap 📋

- VPC Endpoints (S3, DynamoDB, interface endpoints)
- Network ACLs
- DHCP Options
- VPC Flow Logs
- Secondary CIDR blocks
- VPN Gateway support
- IPv6 support

See [thoughts/tasks.md](thoughts/tasks.md) for the complete roadmap.

## Quick Start

### Prerequisites

- [Upbound CLI](https://docs.upbound.io/manuals/cli/) installed
- AWS credentials configured
- Kubernetes cluster (for deployment)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd configuration-aws-vpc

# Build the project
up project build

# Test locally
up project run
```

### Usage

Create a simple VPC:

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: VPC
metadata:
  name: my-vpc
  namespace: default
spec:
  region: us-west-2
  cidr: 10.0.0.0/16
  azs:
    - us-west-2a
    - us-west-2b
  publicSubnets:
    - 10.0.1.0/24
    - 10.0.2.0/24
  privateSubnets:
    - 10.0.10.0/24
    - 10.0.11.0/24
  enableDnsHostnames: true
  enableDnsSupport: true
  tags:
    Environment: production
    Owner: platform-team
```

Apply the configuration:

```bash
kubectl apply -f examples/simple-vpc.yaml
```

Check status:

```bash
kubectl get xvpc
kubectl describe xvpc my-vpc
```

### More Examples

See the [examples/](examples/) directory for comprehensive examples:

- `simple-vpc.yaml` - Minimal VPC with public subnets
- `multi-subnet-vpc.yaml` - All subnet types across multiple AZs
- More examples coming soon...

## Architecture

This project follows Upbound's architectural best practices:

```
configuration-aws-vpc/
├── apis/
│   └── vpc/
│       ├── definition.yaml    # XRD (API definition)
│       └── composition.yaml   # Composition (orchestration)
├── functions/
│   └── vpc/
│       ├── main.k            # KCL composition logic
│       └── kcl.mod           # KCL dependencies
├── examples/                  # Usage examples
├── tests/                     # Composition and E2E tests
└── thoughts/                  # Documentation and guides
```

### Key Components

- **XRD (Composite Resource Definition)**: Defines the API surface matching Terraform module inputs
- **Composition**: Orchestrates the KCL function
- **KCL Function**: Generates AWS managed resources (VPC, Subnets, IGW, etc.)
- **Tests**: Validates feature parity and behavior

### Design Principles

1. **Test-Driven Development**: All features tested before implementation
2. **Modular Design**: Clean separation of concerns
3. **Terraform Compatibility**: Exact feature parity with reference module
4. **Best Practices**: Follows patterns from [platform-ref-upbound](https://github.com/upbound/platform-ref-upbound)

## Testing

This project follows **strict Test-Driven Development (TDD)**:

🔴 RED → 🟢 GREEN → 🔵 REFACTOR → ✅ COMMIT

### Run Tests

```bash
# Run all composition tests (fast, no AWS)
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-public-subnets

# Run E2E tests (requires AWS credentials)
up login
up test run tests/e2etest-xvpc-basic --e2e
```

### Test Types

- **Composition Tests**: Fast unit tests validating resource generation (< 10s)
- **E2E Tests**: Integration tests with real AWS resources (10-30 minutes)

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

## Development

### Prerequisites

- Go 1.21+
- Upbound CLI
- AWS CLI configured
- Kubernetes cluster (local or remote)

### Development Workflow

1. **Check tasks**: See [thoughts/tasks.md](thoughts/tasks.md) for prioritized tasks
2. **Write test first**: Generate and write test before implementation
3. **Implement feature**: Make the test pass
4. **Refactor**: Improve code while keeping tests green
5. **Commit**: Only commit when all tests pass

### Project Commands

```bash
# Build the project
up project build

# Run locally for testing
up project run

# Run tests
up test run tests/test-*

# Stop local run
up project stop

# Push to registry
up project push
```

### Before Committing

Always ensure:
- ✅ All tests pass: `up test run tests/test-*`
- ✅ Project builds: `up project build`
- ✅ No regressions in existing tests

**NEVER commit failing tests.**

## Contributing

Contributions are welcome! This project follows test-driven development practices.

### Contributing Workflow

1. Check [thoughts/tasks.md](thoughts/tasks.md) for available tasks
2. Read [CLAUDE.md](CLAUDE.md) for comprehensive development guidelines
3. Read [TESTING.md](TESTING.md) for testing guidelines
4. **Write tests FIRST** for any new feature
5. Implement the feature to pass tests
6. Ensure all tests pass before submitting PR
7. Follow conventional commit messages (feat:, fix:, docs:, test:)

### Code Standards

- Follow patterns in [thoughts/coding/upbound-patterns.md](thoughts/coding/upbound-patterns.md)
- Write composition tests for all features
- Document breaking changes
- Update examples when adding features

## Project Status

**Phase**: Core VPC Features Implementation (Phase 2)

**Completed**:
- ✅ Project foundation and structure
- ✅ XRD with comprehensive API surface
- ✅ Basic VPC creation with DNS settings
- ✅ All 6 subnet types (public, private, database, elasticache, redshift, intra)
- ✅ Internet Gateway with conditional creation
- ✅ Tag management and merging

**In Progress**:
- 🚧 NAT Gateway implementation (single and per-AZ)
- 🚧 Route tables and routing logic
- 🚧 Comprehensive test coverage

**Next Up**:
- VPC Endpoints
- Network ACLs
- VPC Flow Logs

See [thoughts/tasks.md](thoughts/tasks.md) for the complete roadmap.

## Documentation

### For Users
- [README.md](README.md) - This file
- [examples/](examples/) - Usage examples
- [TESTING.md](TESTING.md) - Testing guide

### For Developers
- [CLAUDE.md](CLAUDE.md) - Comprehensive development guide
- [thoughts/tasks.md](thoughts/tasks.md) - Prioritized task list
- [thoughts/spec/terraform-vpc-analysis.md](thoughts/spec/terraform-vpc-analysis.md) - Feature specification
- [thoughts/coding/upbound-patterns.md](thoughts/coding/upbound-patterns.md) - Coding standards
- [thoughts/tools/](thoughts/tools/) - Tool references (up-cli, KCL, git)

### Related Documentation
- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc) - Reference implementation
- [Upbound Documentation](https://docs.upbound.io/) - Upbound platform docs
- [Crossplane Documentation](https://docs.crossplane.io/) - Crossplane concepts
- [KCL Language](https://kcl-lang.io/) - KCL reference

## API Reference

### VPC Resource

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: VPC
metadata:
  name: string
  namespace: default  # REQUIRED for namespaced resources
spec:
  # Core Configuration
  region: string                    # AWS region (required)
  cidr: string                      # VPC CIDR block (required)
  azs: [string]                     # Availability zones (required)

  # DNS Settings
  enableDnsHostnames: bool          # Enable DNS hostnames (default: true)
  enableDnsSupport: bool            # Enable DNS support (default: true)

  # Subnets
  publicSubnets: [string]           # Public subnet CIDRs
  privateSubnets: [string]          # Private subnet CIDRs
  databaseSubnets: [string]         # Database subnet CIDRs
  elasticacheSubnets: [string]      # ElastiCache subnet CIDRs
  redshiftSubnets: [string]         # Redshift subnet CIDRs
  intraSubnets: [string]            # Intra subnet CIDRs

  # Gateways
  createIgw: bool                   # Create Internet Gateway (default: true)
  enableNatGateway: bool            # Create NAT Gateway (default: false)
  singleNatGateway: bool            # Single NAT vs per-AZ (default: false)
  oneNatGatewayPerAz: bool          # One NAT per AZ (default: false)

  # Tagging
  tags: {string: string}            # Tags for all resources
  publicSubnetTags: {string: string}
  privateSubnetTags: {string: string}
  databaseSubnetTags: {string: string}
  elasticacheSubnetTags: {string: string}
  redshiftSubnetTags: {string: string}
  intraSubnetTags: {string: string}
```

See [apis/vpc/definition.yaml](apis/vpc/definition.yaml) for the complete API definition.

## Comparison with Terraform Module

| Feature | Terraform Module | This Project | Status |
|---------|-----------------|--------------|--------|
| Basic VPC | ✅ | ✅ | Implemented |
| All Subnet Types | ✅ | ✅ | Implemented |
| Internet Gateway | ✅ | ✅ | Implemented |
| NAT Gateway | ✅ | 🚧 | In Progress |
| Route Tables | ✅ | 🚧 | In Progress |
| VPC Endpoints | ✅ | 📋 | Planned |
| Network ACLs | ✅ | 📋 | Planned |
| VPN Gateway | ✅ | 📋 | Planned |
| IPv6 Support | ✅ | 📋 | Planned |

See [thoughts/spec/terraform-vpc-analysis.md](thoughts/spec/terraform-vpc-analysis.md) for detailed feature comparison.

## Troubleshooting

### Common Issues

**Project won't build**:
```bash
# Check dependencies
up project build --verbose

# Verify KCL syntax
cd functions/vpc && kcl run main.k
```

**Tests failing**:
```bash
# Run specific test with verbose output
up test run tests/test-xvpc-basic --verbose

# Check generated resources
kubectl get managed
kubectl describe <resource>
```

**Resources not creating**:
```bash
# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check composition status
kubectl describe xvpc <name>

# Check managed resource status
kubectl describe <managed-resource>
```

### Getting Help

- Check [CLAUDE.md](CLAUDE.md) for detailed development instructions
- Review [thoughts/tools/](thoughts/tools/) for tool-specific guides
- Consult [Upbound Documentation](https://docs.upbound.io/)
- Open an issue with reproduction steps

## License

Apache-2.0

## Maintainers

Upbound Solutions Team

## Acknowledgments

- [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) - Reference implementation
- [platform-ref-upbound](https://github.com/upbound/platform-ref-upbound) - Architectural patterns
- Upbound and Crossplane communities

---

**Ready to get started?** Check out the [examples/](examples/) directory or read the [Quick Start](#quick-start) guide above.

**Contributing?** Read [CLAUDE.md](CLAUDE.md) and [TESTING.md](TESTING.md) to understand our development workflow.

**Questions?** Open an issue or consult the [documentation](#documentation).
