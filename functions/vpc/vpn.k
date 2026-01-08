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
            - vpnGatewayId: Use existing VPN Gateway (optional)
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
                    amazonSideAsn = str(config.amazonSideAsn)
                    region = config.region
                    tags = config.tags | config.vpnGatewayTags | {
                        Name = "vgw-${config.vpcName}"
                    }
                } | ({"availabilityZone": config.vpnGatewayAz} if config.vpnGatewayAz else {})
            }
        }
    ] if config.enableVpnGateway and not config.vpnGatewayId else []
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
    ] if config.enableVpnGateway and not config.vpnGatewayId else []
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
            - publicSubnets: Public subnets list
            - privateSubnets: Private subnets list
            - databaseSubnets: Database subnets list
            - intraSubnets: Intra subnets list
            - createDatabaseSubnetRouteTable: Whether separate database route table exists

    Returns:
        List of route propagation resources
    """
    propagations = []
    
    # Public route table propagation
    if config.propagatePublicRouteTablesVgw and len(config.publicSubnets) > 0:
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
    if config.propagatePrivateRouteTablesVgw and len(config.privateSubnets) > 0:
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
    if config.propagateDatabaseRouteTablesVgw and len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable:
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
    if config.propagateIntraRouteTablesVgw and len(config.intraSubnets) > 0:
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
    generateVPNGateway(config) + generateVPNGatewayAttachment(config) + _generateVPNGatewayRoutePropagation(config) if config.enableVpnGateway else []
}
