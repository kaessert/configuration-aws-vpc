"""
Subnets Module

This module handles generation of all subnet types:
- Public subnets (with public IP mapping)
- Private subnets
- Database subnets
- ElastiCache subnets
- Redshift subnets
- Intra (isolated) subnets

Supports both IPv4 and IPv6 configurations.
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Helper function to build IPv6 configuration for subnets
_buildIpv6Config = lambda config, i: int, prefixList: [int] -> {str: any} {
    """
    Builds IPv6 configuration fields for a subnet.

    Args:
        config: Configuration object containing IPv6 settings
        i: Index of the subnet
        prefixList: List of IPv6 prefixes for this subnet type

    Returns:
        Dictionary with IPv6 configuration fields (empty if IPv6 disabled)
    """
    ipv6Config = {}

    if config.enableIpv6:
        # AWS auto-assigns IPv6 CIDR blocks from the VPC's IPv6 CIDR range
        # We don't need to explicitly set ipv6CidrBlock - AWS handles allocation

        # Add assignIpv6AddressOnCreation flag
        if config.assignIpv6AddressOnCreation:
            ipv6Config = ipv6Config | {assignIpv6AddressOnCreation = True}

        # Add IPv6-native configuration
        # For dual-stack mode (IPv4 + IPv6), explicitly set ipv6Native = False
        # For IPv6-only mode, set ipv6Native = True
        ipv6Config = ipv6Config | {ipv6Native = config.ipv6Native if config.ipv6Native else False}

        # IPv6-native subnets typically need DNS64
        if config.ipv6Native and config.enableDns64:
            ipv6Config = ipv6Config | {enableDns64 = True}

        # For IPv6-native subnets, set DNS configuration defaults
        if config.ipv6Native:
            # Enable AAAA record for IPv6-native subnets
            ipv6Config = ipv6Config | {enableResourceNameDnsAaaaRecordOnLaunch = True}
            # Set DNS hostname type to resource-name for IPv6-native subnets
            ipv6Config = ipv6Config | {privateDnsHostnameTypeOnLaunch = "resource-name"}
        else:
            # For dual-stack mode, only add if explicitly configured
            if config.enableResourceNameDnsAaaaRecordOnLaunch:
                ipv6Config = ipv6Config | {enableResourceNameDnsAaaaRecordOnLaunch = True}
            if config.privateDnsHostnameTypeOnLaunch:
                ipv6Config = ipv6Config | {privateDnsHostnameTypeOnLaunch = config.privateDnsHostnameTypeOnLaunch}

    ipv6Config
}

# Generate public subnets distributed across AZs
_generatePublicSubnets = lambda config: {str: any} -> [any] {
    """
    Generates public subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of public subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("public-subnet-${i}") | {
                name = "subnet-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.publicSubnetTags) | {
                    "subnet-type": "public"
                    "subnet-index": str(i)
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = config.mapPublicIpOnLaunch
                    region = config.region
                    tags = config.tags | config.publicSubnetTags | {
                        Name = "subnet-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "public"
                    }
                } | _buildIpv6Config(config, i, config.publicSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.publicSubnets
    ] if len(config.publicSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate private subnets distributed across AZs
_generatePrivateSubnets = lambda config: {str: any} -> [any] {
    """
    Generates private subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of private subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("private-subnet-${i}") | {
                name = "subnet-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.privateSubnetTags) | {
                    "subnet-type": "private"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.privateSubnetTags | {
                        Name = "subnet-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "private"
                    }
                } | _buildIpv6Config(config, i, config.privateSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.privateSubnets
    ] if len(config.privateSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate database subnets distributed across AZs
_generateDatabaseSubnets = lambda config: {str: any} -> [any] {
    """
    Generates database subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of database subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("database-subnet-${i}") | {
                name = "subnet-database-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.databaseSubnetTags) | {
                    "subnet-type": "database"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.databaseSubnetTags | {
                        Name = "subnet-database-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "database"
                    }
                } | _buildIpv6Config(config, i, config.databaseSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.databaseSubnets
    ] if len(config.databaseSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate elasticache subnets distributed across AZs
_generateElasticacheSubnets = lambda config: {str: any} -> [any] {
    """
    Generates ElastiCache subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of elasticache subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("elasticache-subnet-${i}") | {
                name = "subnet-elasticache-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.elasticacheSubnetTags) | {
                    "subnet-type": "elasticache"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.elasticacheSubnetTags | {
                        Name = "subnet-elasticache-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "elasticache"
                    }
                } | _buildIpv6Config(config, i, config.elasticacheSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.elasticacheSubnets
    ] if len(config.elasticacheSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate redshift subnets distributed across AZs
_generateRedshiftSubnets = lambda config: {str: any} -> [any] {
    """
    Generates Redshift subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of redshift subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("redshift-subnet-${i}") | {
                name = "subnet-redshift-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.redshiftSubnetTags) | {
                    "subnet-type": "redshift"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.redshiftSubnetTags | {
                        Name = "subnet-redshift-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "redshift"
                    }
                } | _buildIpv6Config(config, i, config.redshiftSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.redshiftSubnets
    ] if len(config.redshiftSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate intra (isolated) subnets distributed across AZs
_generateIntraSubnets = lambda config: {str: any} -> [any] {
    """
    Generates intra (isolated) subnets distributed across availability zones.
    These subnets have no route to the internet (no IGW or NAT Gateway).

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of intra subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("intra-subnet-${i}") | {
                name = "subnet-intra-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.intraSubnetTags) | {
                    "subnet-type": "intra"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.intraSubnetTags | {
                        Name = "subnet-intra-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "intra"
                    }
                } | _buildIpv6Config(config, i, config.intraSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.intraSubnets
    ] if len(config.intraSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate all subnets
generateAllSubnets = lambda config: {str: any} -> [any] {
    """
    Generates all subnet types.

    Args:
        config: Configuration object containing all subnet parameters

    Returns:
        List of all subnet resources
    """
    _generatePublicSubnets(config) + \
    _generatePrivateSubnets(config) + \
    _generateDatabaseSubnets(config) + \
    _generateElasticacheSubnets(config) + \
    _generateRedshiftSubnets(config) + \
    _generateIntraSubnets(config)
}
