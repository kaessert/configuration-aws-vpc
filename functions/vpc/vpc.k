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

    Args:
        config: Configuration object containing:
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - cidr: CIDR block for the VPC
            - region: AWS region
            - enableDnsHostnames: Enable DNS hostnames
            - enableDnsSupport: Enable DNS support

    Returns:
        List containing the VPC resource
    """
    [
        ec2v1beta1.VPC{
            metadata = config.metadata("vpc") | {
                name = "vpc-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    cidrBlock = config.cidr
                    region = config.region
                    enableDnsHostnames = config.enableDnsHostnames
                    enableDnsSupport = config.enableDnsSupport
                    tags = config.tags | {
                        Name = config.vpcName
                    }
                }
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
