# Terraform Validation Checklist

## Module Information
- **Terraform Module**: terraform-aws-vpc
- **Git URL**: https://github.com/terraform-aws-modules/terraform-aws-vpc
- **Branch**: master
- **Crossplane Project**: configuration-aws-vpc
- **Auth Mechanism**: Upbound Web Identity with IAM role (arn:aws:iam::609897127049:role/solutions-e2e-provider-aws)

## Validation Status

| Example | Terraform | Crossplane | Comparison | Status |
|---------|-----------|------------|------------|--------|
| block-public-access | ✅ | ⚠️ N/A | ⚠️ N/A | ⚠️ SKIP - Feature not supported |
| complete | ✅ | ⚠️ DHCP bug | ⚠️ Core matches | ⚠️ PARTIAL PASS |
| flow-log | ✅ | ✅ | ⚠️ Feature gap | ⚠️ PARTIAL PASS |
| ipam | N/A | N/A | N/A | ⚠️ SKIP - IPAM not implemented in XRD |
| ipv6-dualstack | ✅ | ❌ BUG | ❌ | ❌ FAIL - Composition bug |
| ipv6-only | N/A | ❌ BUG | N/A | ❌ SKIP - Same IPv6 bug as ipv6-dualstack |
| issues | N/A | N/A | N/A | ⚠️ SKIP - Tests specific GitHub issues/edge cases |
| manage-default-vpc | N/A | N/A | N/A | ⚠️ SKIP - Different use case |
| network-acls | ❌ | N/A | N/A | ⚠️ SKIP - Terraform example has IPv6 bug |
| outpost | N/A | N/A | N/A | ⚠️ SKIP - Requires hardware |
| secondary-cidr-blocks | ✅ | ⚠️ BUG | ⚠️ Partial | ⚠️ PARTIAL PASS |
| separate-route-tables | ✅ | ✅ | ✅ | ✅ PASS |
| simple | ✅ | ✅ | ✅ | ✅ PASS |

## Examples to Validate

- [x] `block-public-access` - ⚠️ SKIP - Uses vpc_block_public_access_options (feature not implemented)
- [x] `complete` - Complete VPC example with all features - ⚠️ PARTIAL PASS (2026-01-14)
- [x] `flow-log` - VPC with flow logs enabled - ⚠️ PARTIAL PASS (2026-01-14)
- [x] `ipam` - VPC using AWS IPAM for IP address management - ⚠️ SKIP - IPAM not implemented in XRD
- [x] `ipv6-dualstack` - VPC with dual-stack IPv4/IPv6 configuration - ❌ FAIL (2026-01-14)
- [x] `ipv6-only` - VPC with IPv6-only configuration - ❌ SKIP - Same IPv6 bug
- [x] `issues` - VPC examples for specific GitHub issues - ⚠️ SKIP - Tests edge cases
- [ ] `manage-default-vpc` - Managing the default VPC
- [x] `network-acls` - VPC with custom network ACLs - ⚠️ SKIP - Terraform example has bug (enable_ipv6=true without CIDR causes DNS64 error)
- [ ] `outpost` - VPC with AWS Outpost support
- [x] `secondary-cidr-blocks` - VPC with secondary CIDR blocks - ⚠️ PARTIAL PASS (2026-01-14)
- [x] `separate-route-tables` - VPC with separate route tables per subnet - ✅ PASS (2026-01-15)
- [x] `simple` - Minimal VPC configuration - ✅ PASS (2026-01-14)

## Completed Examples

### simple - ✅ PASS (2026-01-14)
- **Terraform Resources**: 13 (1 VPC, 3 Subnets, 3 Route Tables, 3 RT Associations, 1 Default RT, 1 Default NACL, 1 Default SG)
- **Crossplane Resources**: 4 Managed (1 VPC, 3 Subnets)
- **Result**: Functionally equivalent - all core infrastructure matches
- **Report**: `.terraform-validation/reports/simple-comparison.md`

### complete - ⚠️ PARTIAL PASS (2026-01-14)
- **Terraform Resources**: 71 (VPC, 18 Subnets, IGW, NAT GW, VPN GW, 3 Customer Gateways, DHCP Options, Route Tables, VPC Endpoints)
- **Crossplane Resources**: 40+ Managed (VPC, 18 Subnets, IGW, NAT GW, VPN GW, 2 Customer Gateways) - DHCP failing
- **Core Infrastructure**: ✅ All matches (VPC, subnets, gateways, routing)
- **Issues Found**:
  1. ✅ Fixed: Customer gateway key naming (lowercase ip1/ip2 for RFC 1123)
  2. ❌ BUG: DHCP options composition passes null for optional arrays
- **Note**: VPC Endpoints not in XR scope (separate Terraform module)
- **Report**: `.terraform-validation/reports/complete-comparison.md`

### flow-log - ⚠️ PARTIAL PASS (2026-01-14)
- **Terraform Resources**: 36 (VPC, 6 Subnets, IGW, 4 Route Tables, 4 Flow Logs, S3 Bucket, IAM Roles)
- **Crossplane Resources**: 15 Managed (VPC, 6 Subnets, 1 Route Table, 1 Flow Log, IAM Role, CloudWatch Log Group)
- **Core Infrastructure**: ✅ All matches (VPC, subnets, CIDRs)
- **Flow Log**: ✅ CloudWatch flow log working correctly
- **Feature Gap**: XRD creates 1 flow log (CloudWatch); Terraform example has 4 (2 S3, 2 CloudWatch)
- **Note**: Terraform example demonstrates flow-log submodule with multiple configurations
- **Report**: `.terraform-validation/reports/flow-log-comparison.md`

### ipv6-dualstack - ❌ FAIL (2026-01-14)
- **Terraform Resources**: Deployed successfully with IPv6 CIDR 2a05:d018:8c4:6100::/56
- **Crossplane Resources**: 0 (composition failed before creating any resources)
- **Bug Location**: `functions/vpc/subnets.k:90`
- **Error**: KCL ParseIntError - IPv6 CIDR hex parsing fails with InvalidDigit
- **Root Cause**: The `int(segment3Str, 16)` call receives invalid input during IPv6 CIDR calculation
- **Impact**: IPv6 dual-stack VPCs cannot be created until bug is fixed

### secondary-cidr-blocks - ⚠️ PARTIAL PASS (2026-01-14)
- **Terraform Resources**: VPC with 2 secondary CIDRs, 12 subnets (3 public + 9 private)
- **Crossplane Resources**: VPC, 2 secondary CIDR associations, 6 subnets (3 public + 3 private)
- **What Works**: ✅ Secondary CIDR associations work correctly
- **Bug**: Composition creates only 3 private subnets per AZ regardless of how many CIDRs specified
- **Cause**: Subnet naming uses only AZ suffix without CIDR index, causing conflicts when multiple subnets per AZ
- **Impact**: Cannot create multiple subnets in same AZ from different CIDR blocks

### separate-route-tables - ✅ PASS (2026-01-15)
- **Terraform Resources**: 40+ (VPC, 18 Subnets, 7 Route Tables, IGW, NAT GW)
- **Crossplane Resources**: 40+ Managed (VPC, 18 Subnets, 7 Route Tables, IGW, NAT GW)
- **Result**: Perfect match - all infrastructure identical
- **Route Tables**: 7 total (1 main + 1 public + 1 private + 1 database + 1 elasticache + 1 redshift + 1 intra)
- **Feature Validated**: `createDatabaseSubnetRouteTable`, `createElasticacheSubnetRouteTable`, `createRedshiftSubnetRouteTable`
- **Report**: `.terraform-validation/reports/separate-route-tables-comparison.md`

## Notes

- Terraform state stored in: `.terraform-validation/terraform-aws-vpc/examples/<name>/`
- XR manifests generated in: `.terraform-validation/xr-manifests/`
- Comparison reports in: `.terraform-validation/reports/`
- Auth uses Upbound Web Identity federation (no AWS credentials required)
