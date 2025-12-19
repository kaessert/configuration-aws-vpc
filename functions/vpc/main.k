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
]
