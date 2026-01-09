"""
Default Resource Management Module

This module handles generation of AWS default VPC resources for security hardening:
- DefaultSecurityGroup: Manages default security group with lockdown (no ingress/egress)
- DefaultNetworkACL: Manages default Network ACL with custom rules
- DefaultRouteTable: Manages default route table with custom routes

These resources allow explicit control over AWS-created default resources,
implementing security best practices by removing or customizing default configurations.

Reference: Task 4.8 - Default Resource Management
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# ========================================
# PRIVATE HELPER FUNCTIONS
# ========================================

_protocolToNumber = lambda protocol: str -> str {
    """
    Converts protocol names to protocol numbers as required by AWS.

    Args:
        protocol: Protocol name (tcp, udp, icmp, all) or number

    Returns:
        Protocol number as string (tcp=6, udp=17, icmp=1, all=-1)
    """
    "6" if protocol == "tcp" else "17" if protocol == "udp" else "1" if protocol == "icmp" else "-1" if protocol == "all" or protocol == "-1" else protocol
}

_transformNACLRule = lambda rule: any -> any {
    """
    Transforms NACL rule from XR format to AWS provider format.

    Args:
        rule: Rule object from XR spec

    Returns:
        Transformed rule object for AWS provider
    """
    {
        ruleNo = rule.ruleNumber
        protocol = _protocolToNumber(rule.protocol)
        action = rule.ruleAction
        cidrBlock = rule.cidrBlock
    } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
      | ({toPort = rule.toPort} if rule?.toPort else {}) \
      | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
      | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
}

_createRouteSelector = lambda gatewayType: str, natGatewayIndex: int -> any {
    """
    Creates appropriate gateway selector based on gateway type.

    Args:
        gatewayType: Type of gateway (igw, nat, vpn, eigw)
        natGatewayIndex: Index of NAT Gateway (for nat type)

    Returns:
        Selector object for the gateway
    """
    # IGW - Internet Gateway
    {
        gatewayIdSelector = {
            matchControllerRef = True
            matchLabels = {
                "resource-type": "igw"
            }
        }
    } if gatewayType == "igw" else {
        # NAT Gateway
        natGatewayIdSelector = {
            matchControllerRef = True
        } | ({matchLabels = {"nat-index": str(natGatewayIndex)}} if natGatewayIndex != None else {})
    } if gatewayType == "nat" else {
        # VPN Gateway
        vpnGatewayIdSelector = {
            matchControllerRef = True
        }
    } if gatewayType == "vpn" else {
        # Egress-Only Internet Gateway (IPv6)
        egressOnlyGatewayIdSelector = {
            matchControllerRef = True
        }
    } if gatewayType == "eigw" else {}
}

# ========================================
# DEFAULT SECURITY GROUP
# ========================================

_generateDefaultSecurityGroup = lambda config: {str: any} -> [any] {
    """
    Generates the Default Security Group resource.

    Security hardening: When enabled, removes ALL ingress and egress rules
    from the default security group, forcing users to create explicit
    security groups with proper rules.

    Args:
        config: Configuration object containing:
            - manageDefaultSecurityGroup: Enable default SG management
            - vpcName: Name of the VPC
            - tags: Common tags
            - defaultSecurityGroupTags: Additional tags for default SG
            - defaultV2Spec: Crossplane v2 default spec
            - metadata: Metadata helper function
            - sanitizeLabels: Label sanitization helper

    Returns:
        List containing the DefaultSecurityGroup resource, or empty list if disabled
    """
    [
        ec2v1beta1.DefaultSecurityGroup{
            metadata = config.metadata("default-sg") | {
                name = "default-sg-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.defaultSecurityGroupTags)
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    # Reference VPC by controller ref
                    vpcIdSelector = {
                        matchControllerRef = True
                    }

                    # Region is required
                    region = config.region

                    # Security hardening: Empty rules (deny all traffic)
                    ingress = []
                    egress = []

                    # Merge tags
                    tags = config.tags | config.defaultSecurityGroupTags | {
                        Name = "${config.vpcName}-default-sg"
                    }
                }
            }
        }
    ] if config.manageDefaultSecurityGroup else []
}

# ========================================
# DEFAULT NETWORK ACL
# ========================================

_generateDefaultNetworkACL = lambda config: {str: any} -> [any] {
    """
    Generates the Default Network ACL resource with custom rules.

    Allows explicit control over the default Network ACL by specifying
    custom ingress and egress rules.

    Args:
        config: Configuration object containing:
            - manageDefaultNetworkAcl: Enable default NACL management
            - vpcName: Name of the VPC
            - defaultNetworkAclIngressRules: List of ingress rules
            - defaultNetworkAclEgressRules: List of egress rules
            - tags: Common tags
            - defaultNetworkAclTags: Additional tags for default NACL
            - defaultV2Spec: Crossplane v2 default spec
            - metadata: Metadata helper function
            - sanitizeLabels: Label sanitization helper

    Returns:
        List containing the DefaultNetworkACL resource, or empty list if disabled
    """
    [
        ec2v1beta1.DefaultNetworkACL{
            metadata = config.metadata("default-nacl") | {
                name = "default-nacl-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.defaultNetworkAclTags)
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    # Reference VPC's default NACL by controller ref
                    defaultNetworkAclIdSelector = {
                        matchControllerRef = True
                    }

                    # Region is required
                    region = config.region

                    # Custom ingress rules (transform protocol names to numbers)
                    ingress = [_transformNACLRule(rule) for rule in config.defaultNetworkAclIngressRules] if len(config.defaultNetworkAclIngressRules) > 0 else []

                    # Custom egress rules (transform protocol names to numbers)
                    egress = [_transformNACLRule(rule) for rule in config.defaultNetworkAclEgressRules] if len(config.defaultNetworkAclEgressRules) > 0 else []

                    # Merge tags
                    tags = config.tags | config.defaultNetworkAclTags | {
                        Name = "${config.vpcName}-default-nacl"
                    }
                }
            }
        }
    ] if config.manageDefaultNetworkAcl else []
}

# ========================================
# DEFAULT ROUTE TABLE
# ========================================

_generateDefaultRouteTable = lambda config: {str: any} -> [any] {
    """
    Generates the Default Route Table resource with custom routes.

    Allows explicit control over the default route table by specifying
    custom routes to various gateway types.

    Args:
        config: Configuration object containing:
            - manageDefaultRouteTable: Enable default RT management
            - vpcName: Name of the VPC
            - defaultRouteTableRoutes: List of route configurations
            - tags: Common tags
            - defaultRouteTableTags: Additional tags for default RT
            - defaultV2Spec: Crossplane v2 default spec
            - metadata: Metadata helper function
            - sanitizeLabels: Label sanitization helper

    Returns:
        List containing the DefaultRouteTable resource, or empty list if disabled
    """
    [
        ec2v1beta1.DefaultRouteTable{
            metadata = config.metadata("default-rt") | {
                name = "default-rt-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.defaultRouteTableTags)
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    # Reference VPC's default route table by controller ref
                    defaultRouteTableIdSelector = {
                        matchControllerRef = True
                    }

                    # Region is required
                    region = config.region

                    # Custom routes with gateway selectors
                    route = [
                        {
                            cidrBlock = routeConfig.destinationCidrBlock
                        } | _createRouteSelector(routeConfig.gatewayType, routeConfig?.natGatewayIndex)
                        for routeConfig in config.defaultRouteTableRoutes
                    ] if len(config.defaultRouteTableRoutes) > 0 else []

                    # Merge tags
                    tags = config.tags | config.defaultRouteTableTags | {
                        Name = "${config.vpcName}-default-rt"
                    }
                }
            }
        }
    ] if config.manageDefaultRouteTable else []
}

# ========================================
# PUBLIC API
# ========================================

generateDefaultResources = lambda config: {str: any} -> [any] {
    """
    Generates all default resource management resources.

    Orchestrates generation of DefaultSecurityGroup, DefaultNetworkACL,
    and DefaultRouteTable based on configuration flags.

    Args:
        config: Configuration object (see individual generator functions)

    Returns:
        Combined list of all default resource management resources
    """
    _generateDefaultSecurityGroup(config) + \
    _generateDefaultNetworkACL(config) + \
    _generateDefaultRouteTable(config)
}
