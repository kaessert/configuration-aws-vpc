"""
Routing Module

This module handles generation of:
- Route tables (public, private, database, intra)
- Routes (to IGW, NAT Gateway)
- Route table associations with subnets
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# ============================================================================
# PUBLIC ROUTING
# ============================================================================

# Generate public route table (single shared or per-AZ)
_generatePublicRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the public route table(s).

    If onePublicRouteTablePerAz is True: creates one table per AZ
    Otherwise: creates one shared table for all public subnets

    Args:
        config: Configuration object

    Returns:
        List containing the public route table resource(s)
    """
    # Per-AZ public route tables
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("public-route-table-${i}") | {
                name = "rtb-public-${config.vpcName}-${config.azs[i]}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "public"
                    "az": config.azs[i]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-public-${config.vpcName}-${config.azs[i]}"
                        Type = "public"
                        AZ = config.azs[i]
                    }
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.publicSubnets) > 0 and config.onePublicRouteTablePerAz else [
        # Single shared public route table
        ec2v1beta1.RouteTable{
            metadata = config.metadata("public-route-table") | {
                name = "rtb-public-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "public"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-public-${config.vpcName}"
                        Type = "public"
                    }
                }
            }
        }
    ] if len(config.publicSubnets) > 0 else []
}

# Generate public route to Internet Gateway (IPv4)
_generatePublicRoute = lambda config: {str: any} -> [any] {
    """
    Generates the public route(s) to the Internet Gateway (IPv4).

    If onePublicRouteTablePerAz is True: creates one route per AZ route table
    Otherwise: creates one route for the shared route table

    Args:
        config: Configuration object

    Returns:
        List containing the public route resource(s)
    """
    # Per-AZ public routes
    [
        ec2v1beta1.Route{
            metadata = config.metadata("public-route-igw-${i}") | {
                name = "route-public-igw-${config.vpcName}-${config.azs[i]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "public"
                            "az": config.azs[i]
                        }
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.publicSubnets) > 0 and config.createIgw and config.onePublicRouteTablePerAz else [
        # Single shared public route
        ec2v1beta1.Route{
            metadata = config.metadata("public-route-igw") | {
                name = "route-public-igw-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "public"
                        }
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
    ] if len(config.publicSubnets) > 0 and config.createIgw else []
}

# Generate public route to Internet Gateway (IPv6)
_generatePublicRouteIpv6 = lambda config: {str: any} -> [any] {
    """
    Generates the public IPv6 route(s) (::/0) to the Internet Gateway.

    If onePublicRouteTablePerAz is True: creates one IPv6 route per AZ route table
    Otherwise: creates one IPv6 route for the shared route table

    Args:
        config: Configuration object

    Returns:
        List containing the public IPv6 route resource(s)
    """
    # Per-AZ public IPv6 routes
    [
        ec2v1beta1.Route{
            metadata = config.metadata("public-route-ipv6-${i}") | {
                name = "route-public-ipv6-${config.vpcName}-${config.azs[i]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "public"
                            "az": config.azs[i]
                        }
                        matchControllerRef = True
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationIpv6CidrBlock = "::/0"
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.publicSubnets) > 0 and config.createIgw and config.enableIpv6 and config.onePublicRouteTablePerAz else [
        # Single shared public IPv6 route
        ec2v1beta1.Route{
            metadata = config.metadata("public-route-ipv6") | {
                name = "route-public-ipv6-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "public"
                        }
                        matchControllerRef = True
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationIpv6CidrBlock = "::/0"
                }
            }
        }
    ] if len(config.publicSubnets) > 0 and config.createIgw and config.enableIpv6 else []
}

# Generate public route table associations
_generatePublicRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for public subnets.

    If onePublicRouteTablePerAz is True: associates each subnet with its AZ-specific route table
    Otherwise: associates all subnets with the shared route table

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("public-rtb-assoc-${i}") | {
                name = "rtb-assoc-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "public"
                            "az": config.azs[i % len(config.azs)]
                        } if config.onePublicRouteTablePerAz else {
                            "route-table-type": "public"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "public"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.publicSubnets))
    ] if len(config.publicSubnets) > 0 else []
}

# ============================================================================
# PRIVATE ROUTING
# ============================================================================

# Generate private route tables
_generatePrivateRouteTables = lambda config: {str: any} -> [any] {
    """
    Generates private route tables.

    For single NAT: one shared route table for all private subnets
    For NAT per AZ: one route table per AZ

    Args:
        config: Configuration object

    Returns:
        List of private route table resources
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("private-route-table-${i}") | {
                name = "rtb-private-${config.vpcName}-${config.azs[i]}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "private"
                    "az": config.azs[i]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-private-${config.vpcName}-${config.azs[i]}"
                        Type = "private"
                        AZ = config.azs[i]
                    }
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway and config.oneNatGatewayPerAz else [
        # Single route table for all private subnets (single NAT strategy)
        ec2v1beta1.RouteTable{
            metadata = config.metadata("private-route-table") | {
                name = "rtb-private-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "private"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-private-${config.vpcName}"
                        Type = "private"
                    }
                }
            }
        }
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway else []
}

# Generate private routes to NAT Gateway
_generatePrivateRoutes = lambda config: {str: any} -> [any] {
    """
    Generates private routes to NAT Gateway.

    Args:
        config: Configuration object

    Returns:
        List of private route resources
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("private-route-nat-${i}") | {
                name = "route-private-nat-${config.vpcName}-${config.azs[i]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                            "az": config.azs[i]
                        }
                    }
                    natGatewayIdSelector = {
                        matchLabels = {
                            "az": config.azs[i]
                        }
                    }
                    region = config.region
                    destinationCidrBlock = config.natGatewayDestinationCidrBlock
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway and config.oneNatGatewayPerAz else [
        # Single route for single NAT Gateway strategy
        ec2v1beta1.Route{
            metadata = config.metadata("private-route-nat") | {
                name = "route-private-nat-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                        }
                    }
                    natGatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = config.natGatewayDestinationCidrBlock
                }
            }
        }
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway and config.singleNatGateway else []
}

# Generate private IPv6 routes to Egress-Only Internet Gateway
_generatePrivateRoutesIpv6 = lambda config: {str: any} -> [any] {
    """
    Generates private IPv6 routes (::/0) to Egress-Only Internet Gateway.

    Args:
        config: Configuration object

    Returns:
        List of private IPv6 route resources
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("private-route-ipv6-${i}") | {
                name = "route-private-ipv6-${config.vpcName}-${config.azs[i]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                            "az": config.azs[i]
                        }
                        matchControllerRef = True
                    }
                    egressOnlyGatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationIpv6CidrBlock = "::/0"
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.privateSubnets) > 0 and config.createEgressOnlyIgw and config.enableIpv6 and config.oneNatGatewayPerAz else [
        # Single route for single NAT Gateway strategy
        ec2v1beta1.Route{
            metadata = config.metadata("private-route-ipv6") | {
                name = "route-private-ipv6-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                        }
                        matchControllerRef = True
                    }
                    egressOnlyGatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationIpv6CidrBlock = "::/0"
                }
            }
        }
    ] if len(config.privateSubnets) > 0 and config.createEgressOnlyIgw and config.enableIpv6 else []
}

# Generate private route table associations
_generatePrivateRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for private subnets.

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("private-rtb-assoc-${i}") | {
                name = "rtb-assoc-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "private"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.privateSubnets))
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway and config.oneNatGatewayPerAz else [
        # Single route table for single NAT strategy
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("private-rtb-assoc-${i}") | {
                name = "rtb-assoc-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "private"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "private"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.privateSubnets))
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway else []
}

# ============================================================================
# DATABASE ROUTING
# ============================================================================

# Generate database route table
_generateDatabaseRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the database route table.

    Args:
        config: Configuration object

    Returns:
        List containing the database route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("database-route-table") | {
                name = "rtb-database-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "database"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-database-${config.vpcName}"
                        Type = "database"
                    }
                }
            }
        }
    ] if len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable else []
}

# Generate database route to NAT Gateway
_generateDatabaseRoute = lambda config: {str: any} -> [any] {
    """
    Generates the database route to NAT Gateway (optional).

    Args:
        config: Configuration object

    Returns:
        List containing the database route resource
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("database-route-nat") | {
                name = "route-database-nat-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "database"
                        }
                    }
                    natGatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = config.natGatewayDestinationCidrBlock
                }
            }
        }
    ] if len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable and config.createDatabaseNatGatewayRoute and config.enableNatGateway else []
}

# Generate database route to Internet Gateway
_generateDatabaseRouteIgw = lambda config: {str: any} -> [any] {
    """
    Generates the database route to Internet Gateway (WARNING: enables public access).

    Args:
        config: Configuration object

    Returns:
        List containing the database IGW route resource
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("database-route-igw") | {
                name = "route-database-igw-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "database"
                        }
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
    ] if len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable and config.createDatabaseInternetGatewayRoute and config.createIgw else []
}

# Generate database route table associations
_generateDatabaseRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for database subnets.

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("database-rtb-assoc-${i}") | {
                name = "rtb-assoc-database-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "database"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "database"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.databaseSubnets))
    ] if len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable else []
}

# ============================================================================
# INTRA (ISOLATED) ROUTING
# ============================================================================

# Generate intra route table (single shared or per-AZ)
_generateIntraRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the intra (isolated) route table(s).
    Note: No routes are added - intra subnets are fully isolated.

    If oneIntraRouteTablePerAz is True: creates one table per AZ for enhanced isolation
    Otherwise: creates one shared table for all intra subnets

    Args:
        config: Configuration object

    Returns:
        List containing the intra route table resource(s)
    """
    # Per-AZ intra route tables
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("intra-route-table-${i}") | {
                name = "rtb-intra-${config.vpcName}-${config.azs[i]}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "intra"
                    "az": config.azs[i]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-intra-${config.vpcName}-${config.azs[i]}"
                        Type = "intra"
                        AZ = config.azs[i]
                    }
                }
            }
        }
        for i in range(len(config.azs))
    ] if len(config.intraSubnets) > 0 and config.oneIntraRouteTablePerAz else [
        # Single shared intra route table
        ec2v1beta1.RouteTable{
            metadata = config.metadata("intra-route-table") | {
                name = "rtb-intra-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "intra"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-intra-${config.vpcName}"
                        Type = "intra"
                    }
                }
            }
        }
    ] if len(config.intraSubnets) > 0 else []
}

# Generate intra route table associations
_generateIntraRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for intra subnets.

    If oneIntraRouteTablePerAz is True: associates each subnet with its AZ-specific route table
    Otherwise: associates all subnets with the shared route table

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("intra-rtb-assoc-${i}") | {
                name = "rtb-assoc-intra-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "intra"
                            "az": config.azs[i % len(config.azs)]
                        } if config.oneIntraRouteTablePerAz else {
                            "route-table-type": "intra"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "intra"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.intraSubnets))
    ] if len(config.intraSubnets) > 0 else []
}

# ============================================================================
# ELASTICACHE ROUTING
# ============================================================================

# Generate ElastiCache route table
_generateElasticacheRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the ElastiCache route table.

    Args:
        config: Configuration object

    Returns:
        List containing the ElastiCache route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("elasticache-route-table") | {
                name = "rtb-elasticache-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "elasticache"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-elasticache-${config.vpcName}"
                        Type = "elasticache"
                    }
                }
            }
        }
    ] if len(config.elasticacheSubnets) > 0 and config.createElasticacheSubnetRouteTable else []
}

# Generate ElastiCache route to NAT Gateway
_generateElasticacheRoute = lambda config: {str: any} -> [any] {
    """
    Generates the ElastiCache route to NAT Gateway (optional).
    For single NAT: routes to NAT in first AZ
    For per-AZ NAT: routes to NAT in first AZ (shared)

    Args:
        config: Configuration object

    Returns:
        List containing the ElastiCache route resource
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("elasticache-route-nat") | {
                name = "route-elasticache-nat-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "elasticache"
                        }
                    }
                    natGatewayIdSelector = {
                        matchLabels = {
                            "az": config.azs[0]
                        }
                    }
                    region = config.region
                    destinationCidrBlock = config.natGatewayDestinationCidrBlock
                }
            }
        }
    ] if len(config.elasticacheSubnets) > 0 and config.createElasticacheSubnetRouteTable and config.createElasticacheNatGatewayRoute and config.enableNatGateway and len(config.azs) > 0 else []
}

# Generate ElastiCache route table associations
_generateElasticacheRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for ElastiCache subnets.

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("elasticache-rtb-assoc-${i}") | {
                name = "rtb-assoc-elasticache-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "elasticache"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "elasticache"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.elasticacheSubnets))
    ] if len(config.elasticacheSubnets) > 0 and config.createElasticacheSubnetRouteTable else []
}

# ============================================================================
# REDSHIFT ROUTING
# ============================================================================

# Generate Redshift private route table (with NAT)
_generateRedshiftRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the Redshift route table (private routing with NAT).

    Args:
        config: Configuration object

    Returns:
        List containing the Redshift route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("redshift-route-table") | {
                name = "rtb-redshift-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "redshift"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-redshift-${config.vpcName}"
                        Type = "redshift"
                    }
                }
            }
        }
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftSubnetRouteTable else []
}

# Generate Redshift route to NAT Gateway
_generateRedshiftRoute = lambda config: {str: any} -> [any] {
    """
    Generates the Redshift route to NAT Gateway (optional).
    For single NAT: routes to NAT in first AZ
    For per-AZ NAT: routes to NAT in first AZ (shared)

    Args:
        config: Configuration object

    Returns:
        List containing the Redshift route resource
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("redshift-route-nat") | {
                name = "route-redshift-nat-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "redshift"
                        }
                    }
                    natGatewayIdSelector = {
                        matchLabels = {
                            "az": config.azs[0]
                        }
                    }
                    region = config.region
                    destinationCidrBlock = config.natGatewayDestinationCidrBlock
                }
            }
        }
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftSubnetRouteTable and config.createRedshiftNatGatewayRoute and config.enableNatGateway and len(config.azs) > 0 else []
}

# Generate Redshift route table associations
_generateRedshiftRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for Redshift subnets (private routing).

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("redshift-rtb-assoc-${i}") | {
                name = "rtb-assoc-redshift-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "redshift"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "redshift"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.redshiftSubnets))
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftSubnetRouteTable else []
}

# Generate Redshift public route table (with IGW)
_generateRedshiftPublicRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the Redshift public route table (public routing with IGW).

    Args:
        config: Configuration object

    Returns:
        List containing the Redshift public route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("redshift-public-route-table") | {
                name = "rtb-redshift-public-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags) | {
                    "route-table-type": "redshift-public"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    tags = config.tags | {
                        Name = "rtb-redshift-public-${config.vpcName}"
                        Type = "redshift-public"
                    }
                }
            }
        }
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftPublicSubnetRouteTable else []
}

# Generate Redshift public route to IGW
_generateRedshiftPublicRoute = lambda config: {str: any} -> [any] {
    """
    Generates the Redshift public route to Internet Gateway.

    Args:
        config: Configuration object

    Returns:
        List containing the Redshift public route resource
    """
    [
        ec2v1beta1.Route{
            metadata = config.metadata("redshift-public-route-igw") | {
                name = "route-redshift-public-igw-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "redshift-public"
                        }
                    }
                    gatewayIdSelector = {
                        matchControllerRef = True
                    }
                    region = config.region
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftPublicSubnetRouteTable and config.enablePublicRedshift and config.createIgw else []
}

# Generate Redshift public route table associations
_generateRedshiftPublicRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for Redshift subnets (public routing).

    Args:
        config: Configuration object

    Returns:
        List of route table association resources
    """
    [
        ec2v1beta1.RouteTableAssociation{
            metadata = config.metadata("redshift-public-rtb-assoc-${i}") | {
                name = "rtb-assoc-redshift-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    routeTableIdSelector = {
                        matchLabels = {
                            "route-table-type": "redshift-public"
                        }
                    }
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type": "redshift"
                            "az": config.azs[i % len(config.azs)]
                        }
                    }
                    region = config.region
                }
            }
        }
        for i in range(len(config.redshiftSubnets))
    ] if len(config.redshiftSubnets) > 0 and config.createRedshiftPublicSubnetRouteTable else []
}

# ============================================================================
# MAIN ROUTING GENERATOR
# ============================================================================

# Generate all routing resources
generateAllRouting = lambda config: {str: any} -> [any] {
    """
    Generates all routing resources (route tables, routes, associations).

    Args:
        config: Configuration object containing all routing parameters

    Returns:
        List of all routing resources
    """
    _generatePublicRouteTable(config) + \
    _generatePublicRoute(config) + \
    _generatePublicRouteIpv6(config) + \
    _generatePublicRouteTableAssociations(config) + \
    _generatePrivateRouteTables(config) + \
    _generatePrivateRoutes(config) + \
    _generatePrivateRoutesIpv6(config) + \
    _generatePrivateRouteTableAssociations(config) + \
    _generateDatabaseRouteTable(config) + \
    _generateDatabaseRoute(config) + \
    _generateDatabaseRouteIgw(config) + \
    _generateDatabaseRouteTableAssociations(config) + \
    _generateElasticacheRouteTable(config) + \
    _generateElasticacheRoute(config) + \
    _generateElasticacheRouteTableAssociations(config) + \
    _generateRedshiftRouteTable(config) + \
    _generateRedshiftRoute(config) + \
    _generateRedshiftRouteTableAssociations(config) + \
    _generateRedshiftPublicRouteTable(config) + \
    _generateRedshiftPublicRoute(config) + \
    _generateRedshiftPublicRouteTableAssociations(config) + \
    _generateIntraRouteTable(config) + \
    _generateIntraRouteTableAssociations(config)
}
