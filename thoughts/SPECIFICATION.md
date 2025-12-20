# AWS VPC Configuration Specification

## Overview

This document defines the complete specification for building a **drop-in replacement** for the [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module using Upbound and KCL.

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

## Test Case Scenarios

The module's test suite covers these primary scenarios:

### 1. COMPLETE VPC with All Features
- Full VPC with all subnet types
- Public, private, database, elasticache, and redshift subnets
- NAT gateways for high availability
- Internet gateway with proper routing
- Network ACLs with custom rules
- VPC endpoints (S3, DynamoDB, and interface endpoints)
- DHCP options custom set
- DNS settings enabled
- Flow logs configuration

### 2. MINIMAL VPC (Quick Setup)
- Single public subnet only
- Basic internet gateway
- Minimal routing
- No NAT gateways
- No specialized subnet types

### 3. MULTIPLE AVAILABILITY ZONES
- Subnets across multiple AZs
- NAT gateway per AZ for resilience
- Proper routing across zones
- Route table isolation per AZ

### 4. PRIVATE SUBNETS ONLY (No IGW)
- Database subnets
- Application subnets
- No internet gateway
- NAT gateway for outbound traffic (optional)

### 5. CUSTOM ROUTE TABLES
- Custom routes to Transit Gateway
- Custom routes to VPN connections
- Per-subnet custom routing rules

### 6. VPC ENDPOINTS
- S3 gateway endpoint
- DynamoDB gateway endpoint
- Interface endpoints (EC2, SSM, RDS, etc.)
- Endpoint policy configuration

### 7. NETWORK ACLs
- Custom inbound/outbound rules
- Ephemeral port ranges
- Protocol-specific configurations

### 8. DHCP OPTIONS
- Custom domain name servers
- Custom domain name
- NTP servers

### 9. DNS CONFIGURATION
- DNS hostnames enabled
- DNS resolution enabled
- Private hosted zone associations

### 10. VPC FLOW LOGS
- CloudWatch Logs destinations
- S3 destinations
- Traffic monitoring and logging

### 11. NAT GATEWAY STRATEGIES
- One NAT gateway per AZ
- Single NAT gateway (all subnets use same NAT)
- No NAT gateway (private subnets with no internet access)

### 12. SECONDARY CIDR BLOCKS
- Multiple CIDR blocks on single VPC
- Secondary CIDR association

## Resource Types

AWS resources created by the module:

- `aws_vpc`
- `aws_subnet` (multiple types via separate logical groups)
- `aws_internet_gateway`
- `aws_nat_gateway`
- `aws_eip` (for NAT gateways)
- `aws_route_table`
- `aws_route`
- `aws_route_table_association`
- `aws_vpc_endpoint`
- `aws_vpc_endpoint_service_configuration`
- `aws_network_acl`
- `aws_network_acl_rule`
- `aws_dhcp_options`
- `aws_dhcp_options_association`
- `aws_vpc_dhcp_options_association`
- `aws_flow_log`
- `aws_cloudwatch_log_group`
- `aws_s3_bucket` (for flow logs)
- `aws_security_group` (basic for endpoints)

## Implementation Phases

### Phase 1: Core VPC Features (P0)
1. Basic VPC creation with CIDR
2. Public and private subnets across AZs
3. Internet Gateway
4. NAT Gateway (single and per-AZ strategies)
5. Basic routing

### Phase 2: Advanced Networking (P0)
1. Database, Elasticache, and Redshift subnets
2. Intra subnets (no internet access)
3. Custom route tables
4. Secondary CIDR blocks

### Phase 3: Enhanced Features (P1)
1. VPC Endpoints (S3, DynamoDB, interface)
2. Network ACLs
3. DHCP options
4. DNS configuration

### Phase 4: Monitoring and Advanced (P2)
1. VPC Flow Logs (CloudWatch and S3)
2. VPN Gateway integration
3. IPv6 support
4. Advanced tagging strategies

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

## Key Implementation Patterns

### 1. Conditional Resource Creation
- Resources created based on feature flags (enable_nat_gateway, create_igw, etc.)
- Subnet types only created when CIDR blocks provided

### 2. Looping and Counting
- Subnets created for each AZ using count/for_each
- NAT gateways created per AZ based on strategy
- Route tables created per subnet type

### 3. Dependencies and Relationships
- Subnets depend on VPC
- Route tables depend on gateways
- Routes depend on route tables
- Subnet associations depend on route tables

### 4. Dynamic Routing
- Public subnets route to IGW
- Private subnets route to NAT gateway
- Specialized subnets have isolated routing

### 5. Naming Conventions
- Resources named with pattern: `${var.name}-{type}-{az}`
- Consistent naming across regions/accounts

### 6. Default Values
- Sensible defaults for optional parameters
- Automatic AZ detection when not specified
- Default CIDR allocation patterns

### 7. Tagging Strategy
- Common tags merged with resource-specific tags
- Type-specific tags for resource categorization
- Name tags automatically generated

## Feature Coverage for Tests

The test suite validates:

1. **Resource Count Validation**: Correct number of resources created
2. **Output Value Verification**: All outputs populated correctly
3. **CIDR Block Assignment**: Subnets get correct CIDR allocations
4. **Routing Verification**: Routes properly configured
5. **Gateway Association**: Gateways properly associated
6. **Tag Application**: Tags applied correctly
7. **IPv6 Support**: IPv6 configuration when enabled
8. **Conditional Creation**: Resources only created when needed
9. **Cross-AZ High Availability**: Multi-AZ resilience
10. **Network Segmentation**: Proper isolation of subnets

## Special Considerations

1. **Region Handling**: Auto-detection of available AZs
2. **CIDR Math**: Automatic subnet CIDR calculation options
3. **High Availability**: Built-in HA patterns with NAT gateways
4. **Cost Optimization**: Single NAT gateway option for cost-sensitive deployments
5. **Security**: Network ACLs and proper routing isolation
6. **Monitoring**: Built-in Flow Logs integration
7. **Compliance**: DHCP customization for corporate requirements
8. **Scalability**: Support for secondary CIDR blocks

## Success Criteria

The implementation is successful when:

1. All Terraform inputs supported (minor capitalization differences acceptable)
2. All Terraform outputs provided
3. Behavior matches Terraform module exactly
4. Side-by-side validation tests pass
5. All 12 test case scenarios covered
6. Documentation complete
7. Package published to Upbound Marketplace

## References

- [Terraform AWS VPC Module Repository](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [Module Examples](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/master/examples)
- [Crossplane AWS Provider](https://marketplace.upbound.io/providers/upbound/provider-aws)
- [Upbound Documentation](https://docs.upbound.io/)
