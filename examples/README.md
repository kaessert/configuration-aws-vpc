# VPC Configuration Examples

This directory contains comprehensive examples demonstrating all features of the Upbound VPC composition. Each example is production-ready with inline documentation explaining configuration choices, cost considerations, and use cases.

## Quick Reference

| Example | Purpose | Key Features | Use Case |
|---------|---------|--------------|----------|
| **simple-vpc.yaml** | Minimal VPC | Basic VPC with public subnets | Getting started, simple workloads |
| **multi-subnet-vpc.yaml** | Multiple subnet types | All 6 subnet types across AZs | Demonstrating subnet variety |
| **complete-vpc.yaml** | ⭐ All features | Everything implemented | Reference implementation |
| **nat-single.yaml** | Cost optimization | Single NAT Gateway shared | Dev/test environments |
| **nat-per-az.yaml** | High availability | NAT Gateway per AZ | Production workloads |
| **with-endpoints.yaml** | VPC Endpoints | S3 and DynamoDB endpoints | Cost optimization for AWS services |
| **with-flow-logs.yaml** | Traffic monitoring | VPC Flow Logs to CloudWatch/S3 | Security, compliance, troubleshooting |
| **private-only.yaml** | Maximum security | No Internet Gateway | High-security/compliance requirements |
| **multi-az.yaml** | Fault tolerance | 3 AZ distribution | Mission-critical applications |

## Feature Coverage

All examples demonstrate features that are fully implemented and tested with 32 composition tests and 11 E2E tests.

### Core VPC Features ✅

#### Network Foundation
- **VPC Creation** with customizable CIDR blocks
- **Secondary CIDR Blocks** for IP address space expansion
- **DNS Configuration** (hostnames, resolution, DNS64)
- **Multiple Availability Zones** for high availability

#### Subnet Types (All 6 Supported)
- **Public Subnets** - Internet-facing resources (IGW routing)
- **Private Subnets** - Application servers (NAT Gateway routing)
- **Database Subnets** - RDS instances (isolated or NAT routing)
- **ElastiCache Subnets** - Redis/Memcached clusters
- **Redshift Subnets** - Data warehouse clusters
- **Intra Subnets** - Completely isolated (no internet access)

#### Internet Connectivity
- **Internet Gateway** - Conditional creation for public subnets
- **NAT Gateway** - Two strategies:
  - Single NAT Gateway (cost-optimized)
  - NAT Gateway per AZ (high availability)
- **Route Tables** - Automatic configuration for all subnet types

#### AWS Service Access
- **VPC Endpoints** - Private access to AWS services:
  - S3 Gateway Endpoint (FREE)
  - DynamoDB Gateway Endpoint (FREE)
  - Configurable endpoint policies

#### Security
- **Network ACLs** - Stateless firewall rules:
  - Public subnet ACLs with custom rules
  - Private subnet ACLs with custom rules
  - Flexible inbound/outbound rule configuration
- **DHCP Options** - Custom DNS, NTP, NetBIOS configuration

#### Monitoring & Compliance
- **VPC Flow Logs** - Traffic capture and analysis:
  - CloudWatch Logs destination
  - S3 destination with Parquet format
  - Traffic filtering (ALL/ACCEPT/REJECT)
  - Custom aggregation intervals (60s/600s)
  - Hive-compatible partitions for Athena

#### Database Services
- **Subnet Groups** for AWS managed services:
  - RDS Database Subnet Group
  - ElastiCache Subnet Group
  - Redshift Subnet Group
  - Custom naming and tagging

#### Resource Management
- **Comprehensive Tagging** - Multiple tag levels:
  - Global tags (all resources)
  - VPC-specific tags
  - Per-subnet-type tags
  - Service-specific tags (endpoints, ACLs, subnet groups)

### Upcoming Features 📋

The following features are planned but not yet implemented:

**Priority 1 (P1) - High Impact**
- VPN Gateway for site-to-site connectivity
- IPv6 Support (dual-stack VPCs)
- IPAM Integration for automated IP management

**Priority 2 (P2) - Medium Impact**
- Interface VPC Endpoints for additional AWS services
- Transit Gateway attachments
- VPC Peering connections

**Priority 3 (P3) - Future Enhancements**
- Network Firewall integration
- PrivateLink endpoint services
- IPv6 Egress-only Internet Gateway

## Example Details

### Basic Examples

#### simple-vpc.yaml
Minimal VPC configuration for getting started. Demonstrates:
- Single CIDR block VPC
- Public subnets across 2 AZs
- Internet Gateway
- Basic tagging

**When to use**: Learning, simple workloads, proof of concept

#### multi-subnet-vpc.yaml
Demonstrates all 6 subnet types without additional features. Shows:
- Public, private, database, elasticache, redshift, and intra subnets
- Multiple availability zones
- Subnet type organization

**When to use**: Understanding subnet types, planning complex networks

### Feature Showcase Examples

#### complete-vpc.yaml ⭐
**THE comprehensive reference** showing ALL implemented features:
- Primary + secondary CIDR blocks
- All 6 subnet types across 3 AZs
- NAT Gateway per AZ
- VPC endpoints (S3, DynamoDB)
- Network ACLs with custom rules
- Custom DHCP options
- VPC Flow Logs to CloudWatch
- All 3 subnet groups
- Comprehensive tagging strategy

**When to use**: Reference for all capabilities, production template

**Cost**: ~$110/month (3 NAT Gateways + 2 endpoints + Flow Logs)

#### with-endpoints.yaml
Focus on VPC endpoints for private AWS service access:
- S3 Gateway endpoint (FREE)
- DynamoDB Gateway endpoint (FREE)
- Private subnet configuration
- No NAT Gateway needed for these services

**When to use**: Cost optimization for S3/DynamoDB access, security compliance

**Cost**: $0 for Gateway endpoints

**Savings**: Eliminates NAT Gateway data transfer charges for S3/DynamoDB

#### with-flow-logs.yaml
Comprehensive Flow Logs configuration:
- CloudWatch Logs destination (shown)
- S3 destination with Parquet format (documented)
- Traffic filtering options
- Aggregation intervals
- Example queries for CloudWatch Insights and Athena

**When to use**: Security monitoring, compliance, troubleshooting, cost analysis

**Cost**: ~$10-50/month depending on traffic volume

### NAT Gateway Strategy Examples

#### nat-single.yaml
Cost-optimized single NAT Gateway:
- One NAT Gateway shared across all AZs
- All private subnets route through single NAT
- Lower cost but single point of failure

**When to use**: Development, staging, cost-sensitive non-critical workloads

**Cost**: ~$32/month + data transfer

**Savings**: ~$64-96/month vs NAT per AZ

**Trade-off**: AZ failure affects all private subnet internet access

#### nat-per-az.yaml
High availability NAT Gateway configuration:
- One NAT Gateway per availability zone
- Fault isolation per AZ
- No cross-AZ data transfer for NAT traffic

**When to use**: Production, mission-critical workloads

**Cost**: ~$96/month (3 AZs) + data transfer

**Benefit**: 99.99% availability, fault isolation, better performance

### Advanced Configuration Examples

#### private-only.yaml
Maximum security configuration without Internet Gateway:
- No direct internet access (no IGW)
- Private and database subnets only
- VPC endpoints for AWS service access
- Database tier completely isolated

**When to use**: High-security environments, PCI DSS, HIPAA, financial services

**Access**: Requires VPN Gateway or Direct Connect (not shown)

**Cost**: ~$32/month (single NAT) + VPC endpoint charges

#### multi-az.yaml
High availability across 3 availability zones:
- Comprehensive HA design
- NAT Gateway per AZ
- Separate route tables per AZ
- Fault isolation documentation
- Deployment best practices

**When to use**: Mission-critical applications, 99.99% availability requirements

**Cost**: ~$96/month (3 NAT Gateways)

**Availability**: 99.99% (3 AZs) vs 99.95% (2 AZs) vs 99.5% (1 AZ)

## Using These Examples

### 1. Choose the Right Example

**For learning**: Start with `simple-vpc.yaml`

**For production**: Use `complete-vpc.yaml` as template, customize as needed

**For specific features**: Use feature-specific examples as reference

**For cost optimization**: Compare `nat-single.yaml` vs `nat-per-az.yaml`

### 2. Customize for Your Environment

Required changes:
```yaml
# Update region to your preferred AWS region
region: us-west-2  # Change to your region

# Update availability zones (must match your region)
azs:
  - us-west-2a  # Change to your region's AZs
  - us-west-2b

# Update CIDR blocks (avoid conflicts with existing networks)
cidr: 10.0.0.0/16  # Change to your IP range
publicSubnets:
  - 10.0.0.0/24  # Adjust subnet sizes as needed
```

Update tags:
```yaml
tags:
  Environment: production  # Your environment
  ManagedBy: crossplane
  Team: platform  # Your team
  CostCenter: engineering  # Your cost center
```

### 3. Apply the Configuration

```bash
# Validate syntax
kubectl apply --dry-run=client -f examples/complete-vpc.yaml

# Apply configuration
kubectl apply -f examples/complete-vpc.yaml

# Monitor creation
kubectl get vpc complete-vpc -w

# Check status
kubectl describe vpc complete-vpc
```

### 4. Verify Resources

```bash
# Get VPC ID from status
kubectl get vpc complete-vpc -o jsonpath='{.status.vpcId}'

# Get subnet IDs
kubectl get vpc complete-vpc -o jsonpath='{.status.publicSubnets[*]}'

# View all outputs
kubectl get vpc complete-vpc -o yaml | grep -A 100 status:
```

## Cost Estimation

### VPC Resources (FREE)
- VPC
- Subnets
- Route tables
- Internet Gateway
- Security groups
- Network ACLs

### Billable Resources

| Resource | Cost | Notes |
|----------|------|-------|
| NAT Gateway | $0.045/hour (~$32/month) | Per NAT Gateway + data transfer |
| VPC Endpoints (Interface) | $0.01/hour (~$7/month) | Per endpoint per AZ |
| VPC Endpoints (Gateway) | FREE | S3 and DynamoDB only |
| Flow Logs (CloudWatch) | $0.50/GB ingested | + $0.03/GB/month storage |
| Flow Logs (S3) | $0.023/GB/month | Storage only, cheaper long-term |
| Data Transfer | Varies | NAT Gateway, cross-AZ, internet egress |

### Example Configurations Cost

| Example | Monthly Cost | What's Included |
|---------|--------------|-----------------|
| simple-vpc.yaml | $0 | Public subnets only, no NAT |
| nat-single.yaml | ~$32 | 1 NAT Gateway |
| nat-per-az.yaml | ~$96 | 3 NAT Gateways |
| with-endpoints.yaml | $0 | Gateway endpoints are free |
| with-flow-logs.yaml | ~$10-50 | Depends on traffic volume |
| complete-vpc.yaml | ~$110 | 3 NAT + endpoints + Flow Logs |

**Note**: Data transfer charges are not included and vary by usage.

## Testing

All features in these examples are covered by:
- **32 composition tests** - Unit tests for each feature
- **11 E2E tests** - End-to-end validation

To run tests:
```bash
# All composition tests
up project test

# Specific test
up project test test-vpc-nat-single
```

## Troubleshooting

### Common Issues

**VPC not creating**
```bash
# Check events
kubectl describe vpc <vpc-name>

# Check managed resources
kubectl get managed

# View composition details
kubectl get composite
```

**Invalid CIDR block**
- Ensure CIDR follows pattern: X.X.X.X/X (e.g., 10.0.0.0/16)
- Verify no overlap with existing VPCs
- Check secondary CIDRs are non-overlapping

**Availability zone errors**
- AZ names must match your region
- Not all AZs support all instance types
- Use `aws ec2 describe-availability-zones` to list valid AZs

**NAT Gateway issues**
- Requires public subnet to exist
- Requires Internet Gateway
- Check EIP allocation limits

**VPC endpoint errors**
- S3 and DynamoDB use Gateway endpoints (free)
- Other services require Interface endpoints
- Verify endpoint service available in your region

### Getting Help

1. **Check XRD schema**: `apis/vpc/definition.yaml`
2. **Review tests**: `tests/test-*.yaml`
3. **Examine composition**: `functions/vpc/*.k`
4. **AWS documentation**: [VPC User Guide](https://docs.aws.amazon.com/vpc/)

## Best Practices

### Security
- ✅ Use Network ACLs for additional security layer
- ✅ Isolate database subnets (no NAT routing)
- ✅ Enable VPC Flow Logs for audit trails
- ✅ Use VPC endpoints to avoid internet routing
- ✅ Apply least-privilege IAM policies

### High Availability
- ✅ Use 3 availability zones for 99.99% availability
- ✅ Deploy NAT Gateway per AZ
- ✅ Distribute subnets evenly across AZs
- ✅ Use Multi-AZ for RDS and other services
- ✅ Enable cross-zone load balancing

### Cost Optimization
- ✅ Use Gateway endpoints (S3, DynamoDB) - they're free
- ✅ Consider single NAT Gateway for non-production
- ✅ Use S3 for long-term Flow Logs storage
- ✅ Right-size CIDR blocks to avoid waste
- ✅ Tag resources for cost allocation

### Operations
- ✅ Use descriptive names and comprehensive tags
- ✅ Document CIDR allocation strategy
- ✅ Enable Flow Logs for troubleshooting
- ✅ Plan for IP address growth (secondary CIDRs)
- ✅ Implement monitoring and alerting

### Compliance
- ✅ Enable Flow Logs for audit requirements
- ✅ Use Network ACLs for defense in depth
- ✅ Isolate sensitive workloads (intra subnets)
- ✅ Document network architecture
- ✅ Regular security reviews

## Related Resources

- **API Reference**: `apis/vpc/definition.yaml` - Complete XRD schema
- **Implementation**: `functions/vpc/*.k` - KCL composition functions
- **Tests**: `tests/` - Composition and E2E tests
- **Main README**: `README.md` - Project overview and quick start
- **AWS Documentation**: [Amazon VPC Documentation](https://docs.aws.amazon.com/vpc/)

## Contributing

To add new examples:

1. Follow existing example structure
2. Include comprehensive inline comments
3. Document cost implications
4. Explain use cases and trade-offs
5. Add entry to this README
6. Ensure features are tested (see `tests/` directory)

## Support

For issues or questions:
- Check existing examples for reference
- Review XRD schema for available options
- Examine composition tests for feature usage
- Refer to AWS VPC documentation
