"""
Customer Gateway Module

This module handles generation of Customer Gateway resources.
Customer Gateways represent the customer side of VPN connections.
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Helper to build forProvider for a Customer Gateway
_buildForProvider = lambda gatewayName: str, config: {str: any} -> {str: any} {
    """Builds the forProvider configuration for a Customer Gateway."""
    gatewayConfig = config.customerGateways[gatewayName]

    # Start with required and common fields
    forProvider = {
        ipAddress: gatewayConfig.ipAddress if gatewayConfig.ipAddress else ""
        type: gatewayConfig.type if gatewayConfig.type else "ipsec.1"
        region: config.region
        tags: config.tags | (gatewayConfig.tags if gatewayConfig.tags else {}) | {
            Name: "cgw-${gatewayName}-${config.vpcName}"
        }
    }

    # Add BGP ASN (standard or extended, but not both)
    if gatewayConfig.bgpAsnExtended:
        forProvider = forProvider | {bgpAsnExtended: str(gatewayConfig.bgpAsnExtended)}
    elif gatewayConfig.bgpAsn:
        forProvider = forProvider | {bgpAsn: str(gatewayConfig.bgpAsn)}

    # Add device name if specified
    if gatewayConfig.deviceName:
        forProvider = forProvider | {deviceName: gatewayConfig.deviceName}

    # Add certificate ARN if specified
    if gatewayConfig.certificateArn:
        forProvider = forProvider | {certificateArn: gatewayConfig.certificateArn}

    forProvider
}

# Generate Customer Gateway resources
generateCustomerGateways = lambda config: {str: any} -> [any] {
    """
    Generates Customer Gateway resources.

    Args:
        config: Configuration object containing:
            - customerGateways: Map of gateway name to configuration {
                bgpAsn: BGP ASN (1-2147483647, conflicts with bgpAsnExtended)
                bgpAsnExtended: Extended BGP ASN (2147483648-4294967295, conflicts with bgpAsn)
                ipAddress: IPv4 address for the customer gateway device
                type: VPN connection type (only ipsec.1 supported)
                deviceName: Name for the customer gateway device (optional)
                certificateArn: ARN for certificate-based auth (optional)
                tags: Additional tags for this gateway (optional)
              }
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Common tags to apply
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List of Customer Gateway resources
    """

    # Convert customerGateways map to list of resources
    [
        ec2v1beta1.CustomerGateway{
            metadata = config.metadata("cgw-${gatewayName}") | {
                name = "cgw-${gatewayName}-${config.vpcName}"
                labels = config.tags | {"cgw-name": gatewayName}
            }
            spec = config.defaultV2Spec | {
                forProvider = _buildForProvider(gatewayName, config)
            }
        }
        for gatewayName in config.customerGateways
    ] if config.customerGateways else []
}
