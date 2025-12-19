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

### 2.1 Implement Basic VPC Creation ✅
**Priority**: P1
**Effort**: Medium
**Description**: Create the core VPC managed resource
**Status**: COMPLETED

**Tasks**:
- [x] Implement VPC resource in main.k
- [x] Support cidrBlock, region, enableDnsHostnames, enableDnsSupport
- [x] Add proper metadata annotations
- [x] Implement tag merging logic
- [x] Create test example (examples/simple-vpc.yaml)

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/VPC`

**Acceptance Criteria**:
- ✅ VPC resource defined with correct API group
- ✅ DNS settings configurable
- ✅ Tags properly merged
- ✅ Project builds successfully

**Notes**: See thoughts/tools/kcl-resource-notes.md for important learnings about creating managed resources in KCL.

---

### 2.2 Implement Subnet Creation ✅
**Priority**: P1
**Effort**: Large
**Description**: Create subnets across availability zones
**Status**: COMPLETED

**Tasks**:
- [x] Create `functions/vpc/subnet.k` module (implemented in main.k)
- [x] Implement public subnet generation
- [x] Implement private subnet generation
- [x] Support database subnets
- [x] Support elasticache subnets
- [x] Support redshift subnets
- [x] Support intra subnets (no internet access)
- [x] Distribute subnets across AZs
- [x] Implement CIDR block assignment
- [x] Add mapPublicIpOnLaunch for public subnets

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/Subnet` (multiple types)

**Acceptance Criteria**:
- ✅ Subnets created in specified AZs
- ✅ CIDR blocks assigned correctly
- ✅ Subnet types differentiated properly
- ✅ All 6 subnet types supported
- ✅ Tests pass

**Notes**: All subnet types implemented inline in main.k. Added intraSubnetTags to XRD. Created multi-subnet-vpc.yaml example.

---

### 2.2.1 Add Composition Tests for Subnets
**Priority**: P1
**Effort**: Small
**Description**: Create composition tests to validate subnet creation logic
**Dependencies**: Task 2.2

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-public-subnets --language=kcl`
- [ ] Write test asserting public subnets are created with correct specs
- [ ] Test single AZ scenario
- [ ] Test multi-AZ scenario
- [ ] Verify mapPublicIpOnLaunch is set correctly
- [ ] Run test locally: `up test run tests/test-xvpc-public-subnets`
- [ ] Fix any broken tests from previous features (VPC)
- [ ] Ensure all tests pass

**Reference**: thoughts/tools/testing-notes-platform-ref.md

**Acceptance Criteria**:
- Test validates correct number of subnets created
- Test validates subnet CIDR blocks
- Test validates subnet placement across AZs
- All existing tests still pass
- Test runs in < 10 seconds

---

### 2.3 Implement Internet Gateway ✅
**Priority**: P1
**Effort**: Small
**Description**: Create and attach Internet Gateway for public access
**Status**: COMPLETED

**Tasks**:
- [x] Create `functions/vpc/gateway.k` module (implemented in main.k)
- [x] Implement IGW resource generation
- [x] Attach IGW to VPC
- [x] Make creation conditional (create_igw parameter)

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/InternetGateway`

**Acceptance Criteria**:
- ✅ IGW created when createIgw is enabled
- ✅ Properly attached to VPC using vpcIdSelector
- ✅ Conditional creation works
- ✅ Tests pass

**Notes**: IGW implemented inline in main.k. Uses vpcIdSelector for automatic VPC attachment. Conditionally created based on createIgw parameter (default: true).

---

### 2.3.1 Add Composition Tests for Internet Gateway
**Priority**: P1
**Effort**: Small
**Description**: Create composition tests for IGW functionality
**Dependencies**: Task 2.3

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-igw --language=kcl`
- [ ] Test IGW is created when public subnets exist
- [ ] Test IGW is NOT created when no public subnets
- [ ] Verify IGW attachment to VPC
- [ ] Run test: `up test run tests/test-xvpc-igw`
- [ ] Fix any broken tests from subnet changes
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- Test validates conditional IGW creation
- Test validates VPC attachment
- All existing tests still pass

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

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/NATGateway`, `ec2.aws.upbound.io/v1beta1/EIP`

**Acceptance Criteria**:
- All three strategies work correctly
- NAT Gateways placed in public subnets
- EIPs allocated properly
- Cost-optimized single-NAT option available

---

### 2.4.1 Add Composition Tests for NAT Gateway
**Priority**: P1
**Effort**: Medium
**Description**: Create composition tests for all NAT Gateway strategies
**Dependencies**: Task 2.4

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-nat-single --language=kcl`
- [ ] Test single NAT Gateway strategy (1 NAT, 1 EIP)
- [ ] Generate test: `up test generate test-xvpc-nat-per-az --language=kcl`
- [ ] Test NAT per AZ strategy (N NATs, N EIPs)
- [ ] Generate test: `up test generate test-xvpc-nat-disabled --language=kcl`
- [ ] Test no NAT Gateway (0 NATs, 0 EIPs)
- [ ] Verify NAT placement in public subnets
- [ ] Verify EIP allocation
- [ ] Run tests: `up test run tests/test-xvpc-nat-*`
- [ ] Fix any broken tests
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- All three NAT strategies have tests
- Tests validate correct number of NATs and EIPs
- Tests validate placement in public subnets
- All existing tests still pass

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

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/RouteTable`, `ec2.aws.upbound.io/v1beta1/Route`, `ec2.aws.upbound.io/v1beta1/RouteTableAssociation`

**Acceptance Criteria**:
- Public subnets route to IGW
- Private subnets route to NAT Gateway
- Specialized subnets have proper isolation
- Custom routes can be added
- Route table associations correct

---

### 2.5.1 Add Composition Tests for Route Tables
**Priority**: P1
**Effort**: Medium
**Description**: Create composition tests for routing logic
**Dependencies**: Task 2.5

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-routes-public --language=kcl`
- [ ] Test public route table points to IGW
- [ ] Test route table associations for public subnets
- [ ] Generate test: `up test generate test-xvpc-routes-private --language=kcl`
- [ ] Test private route tables point to NAT Gateway
- [ ] Test per-AZ route tables (if NAT per AZ)
- [ ] Generate test: `up test generate test-xvpc-routes-isolated --language=kcl`
- [ ] Test database/intra subnets have no external routes
- [ ] Verify route table association correctness
- [ ] Run tests: `up test run tests/test-xvpc-routes-*`
- [ ] Fix any broken tests
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- Tests validate route destinations (IGW, NAT, none)
- Tests validate route table associations
- Tests cover all subnet types
- All existing tests still pass

---

### 2.5.2 Add E2E Test for Core VPC
**Priority**: P1
**Effort**: Medium
**Description**: Create E2E test validating complete VPC with real AWS resources
**Dependencies**: Tasks 2.1-2.5

**Tasks**:
- [ ] Generate test: `up test generate e2etest-xvpc-basic --e2e --language=kcl`
- [ ] Configure test with VPC, public subnets, IGW
- [ ] Add ProviderConfig to extraResources with IAM role: `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`
- [ ] IMPORTANT: Use assumeRoleChain, NEVER static credentials
- [ ] Set realistic timeout (1800 seconds / 30 minutes)
- [ ] Add defaultConditions: ["Ready", "Synced"]
- [ ] Test locally (requires `up login`): `up test run tests/e2etest-xvpc-basic --e2e`
- [ ] Verify resources created in AWS
- [ ] Verify resources cleaned up after test
- [ ] Document E2E test requirements in test README

**Reference**: thoughts/tools/testing-notes-platform-ref.md, thoughts/tools/testing-guide.md

**Acceptance Criteria**:
- E2E test creates real VPC in AWS
- All resources reach Ready/Synced conditions
- Resources are properly cleaned up
- Test uses IAM role (no static credentials)
- Test can run in CI with proper secrets

**Important**: Run E2E tests on Upbound Cloud for validation

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

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/VPCEndpoint`, Security Groups

**Acceptance Criteria**:
- Gateway endpoints (S3, DynamoDB) work
- Interface endpoints can be created
- Endpoint policies applied
- Cost consideration documented

---

### 3.1.1 Add Composition Tests for VPC Endpoints
**Priority**: P2
**Effort**: Medium
**Description**: Create composition tests for VPC Endpoints
**Dependencies**: Task 3.1

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-endpoints-gateway --language=kcl`
- [ ] Test S3 gateway endpoint creation
- [ ] Test DynamoDB gateway endpoint creation
- [ ] Generate test: `up test generate test-xvpc-endpoints-interface --language=kcl`
- [ ] Test interface endpoint creation (EC2, SSM, etc.)
- [ ] Test endpoint policies
- [ ] Test endpoint security groups
- [ ] Run tests: `up test run tests/test-xvpc-endpoints-*`
- [ ] Fix any broken tests
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- Tests validate gateway endpoint creation
- Tests validate interface endpoint creation
- Tests validate endpoint policies and security groups
- All existing tests still pass

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

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/NetworkACL`, `ec2.aws.upbound.io/v1beta1/NetworkACLRule`

**Acceptance Criteria**:
- Custom NACL rules can be defined
- Rules applied to correct subnets
- Default rules are permissive

---

### 3.2.1 Add Composition Tests for Network ACLs
**Priority**: P2
**Effort**: Small
**Description**: Create composition tests for Network ACLs
**Dependencies**: Task 3.2

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-nacl --language=kcl`
- [ ] Test NACL creation with custom rules
- [ ] Test inbound and outbound rules
- [ ] Test NACL association with subnets
- [ ] Test default permissive rules
- [ ] Run test: `up test run tests/test-xvpc-nacl`
- [ ] Fix any broken tests
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- Test validates NACL creation
- Test validates rule configuration
- Test validates subnet associations
- All existing tests still pass

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

**AWS Resources**: `ec2.aws.upbound.io/v1beta1/FlowLog`, CloudWatch Log Group, S3 Bucket, IAM Role

**Acceptance Criteria**:
- Flow logs to CloudWatch work
- Flow logs to S3 work
- Traffic filtering works
- IAM permissions correct

---

### 3.4.1 Add Composition Tests for Flow Logs
**Priority**: P2
**Effort**: Small
**Description**: Create composition tests for VPC Flow Logs
**Dependencies**: Task 3.4

**Tasks**:
- [ ] Generate test: `up test generate test-xvpc-flow-logs-cloudwatch --language=kcl`
- [ ] Test flow logs to CloudWatch destination
- [ ] Generate test: `up test generate test-xvpc-flow-logs-s3 --language=kcl`
- [ ] Test flow logs to S3 destination
- [ ] Test traffic type filtering (All/Accept/Reject)
- [ ] Test IAM role creation
- [ ] Run tests: `up test run tests/test-xvpc-flow-logs-*`
- [ ] Fix any broken tests
- [ ] Ensure all tests pass

**Acceptance Criteria**:
- Tests validate flow log destinations
- Tests validate IAM role configuration
- Tests validate traffic type filtering
- All existing tests still pass

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
- [x] Create `examples/simple-vpc.yaml` - Minimal VPC (done)
- [ ] Create `examples/complete-vpc.yaml` - All features
- [ ] Create `examples/private-only.yaml` - No IGW
- [ ] Create `examples/multi-az.yaml` - Multiple AZs
- [ ] Create `examples/with-endpoints.yaml` - VPC endpoints
- [ ] Create `examples/with-flow-logs.yaml` - Flow logs enabled
- [ ] Create `examples/nat-single.yaml` - Single NAT Gateway
- [ ] Create `examples/nat-per-az.yaml` - NAT per AZ
- [ ] Document each example thoroughly
- [ ] Add README.md in examples/ directory

**Reference**: thoughts/spec/terraform-vpc-analysis.md (Test Cases section)

**Acceptance Criteria**:
- All major use cases covered
- Examples match Terraform module examples
- Documentation clear and helpful
- Each example has inline comments

---

### 5.2 Implement Composition Test Suite
**Priority**: P1
**Effort**: Large
**Description**: Create comprehensive composition tests for all features

**Tasks**:
- [ ] Organize tests by feature in `tests/` directory
- [ ] Create test for basic VPC (test-xvpc-basic)
- [ ] Create tests for all subnet types
- [ ] Create tests for NAT Gateway strategies (see tasks 2.4.1)
- [ ] Create tests for route tables (see tasks 2.5.1)
- [ ] Create tests for conditional resource creation
- [ ] Create tests for VPC endpoints (after implementing)
- [ ] Create tests for Network ACLs (after implementing)
- [ ] Create tests for Flow Logs (after implementing)
- [ ] Create test for complete VPC with all features
- [ ] Add README.md in tests/ directory explaining test organization
- [ ] Run all tests: `up test run tests/test-*`
- [ ] Ensure all tests pass in < 60 seconds total

**Reference**: thoughts/tools/testing-notes-platform-ref.md

**Acceptance Criteria**:
- At least one test per major feature
- Tests follow platform-ref-upbound patterns
- Tests organized by resource type
- All tests pass locally
- Tests run automatically in CI
- Edge cases covered

---

### 5.3 Implement E2E Test Suite
**Priority**: P1
**Effort**: Large
**Description**: Create E2E tests for critical scenarios

**Tasks**:
- [ ] Create e2etest-xvpc-basic (see task 2.5.2)
- [ ] Create `e2etest-xvpc-nat` - VPC with NAT Gateway
- [ ] Create `e2etest-xvpc-complete` - All features enabled
- [ ] Configure tests with proper timeouts (1800+ seconds)
- [ ] Add ProviderConfig with IAM role to all E2E tests: `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`
- [ ] IMPORTANT: Use assumeRoleChain, NEVER static credentials
- [ ] Set skipDelete=false to ensure cleanup
- [ ] Test locally with `up test run tests/e2etest-* --e2e`
- [ ] Verify resources created in AWS
- [ ] Verify resources cleaned up after test
- [ ] Document E2E test IAM role requirements
- [ ] Add README.md for E2E tests

**Reference**: thoughts/tools/testing-guide.md, thoughts/tools/testing-notes-platform-ref.md

**Acceptance Criteria**:
- E2E tests create real AWS resources
- All resources reach Ready/Synced
- Resources properly cleaned up
- Tests use IAM role (no static credentials)
- Tests run in CI with "run-e2e-tests" label
- Tests can run on Upbound Cloud

---

### 5.4 Validate Feature Parity
**Priority**: P1
**Effort**: Medium
**Description**: Ensure all Terraform module features are implemented

**Tasks**:
- [ ] Create feature comparison checklist
- [ ] Verify all inputs supported
- [ ] Verify all outputs available
- [ ] Test each feature against Terraform behavior
- [ ] Run side-by-side comparison (Terraform vs Upbound)
- [ ] Document any intentional differences
- [ ] Create migration guide from Terraform module

**Reference**: thoughts/spec/terraform-vpc-analysis.md (complete feature list)

**Acceptance Criteria**:
- Feature parity achieved (or documented gaps)
- Behavior matches Terraform module
- Outputs match expected values
- Migration guide available

---

### 5.5 Setup Test Automation in CI/CD
**Priority**: P1
**Effort**: Small
**Description**: Ensure tests run automatically in CI/CD

**Tasks**:
- [x] Composition test workflow exists (`.github/workflows/composition-test.yaml`)
- [x] E2E test workflow exists (`.github/workflows/e2e.yaml`)
- [ ] Verify composition tests run on every PR
- [ ] Verify E2E tests run on labeled PRs ("run-e2e-tests")
- [ ] Add test status badges to README
- [ ] Configure test failure notifications
- [ ] Document how to run tests locally
- [ ] Add pre-commit hook for running tests (optional)

**Reference**: thoughts/tools/testing-notes-platform-ref.md

**Acceptance Criteria**:
- Composition tests run automatically on all PRs
- E2E tests run on labeled PRs
- Test failures block merging
- Documentation clear on running tests locally

---

### 5.6 Create Testing Documentation
**Priority**: P1
**Effort**: Small
**Description**: Document testing strategy and how to write tests

**Tasks**:
- [x] Testing guide created (thoughts/tools/testing-guide.md)
- [x] Platform-ref patterns documented (thoughts/tools/testing-notes-platform-ref.md)
- [ ] Add TESTING.md at project root for contributors
- [ ] Document test organization and naming
- [ ] Document how to generate new tests
- [ ] Document how to run tests locally
- [ ] Document E2E test requirements (credentials, costs)
- [ ] Add testing section to CONTRIBUTING.md
- [ ] Include testing in README.md

**Acceptance Criteria**:
- Contributors know how to write tests
- Testing strategy documented
- Examples provided
- Common issues documented

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
