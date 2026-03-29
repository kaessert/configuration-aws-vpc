# Current Focus: NAT Gateway Enhancements (Task 4.4)

## Status

**Priority**: P2 (Important)
**Effort**: Medium
**Current Phase**: Planning

## Overview

Enhance NAT Gateway functionality to match Terraform aws-vpc module capabilities. Currently support single NAT and NAT per AZ strategies. Need to add NAT per subnet, EIP reuse, and custom destination CIDR.

## Remaining Features to Implement

### 1. NAT per Subnet Strategy
**Current**: NAT per AZ (one NAT Gateway per availability zone)
**Needed**: NAT per subnet (one NAT Gateway in every public subnet)

**Rationale**: Terraform's default is NAT per subnet for maximum availability. Some users need this for compliance or high-availability requirements.

### 2. Reuse Existing EIPs
**Current**: Always creates new EIPs
**Needed**: Support bringing your own EIP allocation IDs

**Rationale**: Organizations may have reserved Elastic IPs for specific purposes or compliance requirements (e.g., whitelisted IPs).

**Implementation**:
- Add `reuseNatIps` boolean flag
- Add `externalNatIpIds` field (list of EIP allocation IDs)
- Skip EIP creation when external IPs provided
- Associate external EIPs with NAT Gateways

### 3. Custom NAT Destination CIDR
**Current**: Always routes 0.0.0.0/0 through NAT
**Needed**: Support custom destination CIDR blocks

**Rationale**: Non-standard routing scenarios (e.g., route only specific CIDR ranges through NAT, use different routes for different traffic).

**Implementation**:
- Add `natGatewayDestinationCidrBlock` field (default: "0.0.0.0/0")
- Use configured value when creating NAT routes

## Next Steps

1. Review Terraform implementation for reference
2. Design XRD field additions
3. Write composition tests (TDD approach)
4. Implement features one at a time
5. Run E2E tests
6. Document usage and cost implications

## Reference

- **Terraform Module**: https://github.com/terraform-aws-modules/terraform-aws-vpc
- **Task Details**: See TASKS.md Section 4.4
- **Current Implementation**: functions/vpc/gateways.k (NAT Gateway generation)
- **Current Tests**: tests/test-vpc-nat-*.k

## Progress Tracking

- [ ] NAT per subnet strategy
- [ ] Reuse existing EIPs
- [ ] Custom NAT destination CIDR
- [ ] Composition tests
- [ ] E2E test
- [ ] Documentation
