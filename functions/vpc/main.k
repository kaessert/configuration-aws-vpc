"""
AWS VPC Composition Function

This composition function creates a complete AWS VPC with:
- VPC with configurable CIDR blocks
- Multiple subnet types (public, private, database, elasticache, redshift, intra)
- Internet Gateway and NAT Gateways
- Route tables and routing rules
- VPC endpoints (S3, DynamoDB)
- DHCP options
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

# Import modular composition functions
import vpc
import subnets
import gateways
import routing
import endpoints
import dhcp
import nacl
import flowlogs
import subnetgroups
import vpn

# ============================================================================
# ACCESS COMPOSITION FUNCTION PARAMETERS
# ============================================================================

# Access composition function parameters
oxr = option("params").oxr      # observed composite resource
ocds = option("params").ocds    # observed composed resources
dxr = option("params").dxr      # desired composite resource
dcds = option("params").dcds    # desired composed resources

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

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

# v2 Common Spec Configuration
# Crossplane v2 requires providerConfigRef.kind and managementPolicies
_defaultV2Spec = {
    providerConfigRef = {
        kind = "ProviderConfig"
        name = "default"
    }
    managementPolicies = ["*"]  # v2 replacement for deletionPolicy
}

# ============================================================================
# EXTRACT PARAMETERS FROM XR
# ============================================================================

# Extract typed metadata and spec from the XR (v2 - using VPC without X prefix)
oxrMeta = awsv1alpha1.VPC.metadata{**oxr.metadata}
oxrSpec = awsv1alpha1.VPC.spec{**oxr.spec}

# Get the VPC name from metadata
vpcName = oxrMeta.name

# Extract core configuration from spec
region = oxrSpec.region
cidr = oxrSpec.cidr
secondaryCidrBlocks = oxrSpec.secondaryCidrBlocks or []
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

# Extract DHCP Options configuration
enableDhcpOptions = oxrSpec.enableDhcpOptions if oxrSpec.enableDhcpOptions != None else False
dhcpOptionsDomainName = oxrSpec.dhcpOptionsDomainName if oxrSpec.dhcpOptionsDomainName else None
dhcpOptionsDomainNameServers = oxrSpec.dhcpOptionsDomainNameServers or []
dhcpOptionsNtpServers = oxrSpec.dhcpOptionsNtpServers or []
dhcpOptionsNetbiosNameServers = oxrSpec.dhcpOptionsNetbiosNameServers or []
dhcpOptionsNetbiosNodeType = oxrSpec.dhcpOptionsNetbiosNodeType if oxrSpec.dhcpOptionsNetbiosNodeType != None else None

# Extract VPC Endpoints configuration
enableS3Endpoint = oxrSpec.enableS3Endpoint if oxrSpec.enableS3Endpoint != None else False
s3EndpointType = oxrSpec.s3EndpointType if oxrSpec.s3EndpointType else "Gateway"
enableDynamodbEndpoint = oxrSpec.enableDynamodbEndpoint if oxrSpec.enableDynamodbEndpoint != None else False
vpcEndpointTags = oxrSpec.vpcEndpointTags or {}

# Extract Network ACL configuration
publicDedicatedNetworkAcl = oxrSpec.publicDedicatedNetworkAcl if oxrSpec.publicDedicatedNetworkAcl != None else False
publicInboundAclRules = oxrSpec.publicInboundAclRules or []
publicOutboundAclRules = oxrSpec.publicOutboundAclRules or []
publicAclTags = oxrSpec.publicAclTags or {}

privateDedicatedNetworkAcl = oxrSpec.privateDedicatedNetworkAcl if oxrSpec.privateDedicatedNetworkAcl != None else False
privateInboundAclRules = oxrSpec.privateInboundAclRules or []
privateOutboundAclRules = oxrSpec.privateOutboundAclRules or []
privateAclTags = oxrSpec.privateAclTags or {}

# Extract Flow Logs configuration
enableFlowLog = oxrSpec.enableFlowLog if oxrSpec.enableFlowLog != None else False
createFlowLogCloudwatchLogGroup = oxrSpec.createFlowLogCloudwatchLogGroup if oxrSpec.createFlowLogCloudwatchLogGroup != None else False
createFlowLogS3Bucket = oxrSpec.createFlowLogS3Bucket if oxrSpec.createFlowLogS3Bucket != None else False
flowLogTrafficType = oxrSpec.flowLogTrafficType if oxrSpec.flowLogTrafficType else "ALL"
flowLogMaxAggregationInterval = oxrSpec.flowLogMaxAggregationInterval if oxrSpec.flowLogMaxAggregationInterval != None else 600
flowLogFileFormat = oxrSpec.flowLogFileFormat if oxrSpec.flowLogFileFormat else "plain-text"
flowLogHiveCompatiblePartitions = oxrSpec.flowLogHiveCompatiblePartitions if oxrSpec.flowLogHiveCompatiblePartitions != None else False
flowLogPerHourPartition = oxrSpec.flowLogPerHourPartition if oxrSpec.flowLogPerHourPartition != None else False

# Extract VPN Gateway configuration
enableVpnGateway = oxrSpec.enableVpnGateway if oxrSpec.enableVpnGateway != None else False
vpnGatewayId = oxrSpec.vpnGatewayId if oxrSpec.vpnGatewayId else None
amazonSideAsn = oxrSpec.amazonSideAsn if oxrSpec.amazonSideAsn != None else 64512
vpnGatewayAz = oxrSpec.vpnGatewayAz if oxrSpec.vpnGatewayAz else None
propagatePublicRouteTablesVgw = oxrSpec.propagatePublicRouteTablesVgw if oxrSpec.propagatePublicRouteTablesVgw != None else True
propagatePrivateRouteTablesVgw = oxrSpec.propagatePrivateRouteTablesVgw if oxrSpec.propagatePrivateRouteTablesVgw != None else True
propagateIntraRouteTablesVgw = oxrSpec.propagateIntraRouteTablesVgw if oxrSpec.propagateIntraRouteTablesVgw != None else False
propagateDatabaseRouteTablesVgw = oxrSpec.propagateDatabaseRouteTablesVgw if oxrSpec.propagateDatabaseRouteTablesVgw != None else False
vpnGatewayTags = oxrSpec.vpnGatewayTags or {}

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

# ============================================================================
# BUILD CONFIGURATION OBJECT FOR MODULES
# ============================================================================

# Build configuration object to pass to module functions
config = {
    # Helper functions
    metadata = _metadata
    defaultV2Spec = _defaultV2Spec

    # Core configuration
    vpcName = vpcName
    region = region
    cidr = cidr
    secondaryCidrBlocks = secondaryCidrBlocks
    azs = azs
    tags = tags

    # DNS configuration
    enableDnsHostnames = enableDnsHostnames
    enableDnsSupport = enableDnsSupport

    # Gateway configuration
    createIgw = createIgw
    enableNatGateway = enableNatGateway
    singleNatGateway = singleNatGateway
    oneNatGatewayPerAz = oneNatGatewayPerAz

    # Subnet configuration
    publicSubnets = publicSubnets
    mapPublicIpOnLaunch = mapPublicIpOnLaunch
    publicSubnetTags = publicSubnetTags
    privateSubnets = privateSubnets
    privateSubnetTags = privateSubnetTags
    databaseSubnets = databaseSubnets
    databaseSubnetTags = databaseSubnetTags
    elasticacheSubnets = elasticacheSubnets
    elasticacheSubnetTags = elasticacheSubnetTags
    redshiftSubnets = redshiftSubnets
    redshiftSubnetTags = redshiftSubnetTags
    intraSubnets = intraSubnets
    intraSubnetTags = intraSubnetTags

    # Route table configuration
    createDatabaseSubnetRouteTable = createDatabaseSubnetRouteTable
    createDatabaseNatGatewayRoute = createDatabaseNatGatewayRoute

    # DHCP Options configuration
    enableDhcpOptions = enableDhcpOptions
    dhcpOptionsDomainName = dhcpOptionsDomainName
    dhcpOptionsDomainNameServers = dhcpOptionsDomainNameServers
    dhcpOptionsNtpServers = dhcpOptionsNtpServers
    dhcpOptionsNetbiosNameServers = dhcpOptionsNetbiosNameServers
    dhcpOptionsNetbiosNodeType = dhcpOptionsNetbiosNodeType

    # VPC Endpoints configuration
    enableS3Endpoint = enableS3Endpoint
    s3EndpointType = s3EndpointType
    enableDynamodbEndpoint = enableDynamodbEndpoint
    vpcEndpointTags = vpcEndpointTags

    # Network ACL configuration
    publicDedicatedNetworkAcl = publicDedicatedNetworkAcl
    publicInboundAclRules = publicInboundAclRules
    publicOutboundAclRules = publicOutboundAclRules
    publicAclTags = publicAclTags
    privateDedicatedNetworkAcl = privateDedicatedNetworkAcl
    privateInboundAclRules = privateInboundAclRules
    privateOutboundAclRules = privateOutboundAclRules
    privateAclTags = privateAclTags

    # Flow Logs configuration
    enableFlowLog = enableFlowLog
    createFlowLogCloudwatchLogGroup = createFlowLogCloudwatchLogGroup
    createFlowLogS3Bucket = createFlowLogS3Bucket
    flowLogTrafficType = flowLogTrafficType
    flowLogMaxAggregationInterval = flowLogMaxAggregationInterval
    flowLogFileFormat = flowLogFileFormat
    flowLogHiveCompatiblePartitions = flowLogHiveCompatiblePartitions
    flowLogPerHourPartition = flowLogPerHourPartition

    # VPN Gateway configuration
    enableVpnGateway = enableVpnGateway
    vpnGatewayId = vpnGatewayId
    amazonSideAsn = amazonSideAsn
    vpnGatewayAz = vpnGatewayAz
    propagatePublicRouteTablesVgw = propagatePublicRouteTablesVgw
    propagatePrivateRouteTablesVgw = propagatePrivateRouteTablesVgw
    propagateIntraRouteTablesVgw = propagateIntraRouteTablesVgw
    propagateDatabaseRouteTablesVgw = propagateDatabaseRouteTablesVgw
    vpnGatewayTags = vpnGatewayTags
}

# ============================================================================
# GENERATE ALL RESOURCES USING MODULES
# ============================================================================

# Main composition logic - returns list of desired resources
items = \
    vpc.generateVPCResources(config) + \
    subnets.generateAllSubnets(config) + \
    gateways.generateAllGateways(config) + \
    routing.generateAllRouting(config) + \
    endpoints.generateAllEndpoints(config) + \
    dhcp.generateAllDHCP(config) + \
    nacl.generateAllNACLs(config) + \
    flowlogs.generateFlowLogs(config.vpcName, config.region, config.enableFlowLog, config.createFlowLogCloudwatchLogGroup, config.createFlowLogS3Bucket, config.flowLogTrafficType, config.flowLogMaxAggregationInterval, config.flowLogFileFormat, config.flowLogHiveCompatiblePartitions, config.flowLogPerHourPartition, config.tags) + \
    subnetgroups.generateSubnetGroups(oxr, dxr, ocds, dcds, region, tags) + \
    vpn.generateAllVPN(config)
