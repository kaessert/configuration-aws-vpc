"""
Subnets Module

This module handles generation of all subnet types:
- Public subnets (with public IP mapping)
- Private subnets
- Database subnets
- ElastiCache subnets
- Redshift subnets
- Intra (isolated) subnets
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

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
                labels = config.tags | config.publicSubnetTags | {
                    "subnet-type": "public"
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
                }
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
                labels = config.tags | config.privateSubnetTags | {
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
                }
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
                labels = config.tags | config.databaseSubnetTags | {
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
                }
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
                labels = config.tags | config.elasticacheSubnetTags | {
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
                }
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
                labels = config.tags | config.redshiftSubnetTags | {
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
                }
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
                labels = config.tags | config.intraSubnetTags | {
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
                }
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
