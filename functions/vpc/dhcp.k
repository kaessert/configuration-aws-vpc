"""
DHCP Options Module

This module handles generation of DHCP Options resources:
- DHCP Options Set
- DHCP Options Association with VPC
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Generate DHCP Options resource
generateDHCPOptions = lambda config: {str: any} -> [any] {
    """
    Generates the DHCP Options resource.

    Args:
        config: Configuration object containing:
            - enableDhcpOptions: Whether to create DHCP options
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region
            - dhcpOptionsDomainName: Domain name for DHCP options
            - dhcpOptionsDomainNameServers: List of DNS servers
            - dhcpOptionsNtpServers: List of NTP servers
            - dhcpOptionsNetbiosNameServers: List of NetBIOS name servers
            - dhcpOptionsNetbiosNodeType: NetBIOS node type

    Returns:
        List containing the DHCP Options resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPCDHCPOptions{
            metadata = config.metadata("dhcp-options") | {
                name = "dhcp-options-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    domainName = config.dhcpOptionsDomainName if config.dhcpOptionsDomainName else None
                    domainNameServers = config.dhcpOptionsDomainNameServers if len(config.dhcpOptionsDomainNameServers) > 0 else None
                    ntpServers = config.dhcpOptionsNtpServers if len(config.dhcpOptionsNtpServers) > 0 else None
                    netbiosNameServers = config.dhcpOptionsNetbiosNameServers if len(config.dhcpOptionsNetbiosNameServers) > 0 else None
                    netbiosNodeType = str(config.dhcpOptionsNetbiosNodeType) if config.dhcpOptionsNetbiosNodeType != None else None
                    tags = config.tags | {
                        Name = "${config.vpcName}-dhcp-options"
                    }
                }
            }
        }
    ] if config.enableDhcpOptions else []
}

# Generate DHCP Options Association resource
generateDHCPOptionsAssociation = lambda config: {str: any} -> [any] {
    """
    Generates the DHCP Options Association resource.

    Args:
        config: Configuration object containing:
            - enableDhcpOptions: Whether to create DHCP options association
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List containing the DHCP Options Association resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPCDHCPOptionsAssociation{
            metadata = config.metadata("dhcp-association") | {
                name = "dhcp-association-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    dhcpOptionsIdSelector = {
                        matchControllerRef = True
                    }
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                }
            }
        }
    ] if config.enableDhcpOptions else []
}

# Generate all DHCP resources
generateAllDHCP = lambda config: {str: any} -> [any] {
    """
    Generates all DHCP Options resources.

    Args:
        config: Configuration object containing all DHCP parameters

    Returns:
        List of all DHCP Options resources
    """
    generateDHCPOptions(config) + \
    generateDHCPOptionsAssociation(config)
}
