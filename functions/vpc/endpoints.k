"""
VPC Endpoints Module

This module handles generation of VPC Endpoints:
- S3 Gateway Endpoint
- DynamoDB Gateway Endpoint
- Interface VPC Endpoints (PrivateLink) for AWS services
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Generate S3 Gateway Endpoint
generateS3Endpoint = lambda config: {str: any} -> [any] {
    """
    Generates the S3 VPC Endpoint resource.

    Args:
        config: Configuration object containing:
            - enableS3Endpoint: Whether to create the S3 endpoint
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - vpcEndpointTags: Additional tags for VPC endpoints
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region
            - s3EndpointType: Type of S3 endpoint (Gateway or Interface)

    Returns:
        List containing the S3 endpoint resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPCEndpoint{
            metadata = config.metadata("vpce-s3") | {
                name = "vpce-s3-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    serviceName = "com.amazonaws.${config.region}.s3"
                    vpcEndpointType = config.s3EndpointType
                    tags = config.tags | config.vpcEndpointTags | {
                        Name = "vpce-s3-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.enableS3Endpoint else []
}

# Generate DynamoDB Gateway Endpoint
generateDynamoDBEndpoint = lambda config: {str: any} -> [any] {
    """
    Generates the DynamoDB VPC Endpoint resource.

    Args:
        config: Configuration object containing:
            - enableDynamodbEndpoint: Whether to create the DynamoDB endpoint
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - tags: Tags to apply
            - vpcEndpointTags: Additional tags for VPC endpoints
            - defaultV2Spec: Default v2 spec configuration
            - region: AWS region

    Returns:
        List containing the DynamoDB endpoint resource (or empty list if disabled)
    """
    [
        ec2v1beta1.VPCEndpoint{
            metadata = config.metadata("vpce-dynamodb") | {
                name = "vpce-dynamodb-${config.vpcName}"
                labels = config.tags
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    serviceName = "com.amazonaws.${config.region}.dynamodb"
                    vpcEndpointType = "Gateway"
                    tags = config.tags | config.vpcEndpointTags | {
                        Name = "vpce-dynamodb-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.enableDynamodbEndpoint else []
}

# ========================================
# INTERFACE VPC ENDPOINTS (PRIVATELINK)
# ========================================

# Generate single Interface Endpoint for a service
_generateInterfaceEndpointForService = lambda config, service: str -> any {
    """
    Generates a single Interface VPC Endpoint for a given AWS service.

    NOTE: Due to Upbound provider schema limitations, security groups cannot be
    specified. Endpoints will use the VPC's default security group (AWS behavior).

    Args:
        config: Configuration object
        service: AWS service name (e.g., "ec2", "ssm", "rds")

    Returns:
        VPCEndpoint resource for the specified service
    """
    # Build subnet configuration using subnetConfiguration array
    # Use private subnet selectors
    subnetConfig = {
        subnetConfiguration = [
            {
                subnetIdSelector = {
                    matchControllerRef = True
                    matchLabels = {
                        "subnet-type": "private"
                    }
                }
            }
        ]
    }

    # Build endpoint policy configuration (optional)
    policyConfig = {
        policy = config.interfaceEndpointPolicies[service]
    } if service in config.interfaceEndpointPolicies else {}

    ec2v1beta1.VPCEndpoint{
        metadata = config.metadata("vpce-${service}") | {
            name = "vpce-${service}-${config.vpcName}"
            labels = config.sanitizeLabels(config.tags)
        }
        spec = config.defaultV2Spec | {
            forProvider = {
                region = config.region
                vpcIdSelector = {
                    matchControllerRef = True
                }
                serviceName = "com.amazonaws.${config.region}.${service}"
                vpcEndpointType = "Interface"
                privateDnsEnabled = config.enableInterfaceEndpointPrivateDns
                tags = config.tags | config.vpcEndpointTags | {
                    Name = "vpce-${service}-${config.vpcName}"
                    Service = service
                }
            } | subnetConfig | policyConfig
        }
    }
}

# Generate all Interface Endpoints
generateInterfaceEndpoints = lambda config: {str: any} -> [any] {
    """
    Generates all Interface VPC Endpoint resources.

    NOTE: Security group support is not available in the current Upbound provider schema.
    Endpoints will automatically use the VPC's default security group.

    Args:
        config: Configuration object containing:
            - enableInterfaceEndpoints: Whether to create Interface endpoints
            - interfaceEndpointServices: List of AWS service names
            - enableInterfaceEndpointPrivateDns: Whether to enable private DNS
            - interfaceEndpointPolicies: Map of service to policy JSON (optional)

    Returns:
        List of all Interface VPC Endpoint resources
    """
    # Generate Interface endpoint for each service
    [
        _generateInterfaceEndpointForService(config, service)
        for service in config.interfaceEndpointServices
    ] if config.enableInterfaceEndpoints and len(config.interfaceEndpointServices) > 0 else []
}

# Generate all VPC Endpoints
generateAllEndpoints = lambda config: {str: any} -> [any] {
    """
    Generates all VPC Endpoint resources.

    Args:
        config: Configuration object containing all endpoint parameters

    Returns:
        List of all VPC Endpoint resources (Gateway and Interface)
    """
    generateS3Endpoint(config) + \
    generateDynamoDBEndpoint(config) + \
    generateInterfaceEndpoints(config)
}
