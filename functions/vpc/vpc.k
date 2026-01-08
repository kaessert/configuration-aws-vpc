"""
VPC Core Module

This module handles the core VPC resource creation and secondary CIDR block associations.
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Secondary CIDR Block Association Generator
_generateSecondaryCidrBlocks = lambda config: {str: any} -> [any] {
    """
    Generates VPCIPv4CidrBlockAssociation resources for secondary CIDR blocks.

    Args:
        config: Configuration object containing:
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - secondaryCidrBlocks: List of secondary CIDR blocks
            - region: AWS region
            - defaultV2Spec: Default v2 spec configuration

    Returns:
        List of VPCIPv4CidrBlockAssociation resources
    """
    [
        ec2v1beta1.VPCIPv4CidrBlockAssociation{
            metadata = config.metadata("secondary-cidr-${i}") | {
                name = "secondary-cidr-${config.vpcName}-${i}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    cidrBlock = secondaryCidr
                    region = config.region
                    # Reference the VPC via controller ref
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                }
            }
        }
        for i, secondaryCidr in config.secondaryCidrBlocks
    ] if len(config.secondaryCidrBlocks) > 0 else []
}

# VPC Resource Generator
_generateVPC = lambda config: {str: any} -> [any] {
    """
    Generates the core VPC resource.

    Supports two modes for CIDR allocation:
    1. Static CIDR: Uses cidr field (explicit CIDR block)
    2. IPAM: Uses ipv4IpamPoolId and ipv4NetmaskLength (dynamic allocation)

    These modes are mutually exclusive. IPAM mode is used when ipv4IpamPoolId is provided.

    Args:
        config: Configuration object containing:
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - cidr: Static CIDR block for the VPC (optional, mutually exclusive with IPAM)
            - ipv4IpamPoolId: IPAM pool ID for dynamic CIDR allocation (optional)
            - ipv4NetmaskLength: Netmask length for IPAM allocation (optional)
            - region: AWS region
            - enableDnsHostnames: Enable DNS hostnames
            - enableDnsSupport: Enable DNS support

    Returns:
        List containing the VPC resource
    """
    # Build base forProvider with common fields (always present)
    baseForProvider = {
        region = config.region
        enableDnsHostnames = config.enableDnsHostnames
        enableDnsSupport = config.enableDnsSupport
        tags = config.tags | {
            Name = config.vpcName
        }
    }

    # Add IPv4 CIDR configuration based on mode (static vs IPAM)
    # Pattern 11: Complex Conditional Logic - use imperative approach for readability
    # Two modes: IPAM (ipv4IpamPoolId) or Static (cidrBlock)
    ipv4CidrConfig = {}
    if config.ipv4IpamPoolId:
        # IPAM mode: Use IPAM pool for dynamic CIDR allocation
        ipv4CidrConfig = {ipv4IpamPoolId = config.ipv4IpamPoolId}
        # Add netmask length if specified (optional in IPAM mode)
        if config.ipv4NetmaskLength:
            ipv4CidrConfig = ipv4CidrConfig | {ipv4NetmaskLength = config.ipv4NetmaskLength}
    else:
        # Static mode: Use explicit CIDR block
        ipv4CidrConfig = {cidrBlock = config.cidr}

    # Add IPv6 CIDR configuration if IPv6 is enabled
    # Pattern 10: Optional Field Handling - conditional dict merging
    ipv6CidrConfig = {}
    if config.enableIpv6:
        if config.ipv6IpamPoolId:
            # IPv6 IPAM mode: Use IPAM pool for IPv6 allocation
            ipv6CidrConfig = {ipv6IpamPoolId = config.ipv6IpamPoolId}
            if config.ipv6NetmaskLength:
                ipv6CidrConfig = ipv6CidrConfig | {ipv6NetmaskLength = config.ipv6NetmaskLength}
        elif config.ipv6CidrBlock:
            # Custom IPv6 CIDR block
            ipv6CidrConfig = {ipv6CidrBlock = config.ipv6CidrBlock}
        elif config.assignGeneratedIpv6CidrBlock:
            # Amazon-provided IPv6 CIDR block (default)
            ipv6CidrConfig = {assignGeneratedIpv6CidrBlock = True}

    # Merge base config with IPv4 and IPv6 CIDR configuration
    forProvider = baseForProvider | ipv4CidrConfig | ipv6CidrConfig

    [
        ec2v1beta1.VPC{
            metadata = config.metadata("vpc") | {
                name = "vpc-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = forProvider
            }
        }
    ]
}

# Public function to generate VPC and secondary CIDR blocks
generateVPCResources = lambda config: {str: any} -> [any] {
    """
    Generates VPC and secondary CIDR block association resources.

    Args:
        config: Configuration object (see _generateVPC and _generateSecondaryCidrBlocks)

    Returns:
        List containing VPC and VPCIPv4CidrBlockAssociation resources
    """
    _generateVPC(config) + _generateSecondaryCidrBlocks(config)
}
