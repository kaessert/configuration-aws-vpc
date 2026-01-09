"""
Gateways Module

This module handles generation of:
- Internet Gateway (IGW)
- Elastic IP (EIP) resources for NAT Gateways
- NAT Gateway resources
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Generate Internet Gateway resource
generateInternetGateway = lambda config: {str: any} -> [any] {
    """
    Generates the Internet Gateway resource.

    Args:
        config: Configuration object containing:
            - createIgw: Whether to create the IGW
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List containing the IGW resource (or empty list if disabled)
    """
    [
        ec2v1beta1.InternetGateway{
            metadata = config.metadata("igw") | {
                name = "igw-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "resource-type": "igw"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "igw-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.createIgw else []
}

# Generate EIP resources for NAT Gateways
generateEIPs = lambda config: {str: any} -> [any] {
    """
    Generates Elastic IP resources for NAT Gateways.

    Supports three strategies:
    - One NAT Gateway per subnet (oneNatGatewayPerSubnet)
    - One NAT Gateway per AZ (oneNatGatewayPerAz)
    - Single NAT Gateway (singleNatGateway)

    When reuseNatIps is true, NO EIPs are created (external EIPs are used instead).

    Args:
        config: Configuration object containing NAT Gateway parameters

    Returns:
        List of EIP resources, or empty list if reusing external EIPs
    """
    # Strategy 1: NAT per subnet - create EIP per public subnet
    [
        ec2v1beta1.EIP{
            metadata = config.metadata("eip-nat-${i}") | {
                name = "eip-nat-${config.vpcName}-${i}"
                labels = config.sanitizeLabels(config.tags) | {"eip-index": str(i)}
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    domain = "vpc"
                    region = config.region
                    tags = config.tags | {
                        Name = "eip-nat-${config.vpcName}-${i}"
                        Index = str(i)
                    }
                }
            }
        }
        for i in range(len(config.publicSubnets))
    ] if config.enableNatGateway and config.oneNatGatewayPerSubnet and not config.reuseNatIps and len(config.publicSubnets) > 0 else [
        # Strategy 2: NAT per AZ - create EIP per AZ
        ec2v1beta1.EIP{
            metadata = config.metadata("eip-nat-${i}") | {
                name = "eip-nat-${config.vpcName}-${config.azs[i]}"
                labels = config.sanitizeLabels(config.tags) | {"az": config.azs[i]}
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    domain = "vpc"
                    region = config.region
                    tags = config.tags | {
                        Name = "eip-nat-${config.vpcName}-${config.azs[i]}"
                        AZ = config.azs[i]
                    }
                }
            }
        }
        for i in range(len(config.azs))
    ] if config.enableNatGateway and config.oneNatGatewayPerAz and not config.reuseNatIps and len(config.azs) > 0 and len(config.publicSubnets) > 0 else [
        # Strategy 3: Single NAT Gateway - create single EIP
        ec2v1beta1.EIP{
            metadata = config.metadata("eip-nat-0") | {
                name = "eip-nat-${config.vpcName}-${config.azs[0]}"
                labels = config.sanitizeLabels(config.tags)
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    domain = "vpc"
                    region = config.region
                    tags = config.tags | {
                        Name = "eip-nat-${config.vpcName}-${config.azs[0]}"
                    }
                }
            }
        }
    ] if config.enableNatGateway and config.singleNatGateway and not config.reuseNatIps and len(config.azs) > 0 and len(config.publicSubnets) > 0 else []
}

# Helper function to build NAT Gateway forProvider with conditional EIP reference
_buildNatForProvider = lambda subnetSelector: {str: any}, region: str, tags: {str: str}, eipConfig: {str: any} -> {str: any} {
    """
    Builds forProvider configuration for NAT Gateway with conditional EIP reference.

    Args:
        subnetSelector: Selector configuration for subnet
        region: AWS region
        tags: Resource tags
        eipConfig: Either {"allocationId": "..."} or {"allocationIdSelector": {...}}

    Returns:
        Complete forProvider dictionary
    """
    {
        subnetIdSelector = subnetSelector
        region = region
        tags = tags
    } | eipConfig
}

# Generate NAT Gateway resources
generateNATGateways = lambda config: {str: any} -> [any] {
    """
    Generates NAT Gateway resources.

    Supports three strategies:
    - One NAT Gateway per subnet (oneNatGatewayPerSubnet)
    - One NAT Gateway per AZ (oneNatGatewayPerAz)
    - Single NAT Gateway (singleNatGateway)

    Supports two EIP modes:
    - Create new EIPs (default): Uses allocationIdSelector
    - Reuse external EIPs (reuseNatIps): Uses allocationId field with external IDs

    Args:
        config: Configuration object containing NAT Gateway parameters

    Returns:
        List of NAT Gateway resources
    """
    # Strategy 1: NAT per subnet - create NAT Gateway per public subnet
    [
        ec2v1beta1.NATGateway{
            metadata = config.metadata("nat-${i}") | {
                name = "nat-${config.vpcName}-${i}"
                labels = config.sanitizeLabels(config.tags) | {"nat-index": str(i)}
            }
            spec = config.defaultV2Spec | {
                forProvider = _buildNatForProvider(
                    {
                        matchLabels = {
                            "subnet-type": "public"
                            "subnet-index": str(i)
                        }
                    },
                    config.region,
                    config.tags | {
                        Name = "nat-${config.vpcName}-${i}"
                        Index = str(i)
                    },
                    # EIP configuration: use external ID or selector
                    {allocationId = config.externalNatIpIds[i]} if config.reuseNatIps and len(config.externalNatIpIds) > i else {
                        allocationIdSelector = {
                            matchLabels = {
                                "eip-index": str(i)
                            }
                        }
                    }
                )
            }
        }
        for i in range(len(config.publicSubnets))
    ] if config.enableNatGateway and config.oneNatGatewayPerSubnet and len(config.publicSubnets) > 0 else [
        # Strategy 2: NAT per AZ - create NAT Gateway per AZ
        ec2v1beta1.NATGateway{
            metadata = config.metadata("nat-${i}") | {
                name = "nat-${config.vpcName}-${config.azs[i]}"
                labels = config.sanitizeLabels(config.tags) | {"az": config.azs[i]}
            }
            spec = config.defaultV2Spec | {
                forProvider = _buildNatForProvider(
                    {
                        matchLabels = {
                            "subnet-type": "public"
                            "az": config.azs[i]
                        }
                    },
                    config.region,
                    config.tags | {
                        Name = "nat-${config.vpcName}-${config.azs[i]}"
                        AZ = config.azs[i]
                    },
                    # EIP configuration: use external ID or selector
                    {allocationId = config.externalNatIpIds[i]} if config.reuseNatIps and len(config.externalNatIpIds) > i else {
                        allocationIdSelector = {
                            matchLabels = {
                                "az": config.azs[i]
                            }
                        }
                    }
                )
            }
        }
        for i in range(len(config.azs))
    ] if config.enableNatGateway and config.oneNatGatewayPerAz and len(config.azs) > 0 and len(config.publicSubnets) > 0 else [
        # Strategy 3: Single NAT Gateway
        ec2v1beta1.NATGateway{
            metadata = config.metadata("nat-0") | {
                name = "nat-${config.vpcName}-${config.azs[0]}"
                labels = config.sanitizeLabels(config.tags) | {"az": config.azs[0]}
            }
            spec = config.defaultV2Spec | {
                forProvider = _buildNatForProvider(
                    {
                        matchLabels = {
                            "subnet-type": "public"
                            "az": config.azs[0]
                        }
                    },
                    config.region,
                    config.tags | {
                        Name = "nat-${config.vpcName}-${config.azs[0]}"
                    },
                    # EIP configuration: use external ID or selector
                    {allocationId = config.externalNatIpIds[0]} if config.reuseNatIps and len(config.externalNatIpIds) > 0 else {
                        allocationIdSelector = {
                            matchControllerRef = True
                        }
                    }
                )
            }
        }
    ] if config.enableNatGateway and config.singleNatGateway and len(config.azs) > 0 and len(config.publicSubnets) > 0 else []
}

# Generate Egress-Only Internet Gateway for IPv6
generateEgressOnlyInternetGateway = lambda config: {str: any} -> [any] {
    """
    Generates the Egress-Only Internet Gateway resource for IPv6.

    This gateway allows outbound IPv6 traffic from private subnets while
    preventing inbound IPv6 connections from the internet.

    Args:
        config: Configuration object containing:
            - createEgressOnlyIgw: Whether to create the Egress-Only IGW
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List containing the Egress-Only IGW resource (or empty list if disabled)
    """
    [
        ec2v1beta1.EgressOnlyInternetGateway{
            metadata = config.metadata("eigw") | {
                name = "eigw-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags)
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "eigw-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.createEgressOnlyIgw else []
}

# Generate all gateway resources
generateAllGateways = lambda config: {str: any} -> [any] {
    """
    Generates all gateway resources (IGW, Egress-Only IGW, EIPs, NAT Gateways).

    Args:
        config: Configuration object containing all gateway parameters

    Returns:
        List of all gateway resources
    """
    generateInternetGateway(config) + \
    generateEgressOnlyInternetGateway(config) + \
    generateEIPs(config) + \
    generateNATGateways(config)
}
