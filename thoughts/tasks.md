# Project Tasks: AWS VPC Configuration for Upbound

This document contains a prioritized list of all tasks needed to build an Upbound control plane project with feature parity to the [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

## Project Goal

Build a production-ready Upbound configuration package that provides the same functionality as the popular Terraform AWS VPC module, implemented using KCL composition functions and Crossplane managed resources.

## Task Priority Legend

- **P0**: Critical path items - project cannot proceed without these
- **P1**: Core functionality - essential features
- **P2**: Important features - significant value
- **P3**: Nice-to-have - optional enhancements

---

## Phase 1: Project Foundation (P0)

### 1.1 Initialize Upbound Project Structure ✅
**Priority**: P0
**Effort**: Small
**Description**: Set up the basic Upbound project structure using `up project init`
**Status**: COMPLETED

**Tasks**:
- [x] Run `up project init` to create project scaffold
- [x] Review and customize `upbound.yaml` manifest
- [x] Create directory structure: apis/, examples/, functions/
- [x] Initialize git repository (if not already done)
- [x] Create .gitignore file for KCL artifacts

**Acceptance Criteria**:
- ✅ Valid upbound.yaml exists
- ✅ Directory structure matches Upbound conventions
- ✅ Project builds successfully with `up project build`

---

### 1.2 Define XRD for VPC Composite Resource ✅
**Priority**: P0
**Effort**: Medium
**Description**: Create the XRD (Composite Resource Definition) that defines the API for our VPC configuration
**Status**: COMPLETED

**Tasks**:
- [x] Create `apis/vpc/definition.yaml` with XRD definition
- [x] Define input parameters matching Terraform module variables (see thoughts/spec/terraform-vpc-analysis.md)
- [x] Include required fields: name, cidrBlock, region, azs
- [x] Include optional fields for all VPC features
- [x] Define status fields for outputs (vpc_id, subnet_ids, etc.)
- [x] Add validation rules using OpenAPI schema
- [x] Document all fields with descriptions

**Reference**: thoughts/spec/terraform-vpc-analysis.md (Input Variables section)

**Acceptance Criteria**:
- ✅ XRD validates against Crossplane schema
- ✅ All Terraform module inputs have corresponding XRD fields
- ✅ Documentation is clear and comprehensive

**Notes**: See thoughts/tools/function-setup-notes.md for important learnings about dependencies.

---

### 1.3 Create Basic Composition Function Scaffold ✅
**Priority**: P0
**Effort**: Small
**Description**: Set up the KCL composition function structure
**Status**: COMPLETED

**Tasks**:
- [x] Create `functions/vpc/` directory using `up function generate`
- [x] Create `functions/vpc/main.k` with basic structure
- [x] Create `functions/vpc/kcl.mod` with dependencies
- [x] Set up imports for required models
- [x] Implement basic oxr/ocds parameter access
- [x] Create stub for items return

**Reference**: thoughts/coding/upbound-patterns.md (Entry Point Pattern)

**Acceptance Criteria**:
- ✅ Function structure follows Upbound patterns
- ✅ Can access XR parameters
- ✅ Returns empty items list successfully
- ✅ Project builds successfully

**IMPORTANT**: Used `up function generate vpc apis/vpc/composition.yaml --language kcl` instead of manual creation. See thoughts/tools/function-setup-notes.md for details.

---

## Phase 2: Core VPC Features (P1)

### 2.1 Implement Basic VPC Creation
**Priority**: P1
**Effort**: Medium
**Description**: Create the core VPC managed resource

**Tasks**:
- [ ] Create `functions/vpc/vpc.k` module
- [ ] Implement VPC resource generation function
- [ ] Support cidrBlock, region, enableDnsHostnames, enableDnsSupport
- [ ] Add proper metadata annotations
- [ ] Implement tag merging logic
- [ ] Test with minimal example

**AWS Resources**: `aws_vpc`

**Acceptance Criteria**:
- VPC created successfully in AWS
- DNS settings applied correctly
- Tags propagated properly

---

### 2.2 Implement Subnet Creation
**Priority**: P1
**Effort**: Large
**Description**: Create subnets across availability zones

**Tasks**:
- [ ] Create `functions/vpc/subnet.k` module
- [ ] Implement public subnet generation
- [ ] Implement private subnet generation
- [ ] Support database subnets
- [ ] Support elasticache subnets
- [ ] Support redshift subnets
- [ ] Support intra subnets (no internet access)
- [ ] Distribute subnets across AZs
- [ ] Implement CIDR block assignment
- [ ] Add mapPublicIpOnLaunch for public subnets

**AWS Resources**: `aws_subnet` (multiple types)

**Acceptance Criteria**:
- Subnets created in specified AZs
- CIDR blocks assigned correctly
- Subnet types differentiated properly
- All 6 subnet types supported

---

### 2.3 Implement Internet Gateway
**Priority**: P1
**Effort**: Small
**Description**: Create and attach Internet Gateway for public access

**Tasks**:
- [ ] Create `functions/vpc/gateway.k` module
- [ ] Implement IGW resource generation
- [ ] Attach IGW to VPC
- [ ] Make creation conditional (create_igw parameter)

**AWS Resources**: `aws_internet_gateway`

**Acceptance Criteria**:
- IGW created when public subnets exist
- Properly attached to VPC
- Conditional creation works

---

### 2.4 Implement NAT Gateway
**Priority**: P1
**Effort**: Medium
**Description**: Create NAT Gateways for private subnet internet access

**Tasks**:
- [ ] Add NAT Gateway resource generation to gateway.k
- [ ] Create Elastic IP for NAT Gateway
- [ ] Support three strategies:
  - [ ] Single NAT Gateway (all AZs use one)
  - [ ] One NAT Gateway per AZ
  - [ ] No NAT Gateway
- [ ] Place NAT Gateways in public subnets
- [ ] Make strategy configurable

**AWS Resources**: `aws_nat_gateway`, `aws_eip`

**Acceptance Criteria**:
- All three strategies work correctly
- NAT Gateways placed in public subnets
- EIPs allocated properly
- Cost-optimized single-NAT option available

---

### 2.5 Implement Route Tables and Routes
**Priority**: P1
**Effort**: Large
**Description**: Create route tables and routing rules for all subnet types

**Tasks**:
- [ ] Create `functions/vpc/route.k` module
- [ ] Implement public route table (routes to IGW)
- [ ] Implement private route tables (routes to NAT)
- [ ] Implement database route tables
- [ ] Implement elasticache route tables
- [ ] Implement redshift route tables
- [ ] Implement intra route tables (no external routes)
- [ ] Create route table associations for subnets
- [ ] Support per-AZ route tables
- [ ] Support custom routes

**AWS Resources**: `aws_route_table`, `aws_route`, `aws_route_table_association`

**Acceptance Criteria**:
- Public subnets route to IGW
- Private subnets route to NAT Gateway
- Specialized subnets have proper isolation
- Custom routes can be added
- Route table associations correct

---

## Phase 3: Enhanced Networking Features (P2)

### 3.1 Implement VPC Endpoints
**Priority**: P2
**Effort**: Large
**Description**: Add VPC endpoints for AWS services

**Tasks**:
- [ ] Create `functions/vpc/endpoints.k` module
- [ ] Implement S3 gateway endpoint
- [ ] Implement DynamoDB gateway endpoint
- [ ] Implement interface endpoints (EC2, SSM, RDS, etc.)
- [ ] Support endpoint policies
- [ ] Support endpoint security groups
- [ ] Make endpoints optional with feature flags

**AWS Resources**: `aws_vpc_endpoint`, `aws_security_group`

**Acceptance Criteria**:
- Gateway endpoints (S3, DynamoDB) work
- Interface endpoints can be created
- Endpoint policies applied
- Cost consideration documented

---

### 3.2 Implement Network ACLs
**Priority**: P2
**Effort**: Medium
**Description**: Add Network ACL support for subnet-level security

**Tasks**:
- [ ] Create `functions/vpc/nacl.k` module
- [ ] Implement NACL resource generation
- [ ] Support custom inbound rules
- [ ] Support custom outbound rules
- [ ] Support ephemeral port ranges
- [ ] Associate NACLs with subnets
- [ ] Provide sensible defaults

**AWS Resources**: `aws_network_acl`, `aws_network_acl_rule`

**Acceptance Criteria**:
- Custom NACL rules can be defined
- Rules applied to correct subnets
- Default rules are permissive

---

### 3.3 Implement DHCP Options
**Priority**: P2
**Effort**: Small
**Description**: Support custom DHCP options for the VPC

**Tasks**:
- [ ] Create `functions/vpc/dhcp.k` module
- [ ] Implement DHCP options set
- [ ] Support custom DNS servers
- [ ] Support custom domain name
- [ ] Support NTP servers
- [ ] Support NetBIOS settings
- [ ] Associate DHCP options with VPC

**AWS Resources**: `aws_dhcp_options`, `aws_dhcp_options_association`

**Acceptance Criteria**:
- Custom DNS servers configurable
- Domain name can be set
- Options associated with VPC correctly

---

### 3.4 Implement VPC Flow Logs
**Priority**: P2
**Effort**: Medium
**Description**: Add VPC Flow Logs for traffic monitoring

**Tasks**:
- [ ] Create `functions/vpc/flowlogs.k` module
- [ ] Support CloudWatch Logs destination
- [ ] Support S3 bucket destination
- [ ] Configure traffic type (All/Accept/Reject)
- [ ] Set aggregation interval
- [ ] Create necessary IAM roles
- [ ] Create log groups/buckets as needed

**AWS Resources**: `aws_flow_log`, `aws_cloudwatch_log_group`, `aws_s3_bucket`, `aws_iam_role`

**Acceptance Criteria**:
- Flow logs to CloudWatch work
- Flow logs to S3 work
- Traffic filtering works
- IAM permissions correct

---

### 3.5 Support Secondary CIDR Blocks
**Priority**: P2
**Effort**: Small
**Description**: Allow multiple CIDR blocks on a single VPC

**Tasks**:
- [ ] Extend vpc.k to support secondary CIDRs
- [ ] Implement CIDR block association
- [ ] Support subnets from secondary CIDRs
- [ ] Update routing logic

**AWS Resources**: `aws_vpc_ipv4_cidr_block_association`

**Acceptance Criteria**:
- Multiple CIDRs can be added
- Subnets can use any CIDR block
- Routing works across all CIDRs

---

## Phase 4: Advanced Features (P2)

### 4.1 Implement VPN Gateway Support
**Priority**: P2
**Effort**: Medium
**Description**: Add VPN Gateway for hybrid cloud connectivity

**Tasks**:
- [ ] Create `functions/vpc/vpn.k` module
- [ ] Implement VPN Gateway resource
- [ ] Attach to VPC
- [ ] Support propagation to route tables
- [ ] Make optional with feature flag

**AWS Resources**: `aws_vpn_gateway`, `aws_vpn_gateway_attachment`

**Acceptance Criteria**:
- VPN Gateway created when enabled
- Attached to VPC correctly
- Routes propagated to tables

---

### 4.2 Implement IPv6 Support
**Priority**: P2
**Effort**: Large
**Description**: Add IPv6 support for VPC and subnets

**Tasks**:
- [ ] Extend vpc.k for IPv6 CIDR association
- [ ] Support IPv6 CIDR blocks for subnets
- [ ] Update route tables for IPv6
- [ ] Support egress-only internet gateway
- [ ] Enable DNS64 when configured

**AWS Resources**: `aws_vpc_ipv6_cidr_block_association`, `aws_egress_only_internet_gateway`

**Acceptance Criteria**:
- IPv6 CIDR can be enabled
- IPv6 subnets created
- IPv6 routing works
- Dual-stack configuration supported

---

## Phase 5: Testing and Validation (P1)

### 5.1 Create Example Configurations
**Priority**: P1
**Effort**: Medium
**Description**: Create comprehensive examples matching Terraform module test cases

**Tasks**:
- [ ] Create `examples/simple-vpc.yaml` - Minimal VPC
- [ ] Create `examples/complete-vpc.yaml` - All features
- [ ] Create `examples/private-only.yaml` - No IGW
- [ ] Create `examples/multi-az.yaml` - Multiple AZs
- [ ] Create `examples/with-endpoints.yaml` - VPC endpoints
- [ ] Create `examples/with-flow-logs.yaml` - Flow logs enabled
- [ ] Document each example thoroughly

**Reference**: thoughts/spec/terraform-vpc-analysis.md (Test Cases section)

**Acceptance Criteria**:
- All major use cases covered
- Examples match Terraform module examples
- Documentation clear and helpful

---

### 5.2 Implement Automated Tests
**Priority**: P1
**Effort**: Large
**Description**: Create test suite using `up test`

**Tasks**:
- [ ] Create test configurations in `tests/` directory
- [ ] Test basic VPC creation
- [ ] Test all subnet types
- [ ] Test NAT Gateway strategies
- [ ] Test conditional resource creation
- [ ] Test outputs are populated
- [ ] Test with different regions/AZs
- [ ] Test deletion and cleanup

**Acceptance Criteria**:
- All tests pass with `up test run`
- Edge cases covered
- Cleanup verified

---

### 5.3 Validate Feature Parity
**Priority**: P1
**Effort**: Medium
**Description**: Ensure all Terraform module features are implemented

**Tasks**:
- [ ] Create feature comparison checklist
- [ ] Verify all inputs supported
- [ ] Verify all outputs available
- [ ] Test each feature against Terraform behavior
- [ ] Document any intentional differences

**Reference**: thoughts/spec/terraform-vpc-analysis.md (complete feature list)

**Acceptance Criteria**:
- Feature parity achieved (or documented gaps)
- Behavior matches Terraform module
- Outputs match expected values

---

## Phase 6: Documentation and Polish (P1)

### 6.1 Write Comprehensive README
**Priority**: P1
**Effort**: Medium
**Description**: Create user-facing documentation

**Tasks**:
- [ ] Document project purpose and goals
- [ ] Add installation instructions
- [ ] Document all input parameters
- [ ] Document all outputs
- [ ] Provide usage examples
- [ ] Add troubleshooting section
- [ ] Document differences from Terraform module
- [ ] Add architecture diagrams

**Acceptance Criteria**:
- Users can get started quickly
- All features documented
- Examples are clear

---

### 6.2 Add API Documentation
**Priority**: P1
**Effort**: Small
**Description**: Generate API reference documentation

**Tasks**:
- [ ] Document XRD fields thoroughly
- [ ] Add examples for each parameter
- [ ] Document validation rules
- [ ] Document default values
- [ ] Create API reference page

**Acceptance Criteria**:
- API fully documented
- Examples for complex scenarios
- Validation rules clear

---

### 6.3 Create Contribution Guidelines
**Priority**: P3
**Effort**: Small
**Description**: Help others contribute to the project

**Tasks**:
- [ ] Create CONTRIBUTING.md
- [ ] Document development workflow
- [ ] Explain testing process
- [ ] Set up PR template
- [ ] Document code style expectations

**Acceptance Criteria**:
- Contributors know how to help
- Standards clearly communicated

---

## Phase 7: Optimization and Performance (P2)

### 7.1 Optimize Resource Creation
**Priority**: P2
**Effort**: Medium
**Description**: Ensure efficient resource composition

**Tasks**:
- [ ] Review composition for unnecessary dependencies
- [ ] Optimize conditional logic
- [ ] Minimize status field usage
- [ ] Review for parallel resource creation
- [ ] Profile composition performance

**Acceptance Criteria**:
- Resources created in minimal time
- No unnecessary serialization
- Composition runs efficiently

---

### 7.2 Implement Status Conditions
**Priority**: P2
**Effort**: Small
**Description**: Provide detailed status information

**Tasks**:
- [ ] Add Ready condition
- [ ] Add Synced condition
- [ ] Add resource-specific conditions
- [ ] Implement status messages
- [ ] Document status meanings

**Acceptance Criteria**:
- Users can monitor deployment progress
- Error conditions clear
- Status reflects actual state

---

## Phase 8: Advanced Scenarios (P3)

### 8.1 Support Transit Gateway Integration
**Priority**: P3
**Effort**: Large
**Description**: Allow VPCs to connect via Transit Gateway

**Tasks**:
- [ ] Add Transit Gateway attachment support
- [ ] Update routing for TGW routes
- [ ] Support TGW route table associations
- [ ] Document TGW integration patterns

**AWS Resources**: `aws_ec2_transit_gateway_vpc_attachment`

**Acceptance Criteria**:
- VPC can attach to TGW
- Routes properly configured
- Multi-VPC scenarios work

---

### 8.2 Support VPC Peering
**Priority**: P3
**Effort**: Medium
**Description**: Enable VPC-to-VPC peering

**Tasks**:
- [ ] Add peering connection resource
- [ ] Support peering routes
- [ ] Handle cross-account peering
- [ ] Document peering setup

**AWS Resources**: `aws_vpc_peering_connection`

**Acceptance Criteria**:
- Peering connections established
- Routes work across peered VPCs
- Cross-account supported

---

### 8.3 Add Cost Estimation
**Priority**: P3
**Effort**: Small
**Description**: Help users understand cost implications

**Tasks**:
- [ ] Document cost of NAT Gateways
- [ ] Document VPC endpoint costs
- [ ] Provide cost optimization tips
- [ ] Add cost tags to resources

**Acceptance Criteria**:
- Users aware of costs
- Optimization strategies documented

---

## Phase 9: CI/CD and Publishing (P1)

### 9.1 Set Up CI/CD Pipeline
**Priority**: P1
**Effort**: Medium
**Description**: Automate testing and publishing

**Tasks**:
- [ ] Set up GitHub Actions (or equivalent)
- [ ] Automate testing on PRs
- [ ] Automate package building
- [ ] Automate version bumping
- [ ] Configure automated publishing

**Acceptance Criteria**:
- Tests run automatically
- Packages built on release
- Publishing automated

---

### 9.2 Publish to Upbound Marketplace
**Priority**: P1
**Effort**: Small
**Description**: Make package available publicly

**Tasks**:
- [ ] Create Upbound Marketplace account
- [ ] Configure package metadata
- [ ] Publish initial version
- [ ] Add package description and tags
- [ ] Monitor for issues

**Acceptance Criteria**:
- Package available in marketplace
- Users can install easily
- Package metadata complete

---

## Quick Start Checklist

For someone picking up this project, start with these tasks in order:

1. **Set up project** (1.1)
2. **Define XRD** (1.2)
3. **Create function scaffold** (1.3)
4. **Implement VPC** (2.1)
5. **Implement subnets** (2.2)
6. **Implement gateways** (2.3, 2.4)
7. **Implement routing** (2.5)
8. **Create examples** (5.1)
9. **Test thoroughly** (5.2, 5.3)
10. **Document** (6.1, 6.2)

## Dependencies Between Tasks

```
1.1 → 1.2 → 1.3 → 2.1
              ↓
2.1 → 2.2 → 2.3 → 2.4 → 2.5
              ↓     ↓
              ↓     3.1
              ↓
              5.1 → 5.2 → 5.3
                           ↓
                          6.1 → 6.2 → 9.1 → 9.2
```

## Estimated Timeline

- **Phase 1 (Foundation)**: 1-2 days
- **Phase 2 (Core VPC)**: 5-7 days
- **Phase 3 (Enhanced Features)**: 5-7 days
- **Phase 4 (Advanced Features)**: 3-4 days
- **Phase 5 (Testing)**: 3-4 days
- **Phase 6 (Documentation)**: 2-3 days
- **Phase 7 (Optimization)**: 2-3 days
- **Phase 8 (Advanced Scenarios)**: Optional, 3-5 days
- **Phase 9 (CI/CD)**: 1-2 days

**Total Estimated Time**: 22-30 days (core features only)

## Current Status

Project is at the planning stage. All foundational research has been completed:
- ✅ Terraform module analysis complete
- ✅ Upbound patterns documented
- ✅ KCL language guide created
- ✅ up-cli reference available
- ✅ Git operations documented

Ready to begin Phase 1 implementation.

---

**Note**: This task list should be updated as the project progresses. Mark tasks as complete, add new tasks as needed, and adjust priorities based on feedback and requirements.
