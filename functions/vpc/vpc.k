"""
VPC Core Module

This module handles the core VPC resource creation.
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

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
