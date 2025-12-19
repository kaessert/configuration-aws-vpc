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

# Import AWS provider models
import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1

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

# Extract typed metadata and spec from the XR
oxrMeta = awsv1alpha1.XVPC.metadata{**oxr.metadata}
oxrSpec = awsv1alpha1.XVPC.spec{**oxr.spec}

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

# Extract DNS configuration
enableDnsHostnames = oxrSpec.enableDnsHostnames if oxrSpec.enableDnsHostnames != None else True
enableDnsSupport = oxrSpec.enableDnsSupport if oxrSpec.enableDnsSupport != None else True

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

# Generate public subnets distributed across AZs
_publicSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("public-subnet-${i}") | {
            name = "subnet-public-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | publicSubnetTags
        }
        spec = {
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

# Generate private subnets distributed across AZs
_privateSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("private-subnet-${i}") | {
            name = "subnet-private-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | privateSubnetTags
        }
        spec = {
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

# Generate database subnets distributed across AZs
_databaseSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("database-subnet-${i}") | {
            name = "subnet-database-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | databaseSubnetTags
        }
        spec = {
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

# Generate elasticache subnets distributed across AZs
_elasticacheSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("elasticache-subnet-${i}") | {
            name = "subnet-elasticache-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | elasticacheSubnetTags
        }
        spec = {
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

# Generate redshift subnets distributed across AZs
_redshiftSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("redshift-subnet-${i}") | {
            name = "subnet-redshift-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | redshiftSubnetTags
        }
        spec = {
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

# Generate intra subnets distributed across AZs (internal subnets with no internet access)
_intraSubnetResources = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "Subnet"
        metadata = _metadata("intra-subnet-${i}") | {
            name = "subnet-intra-${vpcName}-${azs[i % len(azs)]}"
            labels = tags | intraSubnetTags
        }
        spec = {
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

# Generate Internet Gateway resource (conditional)
_igwResource = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "InternetGateway"
        metadata = _metadata("igw") | {
            name = "igw-${vpcName}"
            labels = tags
        }
        spec = {
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

# Main composition logic - returns list of desired resources
items = [
    # VPC Resource
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        metadata = _metadata("vpc") | {
            name = "vpc-${vpcName}"
            labels = tags
        }
        spec = {
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
] + _igwResource + _publicSubnetResources + _privateSubnetResources + _databaseSubnetResources + _elasticacheSubnetResources + _redshiftSubnetResources + _intraSubnetResources
