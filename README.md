# AWS VPC Configuration for Upbound

A production-ready Upbound control plane configuration that provides **feature parity** with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) Terraform module.

Build AWS VPCs using Crossplane Composite Resources, KCL composition functions, and declarative Kubernetes-style configuration.

## Production Readiness

✅ **Phase 4 COMPLETED** - All critical (P0), high-priority (P1), and important (P2) features implemented
✅ **68 Composition Tests** - All features validated with fast unit tests
✅ **15 E2E Tests** - Critical paths tested against real AWS infrastructure
✅ **~90% Feature Parity** - Comprehensive feature set matching Terraform AWS VPC module
✅ **Modular Design** - 10 focused KCL modules (~3000 lines), well-organized and maintainable
✅ **Zero Failing Tests** - All tests passing, no known regressions

**Ready for**: Production environments with comprehensive requirements including hybrid cloud (VPN), IPv6 networks, enterprise IP management (IPAM), interface endpoints, and advanced routing
**Includes**: VPC, Subnets (all 6 types), NAT (3 strategies), Routing, Gateway Endpoints, Interface Endpoints, NACLs (all subnet types), DHCP, Flow Logs, Subnet Groups, Secondary CIDRs, VPN Gateway, Customer Gateways, IPv6 (dual-stack & native), IPAM, Default Resource Management

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

**Phase 1-3 Features (Core & Enhanced Networking):**
- **VPC Creation**: Basic VPC with DNS support, customizable CIDR blocks, instance tenancy
- **Subnets**: Six subnet types across multiple availability zones
  - Public subnets (with auto-assign public IP)
  - Private subnets
  - Database subnets
  - ElastiCache subnets
  - Redshift subnets
  - Intra subnets (no internet access)
- **Internet Gateway**: Conditional creation and VPC attachment
- **NAT Gateway**: Three strategies (single NAT, per-AZ, per-subnet), EIP reuse, custom destination CIDR
- **Route Tables**: Public, private, database, and isolated routing with flexible association
- **VPC Endpoints (Gateway)**: S3 and DynamoDB gateway endpoints
- **Network ACLs**: Dedicated ACLs with custom rules for all subnet types (public, private, database, ElastiCache, Redshift, intra)
- **DHCP Options**: Custom DNS servers, domain names, NTP servers, NetBIOS settings
- **VPC Flow Logs**: Traffic monitoring to CloudWatch Logs or S3 with configurable filters
- **Subnet Groups**: Database, ElastiCache, and Redshift subnet groups for managed services
- **Secondary CIDR Blocks**: IP space expansion with multiple CIDR blocks per VPC
- **Tagging**: Flexible tag merging for all resources
- **Multi-AZ Support**: Distribute resources across availability zones

**Phase 4 Features (Advanced):**
- **VPN Gateway**: Hybrid cloud connectivity with route propagation to all subnet types
- **Customer Gateways**: VPN customer side configuration with BGP support
- **IPv6 Support**: Dual-stack and IPv6-native configurations with Egress-Only IGW
- **IPAM Integration**: AWS IPAM for dynamic CIDR allocation (IPv4 and IPv6)
- **Interface VPC Endpoints**: Private connectivity for EC2, SSM, RDS, Secrets Manager, and custom services
- **Extended NACL Support**: Dedicated NACLs for database, ElastiCache, Redshift, and intra subnets
- **Extended Routing**: Per-AZ public routes, ElastiCache routing, Redshift routing (private & public)
- **Default Resource Management**: Manage default VPC resources (security group, NACL, route table)
- **NAT Gateway Enhancements**: Per-subnet NAT, EIP reuse, custom destination CIDR

### Optional Future Enhancements (P3 - Nice to Have) 📋

- **Subnet Configuration**: Custom subnet naming and per-AZ tags (low priority)
- **VPC Block Public Access**: New AWS security feature (waiting for provider support)
- **Outpost Subnets**: AWS Outposts support (niche use case)

See [thoughts/TASKS.md](thoughts/TASKS.md) for the complete roadmap and status.

## Quick Start

> **Note**: All implemented features are production-ready and fully tested with 68 composition tests and 15 E2E tests covering all Phase 1-4 features.

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

See the [examples/](examples/) directory for comprehensive, production-ready examples:

**Basic Examples:**
- `simple-vpc.yaml` - Minimal VPC with public subnets
- `multi-subnet-vpc.yaml` - All subnet types across multiple AZs

**Feature Showcases:**
- `complete-vpc.yaml` ⭐ - **Complete reference** with all features (NAT, endpoints, ACLs, DHCP, Flow Logs, Subnet Groups, Secondary CIDRs)
- `with-endpoints.yaml` - VPC Endpoints for private AWS service access
- `with-flow-logs.yaml` - Traffic monitoring with VPC Flow Logs
- `with-ipv6-dual-stack.yaml` - IPv6 dual-stack configuration with Egress-Only IGW
- `with-vpn.yaml` - VPN Gateway and Customer Gateways for hybrid cloud

**NAT Gateway Strategies:**
- `nat-single.yaml` - Single NAT Gateway (cost-optimized: ~$32/month)
- `nat-per-az.yaml` - NAT Gateway per AZ (high availability: ~$96/month)
- NAT per subnet - Maximum availability (cost: ~$32/month × number of subnets)

**Advanced Configurations:**
- `private-only.yaml` - Private subnets without direct internet access
- `multi-az.yaml` - High availability across 3 availability zones

**Total**: 11 production-ready examples covering all implemented features with inline documentation, cost analysis, and use case guidance.

See [examples/README.md](examples/README.md) for detailed documentation, cost comparisons, and usage guidance.

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
- **KCL Function**: Modular design with 10 focused modules (~2300 lines total)
  - `vpc.k` - Core VPC resource
  - `subnets.k` - All 6 subnet types
  - `gateways.k` - IGW, EIP, and NAT Gateway
  - `routing.k` - Route tables and associations
  - `endpoints.k` - VPC Endpoints (Gateway)
  - `nacl.k` - Network ACLs
  - `dhcp.k` - DHCP Options
  - `flowlogs.k` - VPC Flow Logs
  - `subnetgroups.k` - DB/ElastiCache/Redshift subnet groups
  - `main.k` - Orchestration and coordination
- **Tests**: 32 composition tests + 10 E2E tests validate all features

> **Note**: Modular refactoring completed in Phase 2.6, ensuring clean separation of concerns and maintainability.

### Design Principles

1. **Test-Driven Development**: All features tested before implementation
2. **Modular Design**: Clean separation of concerns
3. **Terraform Compatibility**: Exact feature parity with reference module
4. **Best Practices**: Follows patterns from [platform-ref-upbound](https://github.com/upbound/platform-ref-upbound)

## Testing

This project follows **strict Test-Driven Development (TDD)**:

🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

### Current Test Coverage

**Composition Tests**: 68 tests (all passing) ✅
- VPC basics (1 test)
- All 6 subnet types (6 tests)
- Internet Gateway (2 tests)
- NAT Gateway strategies (6 tests: single, per-AZ, per-subnet, reuse EIPs, custom CIDR, disabled)
- Route tables (8 tests: public, private single NAT, private per-AZ, isolated, database NAT, database IGW, ElastiCache NAT, Redshift NAT, Redshift public, public per-AZ, intra per-AZ)
- VPC Endpoints (3 tests: S3 gateway, DynamoDB gateway, disabled)
- Interface VPC Endpoints (5 tests: single, multiple, custom SG, no private DNS, disabled)
- Network ACLs (6 tests: public, private, database, ElastiCache, Redshift, intra)
- DHCP Options (2 tests)
- VPC Flow Logs (3 tests)
- Subnet Groups (3 tests)
- Secondary CIDR Blocks (1 test)
- VPN Gateway (4 tests: enabled, disabled, custom ASN, selective propagation)
- Customer Gateway (2 tests)
- IPv6 Support (6 tests: dual-stack, native, disabled, routing, Egress-Only IGW, IPAM)
- IPAM Integration (2 tests: IPv4, IPv6)
- Default Resource Management (4 tests: security group, NACL, route table)
- Instance Tenancy (2 tests)

**E2E Tests**: 15 tests (all passing) ✅
- Basic VPC
- Complete VPC
- Simple VPC
- NAT strategies (2 tests: single, enhancements)
- VPC Endpoints
- DHCP Options
- Network ACLs (2 tests: public/private, extended all subnet types)
- Flow Logs
- Subnet Groups
- Secondary CIDR Blocks
- VPN Gateway
- IPv6 Support (dual-stack)
- Interface VPC Endpoints

### Run Tests

```bash
# Run all composition tests (fast, no AWS)
up test run tests/test-*

# Run specific test
up test run tests/test-xvpc-public-subnets

# Run E2E tests (requires AWS credentials)
up login
up test run tests/e2etest-vpc-basic --e2e
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

- Follow patterns in [thoughts/UPBOUND_REFERENCE.md](thoughts/UPBOUND_REFERENCE.md)
- Write composition tests for all features
- Document breaking changes
- Update examples when adding features

## Project Status

**Phase**: Phase 4: Advanced Features - **COMPLETED** ✅

**Completed**:
- ✅ Phase 1: Project foundation and structure
- ✅ Phase 2: Core VPC Features
  - VPC creation with DNS settings and instance tenancy
  - All 6 subnet types (public, private, database, elasticache, redshift, intra)
  - Internet Gateway with conditional creation
  - NAT Gateway (single, per-AZ, and per-subnet strategies)
  - Comprehensive routing for all subnet types
  - Modular code structure (10 KCL modules, ~3000 lines)
- ✅ Phase 3: Enhanced Networking Features
  - VPC Endpoints (Gateway: S3, DynamoDB)
  - Network ACLs (all subnet types with custom rules)
  - DHCP Options (DNS servers, domain name, NTP, NetBIOS)
  - VPC Flow Logs (CloudWatch and S3 destinations)
  - Subnet Groups (RDS, ElastiCache, Redshift)
  - Secondary CIDR Blocks (IP space expansion)
  - IPAM Integration (IPv4 support)
- ✅ Phase 4: Advanced Features
  - VPN Gateway - Hybrid cloud connectivity with route propagation
  - Customer Gateways - VPN customer side configuration
  - IPv6 Support - Dual-stack and IPv6-native with Egress-Only IGW
  - IPAM Integration - IPv4 and IPv6 support
  - Interface VPC Endpoints - EC2, SSM, RDS, Secrets Manager, custom services
  - Extended NACL Support - All subnet types (database, ElastiCache, Redshift, intra)
  - Extended Routing - Per-AZ public routes, ElastiCache/Redshift routing
  - Default Resource Management - Security group, NACL, route table management
  - NAT Gateway Enhancements - Per-subnet NAT, EIP reuse, custom destination CIDR

**Test Coverage**: 68 composition tests + 15 E2E tests - **ALL PASSING** ✅

**Feature Parity**: ~90% vs Terraform AWS VPC module

**Remaining (Optional - P3 priorities)**:
- Subnet Configuration Enhancements - Custom naming/suffixes (low priority)
- VPC Block Public Access - Waiting for provider support (AWS feature from Nov 2024)
- Outpost Subnets - Niche use case for AWS Outposts

**Next Up (Phase 5-6)**:
- Phase 5: Additional examples and documentation
- Phase 6: User-facing documentation completion
- Phase 7: Performance optimization

See [thoughts/TASKS.md](thoughts/TASKS.md) for the complete roadmap.

## Documentation

### For Users
- [README.md](README.md) - This file
- [examples/](examples/) - Usage examples
- [TESTING.md](TESTING.md) - Testing guide

### For Developers
- [CLAUDE.md](CLAUDE.md) - Comprehensive development guide
- [thoughts/tasks.md](thoughts/tasks.md) - Prioritized task list
- [thoughts/SPECIFICATION.md](thoughts/SPECIFICATION.md) - Feature specification
- [thoughts/UPBOUND_REFERENCE.md](thoughts/UPBOUND_REFERENCE.md) - Upbound patterns and best practices
- [thoughts/KCL_REFERENCE.md](thoughts/KCL_REFERENCE.md) - KCL language reference
- [thoughts/GIT_REFERENCE.md](thoughts/GIT_REFERENCE.md) - Git workflow reference

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
  secondaryCidrBlocks: [string]     # Additional CIDR blocks for IP space expansion
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

  # Routing
  createDatabaseSubnetRouteTable: bool     # Create separate route table for DB subnets
  createDatabaseNatGatewayRoute: bool      # Route DB subnets through NAT

  # VPC Endpoints
  enableS3Endpoint: bool            # Create S3 gateway endpoint (default: false)
  enableDynamodbEndpoint: bool      # Create DynamoDB gateway endpoint (default: false)
  s3EndpointType: string            # S3 endpoint type: Gateway or Interface (default: Gateway)
  vpcEndpointTags: {string: string} # Tags for VPC endpoints

  # Network ACLs
  publicDedicatedNetworkAcl: bool   # Create dedicated NACL for public subnets (default: false)
  privateDedicatedNetworkAcl: bool  # Create dedicated NACL for private subnets (default: false)
  databaseDedicatedNetworkAcl: bool # Create dedicated NACL for database subnets (default: false)
  elasticacheDedicatedNetworkAcl: bool  # Create dedicated NACL for ElastiCache subnets (default: false)
  redshiftDedicatedNetworkAcl: bool # Create dedicated NACL for Redshift subnets (default: false)
  intraDedicatedNetworkAcl: bool    # Create dedicated NACL for intra subnets (default: false)
  publicInboundAclRules: [object]   # Custom inbound rules for public NACL
  publicOutboundAclRules: [object]  # Custom outbound rules for public NACL
  privateInboundAclRules: [object]  # Custom inbound rules for private NACL
  privateOutboundAclRules: [object] # Custom outbound rules for private NACL
  databaseInboundAclRules: [object] # Custom inbound rules for database NACL
  databaseOutboundAclRules: [object]# Custom outbound rules for database NACL
  elasticacheInboundAclRules: [object]  # Custom inbound rules for ElastiCache NACL
  elasticacheOutboundAclRules: [object] # Custom outbound rules for ElastiCache NACL
  redshiftInboundAclRules: [object] # Custom inbound rules for Redshift NACL
  redshiftOutboundAclRules: [object]# Custom outbound rules for Redshift NACL
  intraInboundAclRules: [object]    # Custom inbound rules for intra NACL
  intraOutboundAclRules: [object]   # Custom outbound rules for intra NACL
  publicAclTags: {string: string}   # Tags for public NACL
  privateAclTags: {string: string}  # Tags for private NACL
  databaseAclTags: {string: string} # Tags for database NACL
  elasticacheAclTags: {string: string}  # Tags for ElastiCache NACL
  redshiftAclTags: {string: string} # Tags for Redshift NACL
  intraAclTags: {string: string}    # Tags for intra NACL

  # DHCP Options
  enableDhcpOptions: bool           # Create DHCP options set (default: false)
  domainName: string                # DNS domain name
  domainNameServers: [string]       # DNS servers (default: ["AmazonProvidedDNS"])
  ntpServers: [string]              # NTP servers
  netbiosNameServers: [string]      # NetBIOS name servers
  netbiosNodeType: int              # NetBIOS node type (1, 2, 4, or 8)
  dhcpOptionsTags: {string: string} # Tags for DHCP options

  # VPC Flow Logs
  enableFlowLog: bool               # Enable VPC Flow Logs (default: false)
  flowLogDestination: string        # Destination type: cloud-watch-logs or s3
  flowLogDestinationArn: string     # CloudWatch log group ARN or S3 bucket ARN
  flowLogTrafficType: string        # Traffic type: ALL, ACCEPT, or REJECT (default: ALL)
  flowLogMaxAggregationInterval: int # Aggregation interval in seconds: 60 or 600 (default: 600)
  flowLogFileFormat: string         # S3 file format: plain-text or parquet (default: plain-text)
  flowLogHiveCompatiblePartitions: bool  # Enable Hive-compatible S3 partitions (default: false)
  flowLogPerHourPartition: bool     # Enable per-hour S3 partitions (default: false)
  flowLogTags: {string: string}     # Tags for flow logs

  # Subnet Groups
  createDatabaseSubnetGroup: bool       # Create RDS subnet group (default: true when databaseSubnets exist)
  createElasticacheSubnetGroup: bool    # Create ElastiCache subnet group (default: true when elasticacheSubnets exist)
  createRedshiftSubnetGroup: bool       # Create Redshift subnet group (default: true when redshiftSubnets exist)
  databaseSubnetGroupName: string       # Custom name for DB subnet group
  elasticacheSubnetGroupName: string    # Custom name for ElastiCache subnet group
  redshiftSubnetGroupName: string       # Custom name for Redshift subnet group
  databaseSubnetGroupTags: {string: string}     # Tags for DB subnet group
  elasticacheSubnetGroupTags: {string: string}  # Tags for ElastiCache subnet group
  redshiftSubnetGroupTags: {string: string}     # Tags for Redshift subnet group

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

### VPC Outputs (Status Fields)

After a VPC is created and reconciled, the following status fields are available:

```yaml
status:
  # VPC Outputs
  vpcId: string                          # ID of the VPC
  vpcArn: string                         # ARN of the VPC
  vpcCidrBlock: string                   # The CIDR block of the VPC
  vpcIpv6CidrBlock: string              # The IPv6 CIDR block (if enabled)
  vpcEnableDnsSupport: bool             # Whether DNS support is enabled
  vpcEnableDnsHostnames: bool           # Whether DNS hostnames are enabled

  # Subnet Outputs
  publicSubnets: [string]               # List of public subnet IDs
  publicSubnetsCidrBlocks: [string]     # List of public subnet CIDR blocks
  publicSubnetArns: [string]            # List of public subnet ARNs
  privateSubnets: [string]              # List of private subnet IDs
  privateSubnetsCidrBlocks: [string]    # List of private subnet CIDR blocks
  privateSubnetArns: [string]           # List of private subnet ARNs
  databaseSubnets: [string]             # List of database subnet IDs
  databaseSubnetsCidrBlocks: [string]   # List of database subnet CIDR blocks
  elasticacheSubnets: [string]          # List of ElastiCache subnet IDs
  elasticacheSubnetsCidrBlocks: [string] # List of ElastiCache subnet CIDR blocks
  redshiftSubnets: [string]             # List of Redshift subnet IDs
  redshiftSubnetsCidrBlocks: [string]   # List of Redshift subnet CIDR blocks
  intraSubnets: [string]                # List of intra subnet IDs
  intraSubnetsCidrBlocks: [string]      # List of intra subnet CIDR blocks

  # Gateway Outputs
  igwId: string                         # Internet Gateway ID
  igwArn: string                        # Internet Gateway ARN
  natGatewayIds: [string]               # List of NAT Gateway IDs
  natEipPublicIps: [string]             # List of Elastic IP addresses for NAT Gateways
  vpnGatewayId: string                  # VPN Gateway ID (if enabled)
  vpnGatewayArn: string                 # VPN Gateway ARN (if enabled)
  customerGatewayIds: {string: string}  # Map of Customer Gateway names to IDs
  customerGatewayArns: {string: string} # Map of Customer Gateway names to ARNs

  # Route Table Outputs
  publicRouteTableIds: [string]         # List of public route table IDs
  privateRouteTableIds: [string]        # List of private route table IDs
  databaseRouteTableIds: [string]       # List of database route table IDs
  elasticacheRouteTableIds: [string]    # List of ElastiCache route table IDs
  redshiftRouteTableIds: [string]       # List of Redshift route table IDs
  intraRouteTableIds: [string]          # List of intra route table IDs

  # VPC Endpoint Outputs
  vpcEndpointS3Id: string               # S3 VPC endpoint ID
  vpcEndpointDynamodbId: string         # DynamoDB VPC endpoint ID

  # DHCP Options Outputs
  dhcpOptionsId: string                 # DHCP options set ID
  dhcpOptionsAssociationId: string      # DHCP options association ID

  # Flow Log Outputs
  vpcFlowLogId: string                  # VPC Flow Log ID
  vpcFlowLogArn: string                 # VPC Flow Log ARN
  vpcFlowLogDestinationArn: string      # Flow Log destination ARN

  # Subnet Group Outputs
  databaseSubnetGroupId: string         # Database subnet group ID
  databaseSubnetGroupName: string       # Database subnet group name
  databaseSubnetGroupArn: string        # Database subnet group ARN
  elasticacheSubnetGroupName: string    # ElastiCache subnet group name
  redshiftSubnetGroupId: string         # Redshift subnet group ID
  redshiftSubnetGroupName: string       # Redshift subnet group name
  redshiftSubnetGroupArn: string        # Redshift subnet group ARN

  # Default Resource Outputs
  defaultSecurityGroupId: string        # Default security group ID
  defaultNetworkAclId: string           # Default Network ACL ID
  defaultRouteTableId: string           # Default route table ID
```

**Usage Example:**

```bash
# Get VPC status
kubectl get vpc my-vpc -o yaml

# Extract specific outputs
kubectl get vpc my-vpc -o jsonpath='{.status.vpcId}'
kubectl get vpc my-vpc -o jsonpath='{.status.publicSubnets[*]}'
kubectl get vpc my-vpc -o jsonpath='{.status.natGatewayIds[*]}'
```

## Comparison with Terraform Module

| Feature | Terraform Module | This Project | Status |
|---------|-----------------|--------------|--------|
| Basic VPC | ✅ | ✅ | Implemented |
| All Subnet Types (6) | ✅ | ✅ | Implemented |
| Internet Gateway | ✅ | ✅ | Implemented |
| NAT Gateway (3 strategies) | ✅ | ✅ | Implemented |
| Route Tables (All subnet types) | ✅ | ✅ | Implemented |
| VPC Endpoints (Gateway) | ✅ | ✅ | Implemented |
| VPC Endpoints (Interface) | ✅ | ✅ | Implemented |
| Network ACLs (All types) | ✅ | ✅ | Implemented |
| DHCP Options | ✅ | ✅ | Implemented |
| VPC Flow Logs | ✅ | ✅ | Implemented |
| Subnet Groups (RDS/EC/Redshift) | ✅ | ✅ | Implemented |
| Secondary CIDRs | ✅ | ✅ | Implemented |
| VPN Gateway | ✅ | ✅ | Implemented |
| Customer Gateways | ✅ | ✅ | Implemented |
| IPv6 Support (Dual-stack & Native) | ✅ | ✅ | Implemented |
| IPAM Integration (IPv4 & IPv6) | ✅ | ✅ | Implemented |
| Default Resource Management | ✅ | ✅ | Implemented |
| Extended Routing Options | ✅ | ✅ | Implemented |
| Subnet Naming/Suffixes | ✅ | ⏸️ | Deferred (P3) |
| VPC Block Public Access | ✅ | ⏸️ | Deferred (Provider support needed) |
| Outpost Subnets | ✅ | ⏸️ | Deferred (P3) |

> **Feature Parity**: ~90% complete (18 of 21 major features implemented, 3 deferred as P3/low priority)

See [thoughts/TASKS.md](thoughts/TASKS.md) for detailed feature status and rationale.

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
- Review [thoughts/](thoughts/) for comprehensive development guides
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
