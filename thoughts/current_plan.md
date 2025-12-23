# Implementation Plan: Comprehensive Example Configurations (Task 5.1)

## Overview
Create comprehensive example YAML configurations demonstrating all implemented features (NAT strategies, VPC endpoints, Network ACLs, DHCP options, Flow Logs, Subnet Groups, Secondary CIDRs). Currently only 4 basic examples exist; need 7+ production-ready examples with inline documentation.

## 1. Identify/Create Feature Specification

### 1.1 Review Current Examples
- **File**: `examples/simple-vpc.yaml` - Minimal VPC with public subnets only
- **File**: `examples/multi-subnet-vpc.yaml` - All 6 subnet types, no NAT/endpoints
- **File**: `examples/example.yaml` - Generic placeholder
- **File**: `examples/xr-simple-vpc.yaml` - Basic VPC

### 1.2 Define Required Examples (from TASKS.md Phase 5.1)
Each example must demonstrate specific feature combinations with inline comments:

1. **complete-vpc.yaml** - ALL implemented features enabled
   - VPC with primary + secondary CIDRs
   - All 6 subnet types across 3 AZs
   - NAT per AZ strategy
   - S3 + DynamoDB VPC endpoints
   - Network ACLs for public/private subnets
   - Custom DHCP options
   - Flow Logs to CloudWatch
   - All 3 subnet groups (RDS, ElastiCache, Redshift)
   - Comprehensive tagging

2. **private-only.yaml** - Private subnets with no IGW
   - Private and database subnets only
   - NAT Gateway for outbound access
   - No Internet Gateway
   - VPC endpoints for AWS services access
   - Database subnet group

3. **multi-az.yaml** - High availability configuration
   - 3 availability zones
   - NAT Gateway per AZ (high availability)
   - Public and private subnets
   - Separate route tables per AZ

4. **with-endpoints.yaml** - VPC endpoints showcase
   - S3 Gateway endpoint
   - DynamoDB Gateway endpoint
   - Endpoint-specific tags
   - Private subnets routing through endpoints

5. **with-flow-logs.yaml** - Flow Logs configurations
   - CloudWatch Logs destination example
   - S3 destination example (commented alternate)
   - Traffic filtering (ACCEPT/REJECT/ALL)
   - Custom aggregation interval
   - S3-specific options (Hive partitions, per-hour partition)

6. **nat-single.yaml** - Cost-optimized single NAT
   - Single NAT Gateway strategy
   - All private subnets share one NAT
   - Cost optimization notes

7. **nat-per-az.yaml** - High availability NAT
   - NAT Gateway per AZ strategy
   - Fault-tolerant design
   - High availability notes

### 1.3 Documentation Requirements for Each Example
- **Header comment**: Purpose and use case
- **Feature highlights**: What's demonstrated
- **Cost considerations**: Where applicable
- **Production notes**: Security/HA recommendations
- **Inline comments**: Explain key configuration choices
- **Related features**: Reference other examples

## 2. Develop Tests (Validation Only)

### 2.1 No New Tests Required
All features already have composition tests (32 tests passing):
- VPC creation (test-vpc-simple)
- All subnet types (6 tests)
- NAT strategies (3 tests)
- Routing (5 tests)
- VPC endpoints (3 tests)
- Network ACLs (2 tests)
- DHCP options (2 tests)
- Flow Logs (3 tests)
- Subnet Groups (3 tests)
- Secondary CIDRs (2 tests)

### 2.2 Validation Strategy
For each example created:
1. Syntax validation: `up project build`
2. Manual inspection: Review generated resources
3. Optional: Test locally with `kubectl apply -f examples/<name>.yaml`
4. Verify against XRD schema in `apis/vpc/definition.yaml`

## 3. Implementation Steps

### 3.1 Create complete-vpc.yaml
**File**: `examples/complete-vpc.yaml`
**Purpose**: Showcase ALL implemented features in single configuration

```yaml
# Header: Complete VPC with all features
# - All 6 subnet types
# - NAT per AZ (high availability)
# - VPC endpoints (S3, DynamoDB)
# - Network ACLs
# - DHCP options
# - Flow Logs
# - Subnet Groups
# - Secondary CIDR blocks
```

**Required fields**:
- region, cidr, secondaryCidrBlocks
- azs: 3 zones
- All subnet types: public, private, database, elasticache, redshift, intra
- createIgw: true
- enableNatGateway: true, oneNatGatewayPerAz: true
- enableS3Endpoint: true, enableDynamodbEndpoint: true
- publicDedicatedNetworkAcl: true with custom rules
- privateDedicatedNetworkAcl: true with custom rules
- enableDhcpOptions: true with custom DNS/NTP
- enableFlowLog: true, createFlowLogCloudwatchLogGroup: true
- createDatabaseSubnetGroup: true
- createElasticacheSubnetGroup: true
- createRedshiftSubnetGroup: true
- Comprehensive tags for all resources

### 3.2 Create private-only.yaml
**File**: `examples/private-only.yaml`
**Purpose**: Private subnets without direct internet access

```yaml
# Header: Private-only VPC
# - No Internet Gateway
# - Private and database subnets only
# - NAT Gateway for outbound access
# - VPC endpoints for AWS services
```

**Required fields**:
- region, cidr
- azs: 2 zones
- privateSubnets, databaseSubnets only (NO publicSubnets)
- createIgw: false
- enableNatGateway: true, singleNatGateway: true
- enableS3Endpoint: true, enableDynamodbEndpoint: true
- createDatabaseSubnetGroup: true
- createDatabaseSubnetRouteTable: true
- createDatabaseNatGatewayRoute: false (isolated database)

### 3.3 Create multi-az.yaml
**File**: `examples/multi-az.yaml`
**Purpose**: High availability across multiple availability zones

```yaml
# Header: Multi-AZ High Availability VPC
# - 3 availability zones
# - NAT Gateway per AZ (fault tolerance)
# - Separate route tables per AZ
```

**Required fields**:
- region, cidr
- azs: 3 zones
- publicSubnets, privateSubnets
- createIgw: true
- enableNatGateway: true, oneNatGatewayPerAz: true
- createDatabaseSubnetRouteTable: false (use shared routing)

### 3.4 Create with-endpoints.yaml
**File**: `examples/with-endpoints.yaml`
**Purpose**: Showcase VPC endpoints for private AWS service access

```yaml
# Header: VPC with VPC Endpoints
# - S3 Gateway endpoint
# - DynamoDB Gateway endpoint
# - Private subnet connectivity
```

**Required fields**:
- region, cidr
- azs: 2 zones
- publicSubnets, privateSubnets
- createIgw: true
- enableNatGateway: false
- enableS3Endpoint: true
- s3EndpointType: "Gateway"
- enableDynamodbEndpoint: true
- vpcEndpointTags with descriptive tags

### 3.5 Create with-flow-logs.yaml
**File**: `examples/with-flow-logs.yaml`
**Purpose**: VPC Flow Logs configuration examples

```yaml
# Header: VPC with Flow Logs
# - CloudWatch Logs destination
# - Traffic filtering options
# - S3 destination (commented alternate)
```

**Required fields**:
- region, cidr
- azs: 2 zones
- publicSubnets, privateSubnets
- createIgw: true
- enableFlowLog: true
- createFlowLogCloudwatchLogGroup: true
- flowLogTrafficType: "ALL"
- flowLogMaxAggregationInterval: 60
- Commented section showing S3 configuration:
  - createFlowLogS3Bucket: true
  - flowLogFileFormat: "parquet"
  - flowLogHiveCompatiblePartitions: true
  - flowLogPerHourPartition: true

### 3.6 Create nat-single.yaml
**File**: `examples/nat-single.yaml`
**Purpose**: Cost-optimized single NAT Gateway

```yaml
# Header: VPC with Single NAT Gateway
# - Cost optimization strategy
# - All private subnets share one NAT
# - Not fault-tolerant (note in comments)
```

**Required fields**:
- region, cidr
- azs: 3 zones
- publicSubnets, privateSubnets
- createIgw: true
- enableNatGateway: true
- singleNatGateway: true
- Cost note: "Single NAT saves ~$100/month vs NAT per AZ"
- HA note: "NAT failure affects all AZs"

### 3.7 Create nat-per-az.yaml
**File**: `examples/nat-per-az.yaml`
**Purpose**: High availability NAT configuration

```yaml
# Header: VPC with NAT Gateway per AZ
# - High availability strategy
# - One NAT per availability zone
# - Fault-tolerant design
```

**Required fields**:
- region, cidr
- azs: 3 zones
- publicSubnets, privateSubnets
- createIgw: true
- enableNatGateway: true
- oneNatGatewayPerAz: true
- HA note: "AZ failure isolated, other AZs unaffected"
- Cost note: "Higher cost (~$100/month per NAT)"

### 3.8 Update examples/README.md
**File**: `examples/README.md` (create if doesn't exist)

Structure:
```markdown
# VPC Configuration Examples

This directory contains comprehensive examples demonstrating all features.

## Quick Reference

| Example | Purpose | Features Demonstrated |
|---------|---------|----------------------|
| simple-vpc.yaml | Minimal VPC | Basic VPC, public subnets |
| complete-vpc.yaml | All features | Everything implemented |
| private-only.yaml | No public access | Private subnets, VPC endpoints |
| multi-az.yaml | High availability | Multi-AZ, NAT per AZ |
| with-endpoints.yaml | VPC Endpoints | S3, DynamoDB endpoints |
| with-flow-logs.yaml | Traffic monitoring | Flow Logs to CloudWatch/S3 |
| nat-single.yaml | Cost optimization | Single NAT strategy |
| nat-per-az.yaml | High availability | NAT per AZ strategy |

## Feature Coverage

All examples use features validated by 32 composition tests and 11 E2E tests.

### Core Features (✅ Production Ready)
- VPC creation with DNS settings
- All 6 subnet types: public, private, database, elasticache, redshift, intra
- Internet Gateway with conditional creation
- NAT Gateway: single NAT and NAT per AZ strategies
- Comprehensive routing for all subnet types
- VPC Endpoints: Gateway endpoints (S3, DynamoDB)
- Network ACLs: Public and private with custom rules
- DHCP Options: Custom DNS, NTP, NetBIOS settings
- VPC Flow Logs: CloudWatch and S3 destinations
- Subnet Groups: RDS, ElastiCache, Redshift
- Secondary CIDR Blocks: IP space expansion

### Coming Soon (📋 Planned)
- VPN Gateway (P1)
- IPv6 Support (P1)
- IPAM Integration (P1)
- Interface VPC Endpoints (P2)

## Using These Examples

1. Choose appropriate example
2. Customize parameters (region, CIDRs, AZs)
3. Update tags for your environment
4. Apply: `kubectl apply -f examples/<name>.yaml`
5. Monitor: `kubectl get xvpc <name> -w`

## Cost Considerations

- **Single NAT**: ~$32/month per NAT + data transfer
- **NAT per AZ**: ~$96/month for 3 AZs + data transfer
- **VPC Endpoints**: $0.01/hour per endpoint (~$7/month)
- **Flow Logs**: CloudWatch Logs or S3 storage costs

See individual examples for detailed cost notes.

## Support

All examples are tested with composition tests. For issues:
1. Verify XRD schema: `apis/vpc/definition.yaml`
2. Check test coverage: `tests/test-*`
3. Review implementation: `functions/vpc/*.k`
```

### 3.9 Update Main README.md Examples Section
**File**: `README.md`

Update "More Examples" section (line ~200):
```markdown
### More Examples

See the [examples/](examples/) directory for comprehensive examples:

**Basic Examples:**
- `simple-vpc.yaml` - Minimal VPC with public subnets
- `multi-subnet-vpc.yaml` - All subnet types across multiple AZs

**Feature Showcases:**
- `complete-vpc.yaml` - All implemented features (NAT, endpoints, ACLs, DHCP, Flow Logs, Subnet Groups, Secondary CIDRs)
- `with-endpoints.yaml` - VPC Endpoints for private AWS service access
- `with-flow-logs.yaml` - Traffic monitoring with VPC Flow Logs

**NAT Gateway Strategies:**
- `nat-single.yaml` - Single NAT Gateway (cost-optimized)
- `nat-per-az.yaml` - NAT Gateway per AZ (high availability)

**Advanced Configurations:**
- `private-only.yaml` - Private subnets without direct internet access
- `multi-az.yaml` - High availability across 3 availability zones

**Total**: 11 production-ready examples covering all implemented features.
```

### 3.10 Validation and Final Checks
For each created example:

1. **Syntax validation**:
   ```bash
   up project build
   ```

2. **Schema validation** against XRD:
   - Check all fields exist in `apis/vpc/definition.yaml`
   - Verify CIDR patterns, enum values
   - Confirm required fields present

3. **Completeness check**:
   - Inline comments explain configuration
   - Header describes use case
   - Cost/HA notes where appropriate
   - Tags demonstrate best practices

4. **Cross-reference check**:
   - Features match test coverage (32 tests)
   - Examples reference each other
   - README.md accurately describes examples

## Success Criteria

- ✅ 7 new comprehensive examples created (total 11 examples)
- ✅ Each example demonstrates specific feature set
- ✅ All examples have inline documentation
- ✅ `examples/README.md` created with feature matrix
- ✅ Main `README.md` updated with example references
- ✅ All examples validate against XRD schema
- ✅ Examples cover 100% of implemented features
- ✅ Cost and HA considerations documented
- ✅ No new tests required (features already tested)

## Files to Create/Modify

**Create (7 new examples)**:
1. `examples/complete-vpc.yaml`
2. `examples/private-only.yaml`
3. `examples/multi-az.yaml`
4. `examples/with-endpoints.yaml`
5. `examples/with-flow-logs.yaml`
6. `examples/nat-single.yaml`
7. `examples/nat-per-az.yaml`

**Create (documentation)**:
8. `examples/README.md`

**Modify (documentation update)**:
9. `README.md` - Update examples section

## Estimated Effort
- **Time**: 3-4 hours
- **Complexity**: Low (no new features, only documentation)
- **Risk**: Very low (examples don't affect implementation)

## Implementation Order
1. Create `complete-vpc.yaml` (reference for all features)
2. Create `nat-single.yaml` and `nat-per-az.yaml` (simple, focused)
3. Create `with-endpoints.yaml` (single feature showcase)
4. Create `with-flow-logs.yaml` (single feature showcase)
5. Create `private-only.yaml` (combination features)
6. Create `multi-az.yaml` (HA-focused)
7. Create `examples/README.md` (documentation)
8. Update main `README.md` (final step)
9. Validate all examples with `up project build`

## Notes
- All features are already implemented and tested (32 composition tests, 11 E2E tests)
- Examples serve as user-facing documentation
- No code changes required in functions/vpc/*.k
- Focus on clear documentation and inline comments
- Demonstrate best practices for tagging, naming, and configuration
