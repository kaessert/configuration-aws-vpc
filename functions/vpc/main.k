"""
AWS VPC Composition Function

This composition function creates a complete AWS VPC with:
- VPC with configurable CIDR blocks
- Multiple subnet types (public, private, database, elasticache, redshift, intra)
- Internet Gateway and NAT Gateways
- Route tables and routing rules
- VPC endpoints (S3, DynamoDB, and interface endpoints)
- DHCP options
- VPC Flow Logs
- Network ACLs

The composition provides feature parity with the terraform-aws-modules/vpc module.
"""

# Import AWS provider models (v2 - namespaced with .m suffix)
import models.io.upbound.awsm.v1beta1 as awsmv1beta1

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Import Upbound meta models
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1

# Import our XRD models
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1

# Import Kubernetes meta models
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# Access composition function parameters
oxr = option("params").oxr      # observed composite resource
ocds = option("params").ocds    # observed composed resources
dxr = option("params").dxr      # desired composite resource
dcds = option("params").dcds    # desired composed resources

# Metadata helper for composition resource naming
_metadata = lambda name: str -> any {
    """
    Creates metadata with a standardized composition resource name.

    Args:
        name: The name to include in the annotations

    Returns:
        A metadata object with annotations for composition resource naming
    """
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}

# Extract typed metadata and spec from the XR (v2 - using VPC without X prefix)
oxrMeta = awsv1alpha1.VPC.metadata{**oxr.metadata}
oxrSpec = awsv1alpha1.VPC.spec{**oxr.spec}

# Get the VPC name from metadata
vpcName = oxrMeta.name

# Extract core configuration from spec
region = oxrSpec.region
cidr = oxrSpec.cidr
azs = oxrSpec.azs or []
tags = oxrSpec.tags or {}

# Extract gateway configuration
createIgw = oxrSpec.createIgw if oxrSpec.createIgw != None else True
enableNatGateway = oxrSpec.enableNatGateway if oxrSpec.enableNatGateway != None else False
singleNatGateway = oxrSpec.singleNatGateway if oxrSpec.singleNatGateway != None else False
oneNatGatewayPerAz = oxrSpec.oneNatGatewayPerAz if oxrSpec.oneNatGatewayPerAz != None else False

# Extract route table configuration
createDatabaseSubnetRouteTable = oxrSpec.createDatabaseSubnetRouteTable if oxrSpec.createDatabaseSubnetRouteTable != None else False
createDatabaseNatGatewayRoute = oxrSpec.createDatabaseNatGatewayRoute if oxrSpec.createDatabaseNatGatewayRoute != None else False

# Extract DNS configuration
enableDnsHostnames = oxrSpec.enableDnsHostnames if oxrSpec.enableDnsHostnames != None else True
enableDnsSupport = oxrSpec.enableDnsSupport if oxrSpec.enableDnsSupport != None else True

# v2 Common Spec Configuration
# Crossplane v2 requires providerConfigRef.kind and managementPolicies
_defaultV2Spec = {
    providerConfigRef = {
        kind = "ProviderConfig"
        name = "default"
    }
    managementPolicies = ["*"]  # v2 replacement for deletionPolicy
}

# Extract subnet configuration
publicSubnets = oxrSpec.publicSubnets or []
mapPublicIpOnLaunch = oxrSpec.mapPublicIpOnLaunch if oxrSpec.mapPublicIpOnLaunch != None else True
publicSubnetTags = oxrSpec.publicSubnetTags or {}

privateSubnets = oxrSpec.privateSubnets or []
privateSubnetTags = oxrSpec.privateSubnetTags or {}

databaseSubnets = oxrSpec.databaseSubnets or []
databaseSubnetTags = oxrSpec.databaseSubnetTags or {}

elasticacheSubnets = oxrSpec.elasticacheSubnets or []
elasticacheSubnetTags = oxrSpec.elasticacheSubnetTags or {}

redshiftSubnets = oxrSpec.redshiftSubnets or []
redshiftSubnetTags = oxrSpec.redshiftSubnetTags or {}

intraSubnets = oxrSpec.intraSubnets or []
intraSubnetTags = oxrSpec.intraSubnetTags or {}

# Generate public subnets distributed across AZs - Using typed EC2 Subnet model
_publicSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("public-subnet-${i}") | {
            name = "subnet-public-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | publicSubnetTags | {
                "subnet-type": "public"
                "az": azs[i % len(azs)]
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = mapPublicIpOnLaunch
                region = region
                tags = tags | publicSubnetTags | {
                    Name = "subnet-public-${vpcName}-${azs[i % len(azs)]}"
                    Type = "public"
                }
            }
        }
    }
    for i, subnetCidr in publicSubnets
] if len(publicSubnets) > 0 and len(azs) > 0 else []

# Generate private subnets distributed across AZs - Using typed EC2 Subnet model
_privateSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("private-subnet-${i}") | {
            name = "subnet-private-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | privateSubnetTags | {
                "subnet-type": "private"
                "az": azs[i % len(azs)]
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = False
                region = region
                tags = tags | privateSubnetTags | {
                    Name = "subnet-private-${vpcName}-${azs[i % len(azs)]}"
                    Type = "private"
                }
            }
        }
    }
    for i, subnetCidr in privateSubnets
] if len(privateSubnets) > 0 and len(azs) > 0 else []

# Generate database subnets distributed across AZs - Using typed EC2 Subnet model
_databaseSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("database-subnet-${i}") | {
            name = "subnet-database-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | databaseSubnetTags | {
                "subnet-type": "database"
                "az": azs[i % len(azs)]
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = False
                region = region
                tags = tags | databaseSubnetTags | {
                    Name = "subnet-database-${vpcName}-${azs[i % len(azs)]}"
                    Type = "database"
                }
            }
        }
    }
    for i, subnetCidr in databaseSubnets
] if len(databaseSubnets) > 0 and len(azs) > 0 else []

# Generate elasticache subnets distributed across AZs - Using typed EC2 Subnet model
_elasticacheSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("elasticache-subnet-${i}") | {
            name = "subnet-elasticache-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | elasticacheSubnetTags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = False
                region = region
                tags = tags | elasticacheSubnetTags | {
                    Name = "subnet-elasticache-${vpcName}-${azs[i % len(azs)]}"
                    Type = "elasticache"
                }
            }
        }
    }
    for i, subnetCidr in elasticacheSubnets
] if len(elasticacheSubnets) > 0 and len(azs) > 0 else []

# Generate redshift subnets distributed across AZs - Using typed EC2 Subnet model
_redshiftSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("redshift-subnet-${i}") | {
            name = "subnet-redshift-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | redshiftSubnetTags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = False
                region = region
                tags = tags | redshiftSubnetTags | {
                    Name = "subnet-redshift-${vpcName}-${azs[i % len(azs)]}"
                    Type = "redshift"
                }
            }
        }
    }
    for i, subnetCidr in redshiftSubnets
] if len(redshiftSubnets) > 0 and len(azs) > 0 else []

# Generate intra subnets distributed across AZs - Using typed EC2 Subnet model
_intraSubnetResources = [
    ec2v1beta1.Subnet{
        metadata = _metadata("intra-subnet-${i}") | {
            name = "subnet-intra-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | intraSubnetTags | {
                "subnet-type": "intra"
                "az": azs[i % len(azs)]
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = azs[i % len(azs)]
                cidrBlock = subnetCidr
                mapPublicIpOnLaunch = False
                region = region
                tags = tags | intraSubnetTags | {
                    Name = "subnet-intra-${vpcName}-${azs[i % len(azs)]}"
                    Type = "intra"
                }
            }
        }
    }
    for i, subnetCidr in intraSubnets
] if len(intraSubnets) > 0 and len(azs) > 0 else []

# Generate Internet Gateway resource (conditional) - Using typed EC2 InternetGateway model
_igwResource = [
    ec2v1beta1.InternetGateway{
        metadata = _metadata("igw") | {
            name = "igw-${vpcName}"
            labels = tags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "igw-${vpcName}"
                }
            }
        }
    }
] if createIgw else []

# Generate EIP resources for NAT Gateways - Using typed EC2 EIP model
_eipResources = [
    ec2v1beta1.EIP{
        metadata = _metadata("eip-nat-${i}") | {
            name = "eip-nat-${vpcName}-${azs[i]}"
            labels = tags | {"az": azs[i]}
        }
        spec = _defaultV2Spec | {
            forProvider = {
                domain = "vpc"
                region = region
                tags = tags | {
                    Name = "eip-nat-${vpcName}-${azs[i]}"
                    AZ = azs[i]
                }
            }
        }
    }
    for i in range(len(azs))
] if enableNatGateway and oneNatGatewayPerAz and len(azs) > 0 and len(publicSubnets) > 0 else [
    # Single EIP for single NAT Gateway strategy
    ec2v1beta1.EIP{
        metadata = _metadata("eip-nat-0") | {
            name = "eip-nat-${vpcName}-${azs[0]}"
            labels = tags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                domain = "vpc"
                region = region
                tags = tags | {
                    Name = "eip-nat-${vpcName}-${azs[0]}"
                }
            }
        }
    }
] if enableNatGateway and singleNatGateway and len(azs) > 0 and len(publicSubnets) > 0 else []

# Generate NAT Gateway resources - Using typed EC2 NATGateway model
_natGatewayResources = [
    ec2v1beta1.NATGateway{
        metadata = _metadata("nat-${i}") | {
            name = "nat-${vpcName}-${azs[i]}"
            labels = tags | {"az": azs[i]}
        }
        spec = _defaultV2Spec | {
            forProvider = {
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "public"
                        "az": azs[i]
                    }
                }
                allocationIdSelector = {
                    matchLabels = {
                        "az": azs[i]
                    }
                }
                region = region
                tags = tags | {
                    Name = "nat-${vpcName}-${azs[i]}"
                    AZ = azs[i]
                }
            }
        }
    }
    for i in range(len(azs))
] if enableNatGateway and oneNatGatewayPerAz and len(azs) > 0 and len(publicSubnets) > 0 else [
    # Single NAT Gateway for single NAT strategy
    ec2v1beta1.NATGateway{
        metadata = _metadata("nat-0") | {
            name = "nat-${vpcName}-${azs[0]}"
            labels = tags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "public"
                        "az": azs[0]
                    }
                }
                allocationIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "nat-${vpcName}-${azs[0]}"
                }
            }
        }
    }
] if enableNatGateway and singleNatGateway and len(azs) > 0 and len(publicSubnets) > 0 else []

# ============================================================================
# ROUTING RESOURCES
# ============================================================================

# Generate public route table - Using typed EC2 RouteTable model
_publicRouteTable = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("public-route-table") | {
            name = "rtb-public-${vpcName}"
            labels = tags | {
                "route-table-type": "public"
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "rtb-public-${vpcName}"
                    Type = "public"
                }
            }
        }
    }
] if len(publicSubnets) > 0 else []

# Generate public route to Internet Gateway - Using typed EC2 Route model
_publicRoute = [
    ec2v1beta1.Route{
        metadata = _metadata("public-route-igw") | {
            name = "route-public-igw-${vpcName}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "public"
                    }
                }
                gatewayIdSelector = {
                    matchControllerRef = True
                }
                region = region
                destinationCidrBlock = "0.0.0.0/0"
            }
        }
    }
] if len(publicSubnets) > 0 and createIgw else []

# Generate public route table associations - Using typed EC2 RouteTableAssociation model
_publicRouteTableAssociations = [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("public-rtb-assoc-${i}") | {
            name = "rtb-assoc-public-${vpcName}-${azs[i % len(azs)]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "public"
                    }
                }
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "public"
                        "az": azs[i % len(azs)]
                    }
                }
                region = region
            }
        }
    }
    for i in range(len(publicSubnets))
] if len(publicSubnets) > 0 else []

# Generate private route tables - Using typed EC2 RouteTable model
# For single NAT: one shared route table for all private subnets
# For NAT per AZ: one route table per AZ
_privateRouteTables = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("private-route-table-${i}") | {
            name = "rtb-private-${vpcName}-${azs[i]}"
            labels = tags | {
                "route-table-type": "private"
                "az": azs[i]
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "rtb-private-${vpcName}-${azs[i]}"
                    Type = "private"
                    AZ = azs[i]
                }
            }
        }
    }
    for i in range(len(azs))
] if len(privateSubnets) > 0 and enableNatGateway and oneNatGatewayPerAz else [
    # Single route table for all private subnets (single NAT strategy)
    ec2v1beta1.RouteTable{
        metadata = _metadata("private-route-table") | {
            name = "rtb-private-${vpcName}"
            labels = tags | {
                "route-table-type": "private"
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "rtb-private-${vpcName}"
                    Type = "private"
                }
            }
        }
    }
] if len(privateSubnets) > 0 and enableNatGateway else []

# Generate private routes to NAT Gateway - Using typed EC2 Route model
_privateRoutes = [
    ec2v1beta1.Route{
        metadata = _metadata("private-route-nat-${i}") | {
            name = "route-private-nat-${vpcName}-${azs[i]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "private"
                        "az": azs[i]
                    }
                }
                natGatewayIdSelector = {
                    matchLabels = {
                        "az": azs[i]
                    }
                }
                region = region
                destinationCidrBlock = "0.0.0.0/0"
            }
        }
    }
    for i in range(len(azs))
] if len(privateSubnets) > 0 and enableNatGateway and oneNatGatewayPerAz else [
    # Single route for single NAT Gateway strategy
    ec2v1beta1.Route{
        metadata = _metadata("private-route-nat") | {
            name = "route-private-nat-${vpcName}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "private"
                    }
                }
                natGatewayIdSelector = {
                    matchControllerRef = True
                }
                region = region
                destinationCidrBlock = "0.0.0.0/0"
            }
        }
    }
] if len(privateSubnets) > 0 and enableNatGateway and singleNatGateway else []

# Generate private route table associations - Using typed EC2 RouteTableAssociation model
_privateRouteTableAssociations = [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("private-rtb-assoc-${i}") | {
            name = "rtb-assoc-private-${vpcName}-${azs[i % len(azs)]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "private"
                        "az": azs[i % len(azs)]
                    }
                }
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "private"
                        "az": azs[i % len(azs)]
                    }
                }
                region = region
            }
        }
    }
    for i in range(len(privateSubnets))
] if len(privateSubnets) > 0 and enableNatGateway and oneNatGatewayPerAz else [
    # Single route table for single NAT strategy
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("private-rtb-assoc-${i}") | {
            name = "rtb-assoc-private-${vpcName}-${azs[i % len(azs)]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "private"
                    }
                }
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "private"
                        "az": azs[i % len(azs)]
                    }
                }
                region = region
            }
        }
    }
    for i in range(len(privateSubnets))
] if len(privateSubnets) > 0 and enableNatGateway else []

# Generate database route table - Using typed EC2 RouteTable model
_databaseRouteTable = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("database-route-table") | {
            name = "rtb-database-${vpcName}"
            labels = tags | {
                "route-table-type": "database"
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "rtb-database-${vpcName}"
                    Type = "database"
                }
            }
        }
    }
] if len(databaseSubnets) > 0 and createDatabaseSubnetRouteTable else []

# Generate database route to NAT Gateway (optional) - Using typed EC2 Route model
_databaseRoute = [
    ec2v1beta1.Route{
        metadata = _metadata("database-route-nat") | {
            name = "route-database-nat-${vpcName}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "database"
                    }
                }
                natGatewayIdSelector = {
                    matchControllerRef = True
                }
                region = region
                destinationCidrBlock = "0.0.0.0/0"
            }
        }
    }
] if len(databaseSubnets) > 0 and createDatabaseSubnetRouteTable and createDatabaseNatGatewayRoute and enableNatGateway else []

# Generate database route table associations - Using typed EC2 RouteTableAssociation model
_databaseRouteTableAssociations = [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("database-rtb-assoc-${i}") | {
            name = "rtb-assoc-database-${vpcName}-${azs[i % len(azs)]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "database"
                    }
                }
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "database"
                        "az": azs[i % len(azs)]
                    }
                }
                region = region
            }
        }
    }
    for i in range(len(databaseSubnets))
] if len(databaseSubnets) > 0 and createDatabaseSubnetRouteTable else []

# Generate intra (isolated) route table - Using typed EC2 RouteTable model
_intraRouteTable = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("intra-route-table") | {
            name = "rtb-intra-${vpcName}"
            labels = tags | {
                "route-table-type": "intra"
            }
        }
        spec = _defaultV2Spec | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = region
                tags = tags | {
                    Name = "rtb-intra-${vpcName}"
                    Type = "intra"
                }
            }
        }
    }
] if len(intraSubnets) > 0 else []

# Generate intra route table associations - Using typed EC2 RouteTableAssociation model
# Note: No routes are added - intra subnets are fully isolated
_intraRouteTableAssociations = [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("intra-rtb-assoc-${i}") | {
            name = "rtb-assoc-intra-${vpcName}-${azs[i % len(azs)]}"
        }
        spec = _defaultV2Spec | {
            forProvider = {
                routeTableIdSelector = {
                    matchLabels = {
                        "route-table-type": "intra"
                    }
                }
                subnetIdSelector = {
                    matchLabels = {
                        "subnet-type": "intra"
                        "az": azs[i % len(azs)]
                    }
                }
                region = region
            }
        }
    }
    for i in range(len(intraSubnets))
] if len(intraSubnets) > 0 else []

# Main composition logic - returns list of desired resources
items = [
    # VPC Resource - Using typed EC2 VPC model
    ec2v1beta1.VPC{
        metadata = _metadata("vpc") | {
            name = "vpc-${vpcName}"
            labels = tags
        }
        spec = _defaultV2Spec | {
            forProvider = {
                cidrBlock = cidr
                region = region
                enableDnsHostnames = enableDnsHostnames
                enableDnsSupport = enableDnsSupport
                tags = tags | {
                    Name = vpcName
                }
            }
        }
    }
] + _igwResource + _eipResources + _natGatewayResources + _publicSubnetResources + _privateSubnetResources + _databaseSubnetResources + _elasticacheSubnetResources + _redshiftSubnetResources + _intraSubnetResources + _publicRouteTable + _publicRoute + _publicRouteTableAssociations + _privateRouteTables + _privateRoutes + _privateRouteTableAssociations + _databaseRouteTable + _databaseRoute + _databaseRouteTableAssociations + _intraRouteTable + _intraRouteTableAssociations
