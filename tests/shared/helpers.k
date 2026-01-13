"""
Shared Test Helpers

Reusable builder functions for common resource assertions across all tests.

This eliminates boilerplate code and ensures consistency across all tests.
Every test can import these helpers to reduce code duplication by 80-90%.

Usage:
    import helpers

    # Build a composition test spec
    spec: {
        **helpers.buildCompositionTestSpec("vpc")
        xr: { ... }
        assertResources: [
            helpers.buildVPC("vpc-test", "10.0.0.0/16", {...}),
            helpers.buildSubnet("subnet-test", "10.0.1.0/24", "us-west-2a", {...})
        ]
    }
"""

# ============================================================================
# Standard Crossplane v2 Configuration
# ============================================================================

# Default provider config reference (used in all managed resources)
_defaultProviderConfig = {
    kind: "ProviderConfig"
    name: "default"
}

# Default management policies for Crossplane v2 (full management)
_defaultManagementPolicies = ["*"]

# ============================================================================
# Core Builder Functions
# ============================================================================

buildProviderConfigRef = lambda name: str = "default" {
    """
    Build a standard providerConfigRef for Crossplane v2.

    Args:
        name: ProviderConfig name (default: "default")

    Returns:
        Standard providerConfigRef structure
    """
    {
        kind: "ProviderConfig"
        name: name
    }
}

buildManagedResource = lambda name: str, kind: str, apiGroup: str, forProvider: {str: any}, region: str = "us-west-2", labels: {str: str} = {}, annotations: {str: str} = {} {
    """
    Build a generic managed resource with standard Crossplane v2 patterns.

    This is the universal builder for any AWS managed resource. It automatically
    includes providerConfigRef, managementPolicies, and region.

    Args:
        name: Resource metadata name
        kind: Resource kind (e.g., "VPC", "Subnet", "NATGateway")
        apiGroup: API group (e.g., "ec2", "iam", "eks")
        forProvider: Provider-specific configuration (merged with region)
        region: AWS region (default: "us-west-2")
        labels: Resource labels (optional)
        annotations: Resource annotations (optional)

    Returns:
        Complete managed resource structure

    Example:
        helpers.buildManagedResource(
            "vpc-test",
            "VPC",
            "ec2",
            { cidrBlock: "10.0.0.0/16", enableDnsHostnames: True },
            region="us-west-2",
            labels={ "vpc-name": "test" }
        )
    """
    {
        apiVersion: "${apiGroup}.m.upbound.io/v1beta1"
        kind: kind
        metadata: {
            name: name
            labels: labels if labels else {}
            annotations: annotations if annotations else {}
        }
        spec: {
            providerConfigRef: _defaultProviderConfig
            managementPolicies: _defaultManagementPolicies
            forProvider: {
                region: region
                **forProvider
            }
        }
    }
}

buildCompositionTestSpec = lambda resource: str = "vpc", timeoutSeconds: int = 60, validate: bool = True {
    """
    Build base specification for CompositionTest (use with spread operator).

    This creates the standard test spec structure that every composition test needs.
    Use the spread operator (**) to merge this into your test spec.

    Args:
        resource: Resource name (default: "vpc")
        timeoutSeconds: Test timeout in seconds (default: 60, minimum: 60)
        validate: Whether to validate resources (default: True)

    Returns:
        Base specification object for spreading into test spec

    Example:
        spec: {
            **helpers.buildCompositionTestSpec("vpc")
            xr: { ... }
            assertResources: [ ... ]
        }
    """
    {
        compositionPath: "../../apis/${resource}/composition.yaml"
        xrdPath: "../../apis/${resource}/definition.yaml"
        timeoutSeconds: timeoutSeconds
        validate: validate
    }
}

# ============================================================================
# VPC Resource Builders
# ============================================================================

buildVPC = lambda name: str, cidr: str, tags: {str: str}, region: str = "us-west-2", enableDnsHostnames: bool = True, enableDnsSupport: bool = True, instanceTenancy: str = "default" {
    """
    Build a VPC managed resource with standard configuration.

    Args:
        name: VPC name
        cidr: CIDR block (e.g., "10.0.0.0/16")
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        enableDnsHostnames: Enable DNS hostnames (default: True)
        enableDnsSupport: Enable DNS support (default: True)
        instanceTenancy: Instance tenancy (default: "default", or "dedicated")

    Returns:
        VPC managed resource
    """
    buildManagedResource(
        name,
        "VPC",
        "ec2",
        {
            cidrBlock: cidr
            enableDnsHostnames: enableDnsHostnames
            enableDnsSupport: enableDnsSupport
            instanceTenancy: instanceTenancy
            tags: tags
        },
        region=region
    )
}

buildSubnet = lambda name: str, cidr: str, az: str, tags: {str: str}, region: str = "us-west-2", mapPublicIpOnLaunch: bool = False, useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a Subnet managed resource with standard configuration.

    Args:
        name: Subnet name
        cidr: CIDR block (e.g., "10.0.1.0/24")
        az: Availability zone (e.g., "us-west-2a")
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        mapPublicIpOnLaunch: Auto-assign public IP (default: False, True for public subnets)
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Subnet managed resource
    """
    forProviderBase = {
        availabilityZone: az
        cidrBlock: cidr
        mapPublicIpOnLaunch: mapPublicIpOnLaunch
        tags: tags
    }

    forProviderWithVpc = {
        **forProviderBase
        vpcIdSelector: { matchControllerRef: True }
    } if useControllerRef else {
        **forProviderBase
        vpcId: vpcId
    }

    buildManagedResource(name, "Subnet", "ec2", forProviderWithVpc, region=region)
}

buildInternetGateway = lambda name: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build an Internet Gateway managed resource.

    Args:
        name: IGW name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Internet Gateway managed resource
    """
    forProvider = {
        vpcIdSelector: { matchControllerRef: True }
        tags: tags
    } if useControllerRef else {
        vpcId: vpcId
        tags: tags
    }

    buildManagedResource(name, "InternetGateway", "ec2", forProvider, region=region)
}

buildNATGateway = lambda name: str, subnetLabels: {str: str}, tags: {str: str}, region: str = "us-west-2", useAllocationIdSelector: bool = True, allocationId: str = "" {
    """
    Build a NAT Gateway managed resource.

    Args:
        name: NAT Gateway name
        subnetLabels: Labels to match subnet (e.g., {"subnet-type": "public", "az": "us-west-2a"})
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useAllocationIdSelector: Use EIP controller ref (default: True)
        allocationId: Explicit allocation ID (optional, ignored if useAllocationIdSelector is True)

    Returns:
        NAT Gateway managed resource
    """
    forProviderBase = {
        subnetIdSelector: { matchLabels: subnetLabels }
        tags: tags
    }

    forProviderWithAllocation = {
        **forProviderBase
        allocationIdSelector: { matchControllerRef: True }
    } if useAllocationIdSelector else {
        **forProviderBase
        allocationId: allocationId
    }

    buildManagedResource(name, "NATGateway", "ec2", forProviderWithAllocation, region=region)
}

buildEIP = lambda name: str, tags: {str: str}, region: str = "us-west-2", domain: str = "vpc" {
    """
    Build an Elastic IP managed resource.

    Args:
        name: EIP name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        domain: EIP domain (default: "vpc")

    Returns:
        EIP managed resource
    """
    buildManagedResource(
        name,
        "EIP",
        "ec2",
        {
            domain: domain
            tags: tags
        },
        region=region
    )
}

buildRouteTable = lambda name: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a Route Table managed resource.

    Args:
        name: Route table name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Route Table managed resource
    """
    forProvider = {
        vpcIdSelector: { matchControllerRef: True }
        tags: tags
    } if useControllerRef else {
        vpcId: vpcId
        tags: tags
    }

    buildManagedResource(name, "RouteTable", "ec2", forProvider, region=region)
}

buildRoute = lambda name: str, destinationCidr: str, gatewayLabels: {str: str} = {}, natGatewayLabels: {str: str} = {}, routeTableLabels: {str: str} = {}, region: str = "us-west-2" {
    """
    Build a Route managed resource.

    Args:
        name: Route name
        destinationCidr: Destination CIDR (e.g., "0.0.0.0/0")
        gatewayLabels: Labels to match gateway (for IGW routes)
        natGatewayLabels: Labels to match NAT gateway (for NAT routes)
        routeTableLabels: Labels to match route table
        region: AWS region (default: "us-west-2")

    Returns:
        Route managed resource

    Note:
        Provide either gatewayLabels (for IGW) OR natGatewayLabels (for NAT), not both.
    """
    forProviderBase = {
        destinationCidrBlock: destinationCidr
        routeTableIdSelector: { matchLabels: routeTableLabels }
    }

    forProviderWithTarget = {
        **forProviderBase
        gatewayIdSelector: { matchLabels: gatewayLabels }
    } if gatewayLabels else {
        **forProviderBase
        natGatewayIdSelector: { matchLabels: natGatewayLabels }
    } if natGatewayLabels else forProviderBase

    buildManagedResource(name, "Route", "ec2", forProviderWithTarget, region=region)
}

buildRouteTableAssociation = lambda name: str, subnetLabels: {str: str}, routeTableLabels: {str: str}, region: str = "us-west-2" {
    """
    Build a Route Table Association managed resource.

    Args:
        name: Association name
        subnetLabels: Labels to match subnet
        routeTableLabels: Labels to match route table
        region: AWS region (default: "us-west-2")

    Returns:
        Route Table Association managed resource
    """
    buildManagedResource(
        name,
        "RouteTableAssociation",
        "ec2",
        {
            subnetIdSelector: { matchLabels: subnetLabels }
            routeTableIdSelector: { matchLabels: routeTableLabels }
        },
        region=region
    )
}

# ============================================================================
# VPC Endpoints
# ============================================================================

buildVPCEndpoint = lambda name: str, serviceName: str, endpointType: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "", routeTableLabels: [any] = [], subnetLabels: [any] = [], securityGroupIds: [str] = [], privateDnsEnabled: bool = False {
    """
    Build a VPC Endpoint managed resource.

    Args:
        name: Endpoint name
        serviceName: AWS service name (e.g., "com.amazonaws.us-west-2.s3")
        endpointType: Endpoint type ("Gateway" or "Interface")
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)
        routeTableLabels: Route table label selectors (for Gateway endpoints)
        subnetLabels: Subnet label selectors (for Interface endpoints)
        securityGroupIds: Security group IDs (for Interface endpoints)
        privateDnsEnabled: Enable private DNS (for Interface endpoints, default: False)

    Returns:
        VPC Endpoint managed resource
    """
    forProviderBase = {
        serviceName: serviceName
        vpcEndpointType: endpointType
        tags: tags
    }

    # Add VPC reference
    forProviderWithVpc = {
        **forProviderBase
        vpcIdSelector: { matchControllerRef: True }
    } if useControllerRef else {
        **forProviderBase
        vpcId: vpcId
    }

    # Add endpoint-type-specific fields
    forProviderComplete = {
        **forProviderWithVpc
        routeTableIdSelector: routeTableLabels if routeTableLabels else []
    } if endpointType == "Gateway" else {
        **forProviderWithVpc
        subnetIdSelector: subnetLabels if subnetLabels else []
        securityGroupIds: securityGroupIds if securityGroupIds else []
        privateDnsEnabled: privateDnsEnabled
    } if endpointType == "Interface" else forProviderWithVpc

    buildManagedResource(name, "VPCEndpoint", "ec2", forProviderComplete, region=region)
}

# ============================================================================
# Security and Network ACLs
# ============================================================================

buildSecurityGroup = lambda name: str, description: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a Security Group managed resource.

    Args:
        name: Security group name
        description: Security group description
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Security Group managed resource
    """
    forProvider = {
        description: description
        vpcIdSelector: { matchControllerRef: True }
        tags: tags
    } if useControllerRef else {
        description: description
        vpcId: vpcId
        tags: tags
    }

    buildManagedResource(name, "SecurityGroup", "ec2", forProvider, region=region)
}

buildNetworkACL = lambda name: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a Network ACL managed resource.

    Args:
        name: NACL name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Network ACL managed resource
    """
    forProvider = {
        vpcIdSelector: { matchControllerRef: True }
        tags: tags
    } if useControllerRef else {
        vpcId: vpcId
        tags: tags
    }

    buildManagedResource(name, "NetworkACL", "ec2", forProvider, region=region)
}

# ============================================================================
# DHCP Options
# ============================================================================

buildVPCDHCPOptions = lambda name: str, tags: {str: str}, region: str = "us-west-2", domainName: str = "", domainNameServers: [str] = [], ntpServers: [str] = [], netbiosNameServers: [str] = [], netbiosNodeType: str = "" {
    """
    Build a VPC DHCP Options managed resource.

    Args:
        name: DHCP options name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        domainName: Domain name
        domainNameServers: DNS server addresses
        ntpServers: NTP server addresses
        netbiosNameServers: NetBIOS name server addresses
        netbiosNodeType: NetBIOS node type

    Returns:
        VPC DHCP Options managed resource
    """
    forProvider: {str: any} = { tags: tags }

    if domainName:
        forProvider["domainName"] = domainName
    if domainNameServers:
        forProvider["domainNameServers"] = domainNameServers
    if ntpServers:
        forProvider["ntpServers"] = ntpServers
    if netbiosNameServers:
        forProvider["netbiosNameServers"] = netbiosNameServers
    if netbiosNodeType:
        forProvider["netbiosNodeType"] = netbiosNodeType

    buildManagedResource(name, "VPCDHCPOptions", "ec2", forProvider, region=region)
}

buildVPCDHCPOptionsAssociation = lambda name: str, dhcpOptionsLabels: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a VPC DHCP Options Association managed resource.

    Args:
        name: Association name
        dhcpOptionsLabels: Labels to match DHCP options
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        VPC DHCP Options Association managed resource
    """
    forProvider = {
        dhcpOptionsIdSelector: { matchLabels: dhcpOptionsLabels }
        vpcIdSelector: { matchControllerRef: True }
    } if useControllerRef else {
        dhcpOptionsIdSelector: { matchLabels: dhcpOptionsLabels }
        vpcId: vpcId
    }

    buildManagedResource(name, "VPCDHCPOptionsAssociation", "ec2", forProvider, region=region)
}

# ============================================================================
# VPN Resources
# ============================================================================

buildCustomerGateway = lambda name: str, bgpAsn: str, ipAddress: str, tags: {str: str}, region: str = "us-west-2", type: str = "ipsec.1" {
    """
    Build a Customer Gateway managed resource.

    Args:
        name: Customer gateway name
        bgpAsn: BGP ASN
        ipAddress: IP address
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        type: Gateway type (default: "ipsec.1")

    Returns:
        Customer Gateway managed resource
    """
    buildManagedResource(
        name,
        "CustomerGateway",
        "ec2",
        {
            bgpAsn: bgpAsn
            ipAddress: ipAddress
            type: type
            tags: tags
        },
        region=region
    )
}

buildVPNGateway = lambda name: str, tags: {str: str}, region: str = "us-west-2", amazonSideAsn: str = "", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build a VPN Gateway managed resource.

    Args:
        name: VPN gateway name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        amazonSideAsn: Amazon side ASN (optional)
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        VPN Gateway managed resource
    """
    forProviderBase: {str: any} = { tags: tags }

    if amazonSideAsn:
        forProviderBase["amazonSideAsn"] = amazonSideAsn

    forProvider = {
        **forProviderBase
        vpcIdSelector: { matchControllerRef: True }
    } if useControllerRef else {
        **forProviderBase
        vpcId: vpcId
    }

    buildManagedResource(name, "VPNGateway", "ec2", forProvider, region=region)
}

# ============================================================================
# Flow Logs
# ============================================================================

buildFlowLog = lambda name: str, trafficType: str, logDestination: str, logDestinationType: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "", iamRoleArn: str = "" {
    """
    Build a VPC Flow Log managed resource.

    Args:
        name: Flow log name
        trafficType: Traffic type ("ALL", "ACCEPT", or "REJECT")
        logDestination: Log destination ARN (CloudWatch Log Group or S3 bucket)
        logDestinationType: Destination type ("cloud-watch-logs" or "s3")
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)
        iamRoleArn: IAM role ARN (required for CloudWatch Logs)

    Returns:
        Flow Log managed resource
    """
    forProviderBase = {
        trafficType: trafficType
        logDestination: logDestination
        logDestinationType: logDestinationType
        tags: tags
    }

    if iamRoleArn:
        forProviderBase["iamRoleArn"] = iamRoleArn

    forProvider = {
        **forProviderBase
        vpcIdSelector: { matchControllerRef: True }
    } if useControllerRef else {
        **forProviderBase
        vpcId: vpcId
    }

    buildManagedResource(name, "FlowLog", "ec2", forProvider, region=region)
}

# ============================================================================
# IPv6 Resources
# ============================================================================

buildEgressOnlyInternetGateway = lambda name: str, tags: {str: str}, region: str = "us-west-2", useControllerRef: bool = True, vpcId: str = "" {
    """
    Build an Egress-Only Internet Gateway managed resource (for IPv6).

    Args:
        name: Gateway name
        tags: Resource tags
        region: AWS region (default: "us-west-2")
        useControllerRef: Use VPC controller ref (default: True)
        vpcId: Explicit VPC ID (optional, ignored if useControllerRef is True)

    Returns:
        Egress-Only Internet Gateway managed resource
    """
    forProvider = {
        vpcIdSelector: { matchControllerRef: True }
        tags: tags
    } if useControllerRef else {
        vpcId: vpcId
        tags: tags
    }

    buildManagedResource(name, "EgressOnlyInternetGateway", "ec2", forProvider, region=region)
}
