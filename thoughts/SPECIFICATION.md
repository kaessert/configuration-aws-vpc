# AWS VPC Configuration Specification

## Overview

This document defines **WHAT to build**: the complete specification for building a **drop-in replacement** for the [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module using Upbound and KCL.

**For HOW to build it** (architecture, patterns, code organization), see [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md).

### Project Goal

Create an Upbound control plane configuration that provides feature parity with the terraform-aws-vpc module, supporting all input variables, output values, and behavioral characteristics.

### Scope

The terraform-aws-vpc module is a comprehensive, production-ready Terraform module for AWS VPC management. It abstracts the complexity of VPC configuration and provides sensible defaults while allowing extensive customization. This module is one of the most popular AWS infrastructure modules with extensive test coverage.

## Terraform Module Analysis

### Input Variables

#### Core Network Configuration
- `name`: VPC name
- `cidr`: VPC CIDR block
- `secondary_cidr_blocks`: Additional CIDR blocks
- `azs`: List of availability zones
- `public_subnets`: Public subnet CIDR blocks
- `private_subnets`: Private subnet CIDR blocks
- `database_subnets`: Database-specific subnets
- `elasticache_subnets`: Elasticache-specific subnets
- `redshift_subnets`: Redshift-specific subnets
- `intra_subnets`: Internal subnets (no NAT/IGW)

#### NAT Gateway Configuration
- `single_nat_gateway`: Use one NAT for all AZs
- `one_nat_gateway_per_az`: One NAT per AZ
- `create_igw`: Enable/disable IGW

#### DNS Configuration
- `enable_dns_hostnames`: Enable DNS hostnames
- `enable_dns_support`: Enable DNS support
- `enable_dns64`: IPv6 DNS64 support
- `dhcp_options_domain_name`: Custom domain
- `dhcp_options_domain_name_servers`: Custom DNS servers
- `dhcp_options_ntp_servers`: Custom NTP servers
- `dhcp_options_netbios_name_servers`: NetBIOS servers
- `dhcp_options_netbios_node_type`: NetBIOS node type

#### VPC Endpoint Configuration
- `create_vpc_endpoints`: Enable VPC endpoints
- `enable_s3_endpoint`: S3 gateway endpoint
- `s3_endpoint_type`: S3 endpoint type
- `enable_dynamodb_endpoint`: DynamoDB gateway endpoint
- `enable_nat_gateway`: Enable NAT gateways
- `vpc_endpoint_tags`: Tags for endpoints

#### Flow Logs
- `enable_flow_log`: Enable VPC Flow Logs
- `create_flow_log_cloudwatch_log_group`: CloudWatch log group
- `create_flow_log_s3_bucket`: S3 bucket for logs
- `flow_log_max_aggregation_interval`: Aggregation window
- `flow_log_traffic_type`: All/Accept/Reject

#### Tagging and Naming
- `tags`: Common tags for all resources
- `public_subnet_tags`: Tags for public subnets
- `private_subnet_tags`: Tags for private subnets
- `database_subnet_tags`: Database subnet tags
- `elasticache_subnet_tags`: Elasticache tags
- `redshift_subnet_tags`: Redshift tags
- `vpc_tags`: VPC-specific tags

#### Network Configuration
- `map_public_ip_on_launch`: Auto-assign public IPs
- `enable_nat_gateway`: Create NAT gateways
- `enable_vpn_gateway`: Create VPN gateway
- `enable_ipv6`: Enable IPv6 CIDR
- `ipv6_cidr_block`: IPv6 CIDR specification

#### Route Table and Access Control
- `create_database_subnet_route_table`: Separate DB route table
- `create_database_nat_gateway_route`: NAT route for DB subnets
- `create_elasticache_subnet_route_table`: Elasticache routing
- `create_redshift_subnet_route_table`: Redshift routing

### Output Variables

#### VPC Outputs
- `vpc_id`: VPC identifier
- `vpc_cidr_block`: VPC CIDR
- `vpc_ipv6_cidr_block`: IPv6 CIDR block
- `vpc_enable_dns_support`: DNS support status
- `vpc_enable_dns_hostnames`: DNS hostnames status

#### Subnet Outputs (for each type)
- `public_subnets`: List of public subnet IDs
- `public_subnets_cidr_blocks`: Public CIDR blocks
- `public_subnet_arns`: Public subnet ARNs
- `private_subnets`: List of private subnet IDs
- `private_subnets_cidr_blocks`: Private CIDR blocks
- `database_subnets`: Database subnet IDs
- `elasticache_subnets`: Elasticache subnet IDs
- `redshift_subnets`: Redshift subnet IDs
- `intra_subnets`: Internal subnet IDs

#### Gateway Outputs
- `igw_id`: Internet Gateway ID
- `nat_gateway_ids`: NAT Gateway IDs per AZ
- `vpn_gateway_id`: VPN Gateway ID
- `customer_gateway_ids`: Customer Gateway IDs

#### Route Table Outputs
- `public_route_table_ids`: Public route table IDs
- `private_route_table_ids`: Private route table IDs
- `database_route_table_ids`: Database route table IDs
- `elasticache_route_table_ids`: Elasticache route tables

#### Network ACL Outputs
- `network_acls`: Network ACL resources

#### VPC Endpoint Outputs
- `vpc_endpoint_s3_id`: S3 endpoint ID
- `vpc_endpoint_s3_arn`: S3 endpoint ARN
- `vpc_endpoint_dynamodb_id`: DynamoDB endpoint
- `vpc_endpoint_ids`: All endpoint IDs

#### DHCP and DNS
- `dhcp_options_id`: DHCP options ID
- `dhcp_options_association_id`: Association ID

#### Flow Logs
- `vpc_flow_log_id`: Flow Log ID
- `vpc_flow_log_arn`: Flow Log ARN

---

## AWS Resources Created

This configuration creates the following AWS resources (managed by Crossplane):

- `aws_vpc` - VPC
- `aws_subnet` - Subnets (public, private, database, elasticache, redshift, intra)
- `aws_internet_gateway` - Internet Gateway
- `aws_nat_gateway` - NAT Gateway
- `aws_eip` - Elastic IPs for NAT gateways
- `aws_route_table` - Route tables
- `aws_route` - Individual routes
- `aws_route_table_association` - Route table associations
- `aws_vpc_endpoint` - VPC endpoints (gateway and interface)
- `aws_network_acl` - Network ACLs
- `aws_network_acl_rule` - ACL rules
- `aws_dhcp_options` - DHCP options sets
- `aws_dhcp_options_association` - DHCP associations
- `aws_flow_log` - VPC flow logs
- `aws_cloudwatch_log_group` - CloudWatch log groups for flow logs
- `aws_s3_bucket` - S3 buckets for flow logs
- `aws_security_group` - Security groups for endpoints

**See**: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for module-level implementation details.

---

## Field Mapping

Terraform to Upbound XRD (capitalization differences acceptable):

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
```

**Implementation Patterns**: See [IMPLEMENTATION_GUIDE.md → Implementation Patterns](IMPLEMENTATION_GUIDE.md#implementation-patterns) for conditional creation, looping, dependencies, routing, naming, and tagging strategies.

## Requirements

1. **Region Handling**: Auto-detection of available AZs
2. **CIDR Math**: Automatic subnet CIDR calculation options
3. **High Availability**: Built-in HA patterns with NAT gateways
4. **Cost Optimization**: Single NAT gateway option for cost-sensitive deployments
5. **Security**: Network ACLs and proper routing isolation
6. **Monitoring**: Built-in Flow Logs integration
7. **Compliance**: DHCP customization for corporate requirements
8. **Scalability**: Support for secondary CIDR blocks

## Code Quality Requirements

The implementation must meet these code quality standards:

### Module Size and Organization
- ✅ All modules < 300 lines
- ✅ Clear separation of concerns (one responsibility per module)
- ✅ Modular, testable, maintainable code structure

### Documentation Standards
- ✅ 100% of functions documented with:
  - Purpose description
  - Parameter documentation
  - Return value description
  - Usage examples where appropriate

### Code Quality Standards
- ✅ No code duplication
- ✅ Type-safe implementations
- ✅ Input validation for all user-facing parameters
- ✅ Consistent naming conventions

### Testing Requirements
- ✅ 100% of features have composition tests
- ✅ 100% of critical paths have E2E tests
- ✅ All tests documented with expected behavior

**Implementation Guidance**: See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for how to achieve these standards.

## References

- [Terraform AWS VPC Module Repository](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Module Examples](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples)
- [Crossplane AWS Provider](https://marketplace.upbound.io/providers/upbound/provider-aws)
- [Upbound Documentation](https://docs.upbound.io/)
