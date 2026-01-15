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
    # Build forProvider dictionary conditionally to avoid passing null values
    _baseForProvider = {
        region = config.region
        tags = config.tags | {
            Name = "${config.vpcName}-dhcp-options"
        }
    }

    # Conditionally add optional fields only if they have valid values
    # This prevents passing null/None which causes Kubernetes validation errors
    _forProviderWithOptionals = _baseForProvider | ({domainName = config.dhcpOptionsDomainName} if config.dhcpOptionsDomainName else {}) | ({domainNameServers = config.dhcpOptionsDomainNameServers} if config.dhcpOptionsDomainNameServers and len(config.dhcpOptionsDomainNameServers) > 0 else {}) | ({ntpServers = config.dhcpOptionsNtpServers} if config.dhcpOptionsNtpServers and len(config.dhcpOptionsNtpServers) > 0 else {}) | ({netbiosNameServers = config.dhcpOptionsNetbiosNameServers} if config.dhcpOptionsNetbiosNameServers and len(config.dhcpOptionsNetbiosNameServers) > 0 else {}) | ({netbiosNodeType = str(config.dhcpOptionsNetbiosNodeType)} if config.dhcpOptionsNetbiosNodeType != None else {})

    [
        ec2v1beta1.VPCDHCPOptions{
            metadata = config.metadata("dhcp-options") | {
                name = "dhcp-options-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = _forProviderWithOptionals
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
