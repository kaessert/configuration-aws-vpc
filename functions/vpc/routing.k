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

# Generate public route table
_generatePublicRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the public route table.

    Args:
        config: Configuration object

    Returns:
        List containing the public route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("public-route-table") | {
                name = "rtb-public-${config.vpcName}"
                labels = config.tags | {
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

# Generate public route to Internet Gateway
_generatePublicRoute = lambda config: {str: any} -> [any] {
    """
    Generates the public route to the Internet Gateway.

    Args:
        config: Configuration object

    Returns:
        List containing the public route resource
    """
    [
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

# Generate public route table associations
_generatePublicRouteTableAssociations = lambda config: {str: any} -> [any] {
    """
    Generates route table associations for public subnets.

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
                labels = config.tags | {
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
                labels = config.tags | {
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
                    destinationCidrBlock = "0.0.0.0/0"
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
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
    ] if len(config.privateSubnets) > 0 and config.enableNatGateway and config.singleNatGateway else []
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
                labels = config.tags | {
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
                    destinationCidrBlock = "0.0.0.0/0"
                }
            }
        }
    ] if len(config.databaseSubnets) > 0 and config.createDatabaseSubnetRouteTable and config.createDatabaseNatGatewayRoute and config.enableNatGateway else []
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

# Generate intra route table
_generateIntraRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the intra (isolated) route table.
    Note: No routes are added - intra subnets are fully isolated.

    Args:
        config: Configuration object

    Returns:
        List containing the intra route table resource
    """
    [
        ec2v1beta1.RouteTable{
            metadata = config.metadata("intra-route-table") | {
                name = "rtb-intra-${config.vpcName}"
                labels = config.tags | {
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
    _generatePublicRouteTableAssociations(config) + \
    _generatePrivateRouteTables(config) + \
    _generatePrivateRoutes(config) + \
    _generatePrivateRouteTableAssociations(config) + \
    _generateDatabaseRouteTable(config) + \
    _generateDatabaseRoute(config) + \
    _generateDatabaseRouteTableAssociations(config) + \
    _generateIntraRouteTable(config) + \
    _generateIntraRouteTableAssociations(config)
}
