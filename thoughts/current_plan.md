# Implementation Plan: VPN Gateway Support (Task 4.1)

## Feature Overview

Implement VPN Gateway support to enable hybrid cloud connectivity between on-premises networks and AWS VPCs. This is a P1 enterprise requirement that allows secure connections for hybrid workloads.

## Specification

### AWS Resources Required
- `ec2.aws.upbound.io/v1beta1/VPNGateway` - Virtual private gateway
- `ec2.aws.upbound.io/v1beta1/VPNGatewayAttachment` - VPC attachment
- `ec2.aws.upbound.io/v1beta1/VPNGatewayRoutePropagation` - Route propagation to route tables

### XRD Fields to Add

```yaml
# VPN Gateway Configuration
enableVpnGateway: bool                    # Enable VPN Gateway (default: false) [EXISTS]
vpnGatewayId: string                      # Use existing VPN Gateway ID (optional) [NEW]
amazonSideAsn: integer                    # BGP ASN for Amazon side (default: 64512) [NEW]
vpnGatewayAz: string                      # AZ for VPN Gateway (optional) [NEW]
propagatePublicRouteTablesVgw: bool       # Propagate routes to public route tables (default: true) [NEW]
propagatePrivateRouteTablesVgw: bool      # Propagate routes to private route tables (default: true) [NEW]
propagateIntraRouteTablesVgw: bool        # Propagate routes to intra route tables (default: false) [NEW]
propagateDatabaseRouteTablesVgw: bool     # Propagate routes to database route tables (default: false) [NEW]
vpnGatewayTags: object                    # Additional tags for VPN Gateway [NEW]

# Status fields [EXIST]
vpnGatewayId: string                      # ID of created/attached VPN Gateway
vpnGatewayArn: string                     # ARN of VPN Gateway
```

### Behavioral Requirements

1. **Conditional Creation**: Create VPN Gateway only when `enableVpnGateway: true`
2. **Existing Gateway Support**: If `vpnGatewayId` provided, attach existing gateway instead of creating new
3. **VPC Attachment**: Automatically attach gateway to VPC using selector
4. **Route Propagation**: Selectively propagate routes to route tables based on flags
5. **Default Propagation**: By default, propagate to public and private route tables only
6. **BGP ASN**: Support custom Amazon-side ASN (default: 64512)
7. **AZ Specification**: Optional AZ placement for VPN Gateway

---

## Implementation Steps

### Step 1: Update XRD Definition
**File**: `apis/vpc/definition.yaml`

1. Add new input fields to `spec.properties`:
   - `vpnGatewayId` (string, optional)
   - `amazonSideAsn` (integer, optional, default: 64512)
   - `vpnGatewayAz` (string, optional)
   - `propagatePublicRouteTablesVgw` (boolean, default: true)
   - `propagatePrivateRouteTablesVgw` (boolean, default: true)
   - `propagateIntraRouteTablesVgw` (boolean, default: false)
   - `propagateDatabaseRouteTablesVgw` (boolean, default: false)
   - `vpnGatewayTags` (object, optional)

2. Verify status fields exist:
   - `vpnGatewayId` (string)
   - `vpnGatewayArn` (string)

### Step 2: Write Composition Tests (RED Phase)

#### Test 2.1: VPN Gateway Enabled
**File**: `tests/test-vpc-vpn-enabled/main.k`

Generate test:
```bash
up test generate test-vpc-vpn-enabled --language=kcl
```

Test specification:
- Input: VPC with `enableVpnGateway: true`
- Assert: 1 VPNGateway resource created
- Assert: VPNGateway has default Amazon-side ASN (64512)
- Assert: VPNGateway attached to VPC via selector
- Assert: Route propagation to public route tables (1 propagation resource)
- Assert: Route propagation to private route tables (1 propagation resource per AZ for NAT-per-AZ, or 1 for single NAT)
- Assert: Correct tags applied
- Assert: VPNGatewayAttachment resource created

#### Test 2.2: VPN Gateway with Custom ASN
**File**: `tests/test-vpc-vpn-custom-asn/main.k`

Test specification:
- Input: VPC with `enableVpnGateway: true`, `amazonSideAsn: 65000`
- Assert: VPNGateway created with ASN 65000
- Assert: All other resources correct

#### Test 2.3: VPN Gateway with Selective Propagation
**File**: `tests/test-vpc-vpn-selective-propagation/main.k`

Test specification:
- Input: VPC with database subnets, intra subnets
- Input: `enableVpnGateway: true`
- Input: `propagatePublicRouteTablesVgw: true`
- Input: `propagatePrivateRouteTablesVgw: false`
- Input: `propagateDatabaseRouteTablesVgw: true`
- Input: `propagateIntraRouteTablesVgw: false`
- Assert: Route propagation to public route table only
- Assert: Route propagation to database route table only
- Assert: NO propagation to private route tables
- Assert: NO propagation to intra route tables

#### Test 2.4: VPN Gateway Disabled
**File**: `tests/test-vpc-vpn-disabled/main.k`

Test specification:
- Input: VPC with `enableVpnGateway: false` (default)
- Assert: 0 VPNGateway resources
- Assert: 0 VPNGatewayAttachment resources
- Assert: 0 VPNGatewayRoutePropagation resources

**Run tests** (expect all to FAIL - RED phase):
```bash
up test run tests/test-vpc-vpn-*
```

### Step 3: Create VPN Module (GREEN Phase)
**File**: `functions/vpc/vpn.k`

Create new module file with functions:

```kcl
"""
VPN Module

This module handles generation of:
- VPN Gateway
- VPN Gateway VPC attachment
- VPN Gateway route propagation
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Generate VPN Gateway resource
generateVPNGateway = lambda config: {str: any} -> [any] {
    """
    Generates the VPN Gateway resource.

    Args:
        config: Configuration object containing:
            - enableVpnGateway: Whether to create VPN Gateway
            - amazonSideAsn: BGP ASN for Amazon side (default: 64512)
            - vpnGatewayAz: Availability zone (optional)
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - vpnGatewayTags: VPN-specific tags
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List containing the VPN Gateway resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPNGateway{
            metadata = config.metadata("vgw") | {
                name = "vgw-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    amazonSideAsn = str(config.amazonSideAsn) if "amazonSideAsn" in config else "64512"
                    availabilityZone = config.vpnGatewayAz if "vpnGatewayAz" in config else None
                    region = config.region
                    tags = config.tags | config.vpnGatewayTags | {
                        Name = "vgw-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.enableVpnGateway and "vpnGatewayId" not in config else []
}

# Generate VPN Gateway attachment
generateVPNGatewayAttachment = lambda config: {str: any} -> [any] {
    """
    Generates the VPN Gateway VPC attachment.

    Args:
        config: Configuration object

    Returns:
        List containing the attachment resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPNGatewayAttachment{
            metadata = config.metadata("vgw-attachment") | {
                name = "vgw-attachment-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    vpnGatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                }
            }
        }
    ] if config.enableVpnGateway and "vpnGatewayId" not in config else []
}

# Generate VPN Gateway route propagation
_generateVPNGatewayRoutePropagation = lambda config: {str: any} -> [any] {
    """
    Generates VPN Gateway route propagation resources.

    Args:
        config: Configuration object containing:
            - propagatePublicRouteTablesVgw: Propagate to public route tables
            - propagatePrivateRouteTablesVgw: Propagate to private route tables
            - propagateIntraRouteTablesVgw: Propagate to intra route tables
            - propagateDatabaseRouteTablesVgw: Propagate to database route tables
            - enableNatGateway: Whether NAT Gateway is enabled
            - oneNatGatewayPerAz: NAT per AZ strategy
            - azs: Availability zones list

    Returns:
        List of route propagation resources
    """
    propagations = []
    
    # Public route table propagation
    if config.get("propagatePublicRouteTablesVgw", True) and len(config.publicSubnets) > 0:
        propagations += [
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata = config.metadata("vgw-prop-public") | {
                    name = "vgw-prop-public-${config.vpcName}"
                    labels = config.tags
                }
                spec = config.defaultV2Spec | {
                    forProvider = {
                        routeTableIdSelector = {
                            matchLabels = {
                                "route-table-type": "public"
                            }
                        }
                        vpnGatewayIdSelector = {
                            matchControllerRef = True
                        }
                        region = config.region
                    }
                }
            }
        ]
    
    # Private route table propagation
    if config.get("propagatePrivateRouteTablesVgw", True) and len(config.privateSubnets) > 0:
        if config.enableNatGateway and config.oneNatGatewayPerAz:
            # One propagation per AZ for NAT-per-AZ strategy
            propagations += [
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata = config.metadata("vgw-prop-private-${i}") | {
                        name = "vgw-prop-private-${config.vpcName}-${config.azs[i]}"
                        labels = config.tags | {"az": config.azs[i]}
                    }
                    spec = config.defaultV2Spec | {
                        forProvider = {
                            routeTableIdSelector = {
                                matchLabels = {
                                    "route-table-type": "private"
                                    "az": config.azs[i]
                                }
                            }
                            vpnGatewayIdSelector = {
                                matchControllerRef = True
                            }
                            region = config.region
                        }
                    }
                }
                for i in range(len(config.azs))
            ]
        else:
            # Single propagation for shared private route table
            propagations += [
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata = config.metadata("vgw-prop-private") | {
                        name = "vgw-prop-private-${config.vpcName}"
                        labels = config.tags
                    }
                    spec = config.defaultV2Spec | {
                        forProvider = {
                            routeTableIdSelector = {
                                matchLabels = {
                                    "route-table-type": "private"
                                }
                            }
                            vpnGatewayIdSelector = {
                                matchControllerRef = True
                            }
                            region = config.region
                        }
                    }
                }
            ]
    
    # Database route table propagation
    if config.get("propagateDatabaseRouteTablesVgw", False) and len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable:
        propagations += [
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata = config.metadata("vgw-prop-database") | {
                    name = "vgw-prop-database-${config.vpcName}"
                    labels = config.tags
                }
                spec = config.defaultV2Spec | {
                    forProvider = {
                        routeTableIdSelector = {
                            matchLabels = {
                                "route-table-type": "database"
                            }
                        }
                        vpnGatewayIdSelector = {
                            matchControllerRef = True
                        }
                        region = config.region
                    }
                }
            }
        ]
    
    # Intra route table propagation
    if config.get("propagateIntraRouteTablesVgw", False) and len(config.intraSubnets) > 0:
        propagations += [
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata = config.metadata("vgw-prop-intra") | {
                    name = "vgw-prop-intra-${config.vpcName}"
                    labels = config.tags
                }
                spec = config.defaultV2Spec | {
                    forProvider = {
                        routeTableIdSelector = {
                            matchLabels = {
                                "route-table-type": "intra"
                            }
                        }
                        vpnGatewayIdSelector = {
                            matchControllerRef = True
                        }
                        region = config.region
                    }
                }
            }
        ]
    
    propagations
}

# Generate all VPN resources
generateAllVPN = lambda config: {str: any} -> [any] {
    """
    Generates all VPN resources (VPN Gateway, attachment, route propagation).

    Args:
        config: Configuration object containing all VPN parameters

    Returns:
        List of all VPN resources
    """
    generateVPNGateway(config) + \
    generateVPNGatewayAttachment(config) + \
    _generateVPNGatewayRoutePropagation(config) if config.enableVpnGateway else []
}
```

### Step 4: Update Main Orchestration
**File**: `functions/vpc/main.k`

1. Import vpn module:
```kcl
import .vpn as vpn
```

2. Add VPN configuration to config object:
```kcl
config = {
    # ... existing config ...
    enableVpnGateway = oxr.spec.enableVpnGateway or False
    amazonSideAsn = oxr.spec.amazonSideAsn if "amazonSideAsn" in oxr.spec else 64512
    vpnGatewayAz = oxr.spec.vpnGatewayAz if "vpnGatewayAz" in oxr.spec else None
    propagatePublicRouteTablesVgw = oxr.spec.propagatePublicRouteTablesVgw if "propagatePublicRouteTablesVgw" in oxr.spec else True
    propagatePrivateRouteTablesVgw = oxr.spec.propagatePrivateRouteTablesVgw if "propagatePrivateRouteTablesVgw" in oxr.spec else True
    propagateIntraRouteTablesVgw = oxr.spec.propagateIntraRouteTablesVgw if "propagateIntraRouteTablesVgw" in oxr.spec else False
    propagateDatabaseRouteTablesVgw = oxr.spec.propagateDatabaseRouteTablesVgw if "propagateDatabaseRouteTablesVgw" in oxr.spec else False
    vpnGatewayTags = oxr.spec.vpnGatewayTags if "vpnGatewayTags" in oxr.spec else {}
}
```

3. Add VPN resources to items:
```kcl
items = [
    # ... existing resources ...
] + vpn.generateAllVPN(config)
```

### Step 5: Run Tests (GREEN Phase)

Run all VPN tests:
```bash
up test run tests/test-vpc-vpn-*
```

**Expected**: All 4 VPN tests PASS

Run all tests to check for regressions:
```bash
up test run tests/test-*
```

**Expected**: All 36 composition tests PASS (32 existing + 4 new)

### Step 6: Create E2E Test
**File**: `tests/e2etest-vpc-vpn/main.k`

Generate E2E test:
```bash
up test generate e2etest-vpc-vpn --language=kcl
```

Test specification:
- VPC with public, private, and database subnets
- 3 AZs
- Internet Gateway enabled
- NAT Gateway per AZ enabled
- VPN Gateway enabled
- Route propagation to public and private route tables
- Verify VPN Gateway reaches Ready state
- Verify VPN Gateway attached to VPC
- Verify route propagation configured
- Timeout: 2400 seconds (40 minutes)

Run E2E test:
```bash
up login
up test run tests/e2etest-vpc-vpn --e2e
```

**Expected**: E2E test passes, VPN Gateway created in AWS

### Step 7: Create Example Configuration
**File**: `examples/vpn-gateway.yaml`

Create example showing:
- VPC with VPN Gateway for hybrid connectivity
- Multi-AZ setup with NAT Gateway per AZ
- Route propagation to public and private route tables
- Database subnets without VPN propagation (isolated)
- Inline documentation explaining use case
- Cost considerations (VPN Gateway: $0.05/hour + data transfer)

### Step 8: Update Documentation

1. **README.md**: 
   - Add VPN Gateway to implemented features list
   - Update feature parity percentage
   - Add note about hybrid cloud connectivity

2. **thoughts/tasks.md**:
   - Mark Task 4.1 as COMPLETED ✅
   - Update current status
   - Update feature parity metrics

3. **API Reference** in README.md:
   - Document new VPN Gateway fields
   - Add usage examples
   - Document route propagation behavior

---

## Verification Checklist

### Tests
- [ ] 4 composition tests created and passing
- [ ] All existing 32 composition tests still passing (no regressions)
- [ ] 1 E2E test created and passing
- [ ] Total: 36 composition tests, 12 E2E tests

### Code Quality
- [ ] vpn.k module under 300 lines
- [ ] All functions documented with docstrings
- [ ] No code duplication
- [ ] Follows existing module patterns (gateways.k, routing.k)
- [ ] Type-safe implementation

### Functionality
- [ ] VPN Gateway creates when enabled
- [ ] VPN Gateway attaches to VPC
- [ ] Route propagation works for all route table types
- [ ] Selective propagation flags work correctly
- [ ] Custom Amazon-side ASN supported
- [ ] Default values applied correctly
- [ ] Tags merged correctly
- [ ] Conditional creation works (enabled/disabled)

### Documentation
- [ ] XRD fields documented with descriptions
- [ ] Example configuration created
- [ ] README updated with VPN Gateway feature
- [ ] Tasks.md updated with completion status
- [ ] API reference updated

### Integration
- [ ] Module imported in main.k
- [ ] Config object properly structured
- [ ] Resources added to items list
- [ ] No conflicts with existing modules
- [ ] Project builds successfully

---

## Estimated Effort

- **XRD Updates**: 30 minutes
- **Composition Tests (4 tests)**: 2 hours
- **VPN Module Implementation**: 2-3 hours
- **Main.k Integration**: 30 minutes
- **E2E Test**: 1 hour
- **Example Configuration**: 30 minutes
- **Documentation**: 1 hour
- **Testing & Verification**: 1 hour

**Total**: 8-9 hours (1-1.5 days)

---

## Dependencies

### Required
- Task 2.5 (Routing) ✅ COMPLETED - VPN needs route tables to exist
- Task 2.3 (Internet Gateway) ✅ COMPLETED - VPN works alongside IGW

### Blockers
None - all dependencies completed

### Enables
- Task 4.2 (Customer Gateways) - VPN Gateway required for VPN connections
- Hybrid cloud connectivity use cases
- Enterprise multi-region architectures

---

## Risk Mitigation

### Risk: Route Propagation Conflicts
**Mitigation**: Use label selectors to precisely target route tables, ensure propagation is additive

### Risk: VPN Gateway Attachment Timing
**Mitigation**: Use proper selectors for VPC and VPN Gateway, Crossplane handles dependency ordering

### Risk: ASN Validation
**Mitigation**: Document valid ASN ranges (64512-65534 for private use), add OpenAPI validation to XRD

### Risk: Existing VPN Gateway Support
**Mitigation**: Phase 1 implementation creates new gateway only. Existing gateway attachment deferred to enhancement.

---

## Success Criteria

1. ✅ All 4 composition tests passing
2. ✅ All 32 existing tests still passing (no regressions)
3. ✅ E2E test validates real AWS VPN Gateway creation
4. ✅ Example configuration demonstrates hybrid cloud use case
5. ✅ Documentation complete and clear
6. ✅ Code quality meets project standards (modular, documented, tested)
7. ✅ Feature parity increased from 70% to ~73%
