"""
Network ACL Module

This module handles generation of Network ACL resources:
- Network ACLs for public and private subnets
- Network ACL rules (inbound and outbound)
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Protocol mapping helper
_protocolToNumber = lambda protocol: str -> str {
    """
    Converts protocol names to protocol numbers as required by AWS.

    Args:
        protocol: Protocol name (tcp, udp, icmp) or number (-1 for all)

    Returns:
        Protocol number as string
    """
    "6" if protocol == "tcp" else "17" if protocol == "udp" else "1" if protocol == "icmp" else "-1" if protocol == "all" or protocol == "-1" else protocol
}

# ============================================================================
# PUBLIC NETWORK ACL
# ============================================================================

# Generate Network ACL for public subnets
_generatePublicNetworkAcl = lambda config: {str: any} -> [any] {
    """
    Generates the Network ACL for public subnets.

    Args:
        config: Configuration object

    Returns:
        List containing the public Network ACL resource
    """
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("public-nacl") | {
                name = "nacl-public-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.publicAclTags) | {
                    "subnet-type": "public"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    subnetIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "public"
                        }
                    }
                    tags = config.tags | config.publicAclTags | {
                        Name = "nacl-public-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.publicDedicatedNetworkAcl else []
}

# Generate public subnet inbound ACL rules
_generatePublicInboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates inbound Network ACL rules for public subnets.

    Args:
        config: Configuration object

    Returns:
        List of inbound ACL rule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("public-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-public-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "public"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) | ({toPort = rule.toPort} if rule?.toPort else {}) | ({icmpType = rule.icmpType} if rule?.icmpType else {}) | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.publicInboundAclRules
    ] if config.publicDedicatedNetworkAcl else []
}

# Generate public subnet outbound ACL rules
_generatePublicOutboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates outbound Network ACL rules for public subnets.

    Args:
        config: Configuration object

    Returns:
        List of outbound ACL rule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("public-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-public-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "public"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) | ({toPort = rule.toPort} if rule?.toPort else {}) | ({icmpType = rule.icmpType} if rule?.icmpType else {}) | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.publicOutboundAclRules
    ] if config.publicDedicatedNetworkAcl else []
}

# ============================================================================
# PRIVATE NETWORK ACL
# ============================================================================

# Generate Network ACL for private subnets
_generatePrivateNetworkAcl = lambda config: {str: any} -> [any] {
    """
    Generates the Network ACL for private subnets.

    Args:
        config: Configuration object

    Returns:
        List containing the private Network ACL resource
    """
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("private-nacl") | {
                name = "nacl-private-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.privateAclTags) | {
                    "subnet-type": "private"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    subnetIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "private"
                        }
                    }
                    tags = config.tags | config.privateAclTags | {
                        Name = "nacl-private-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.privateDedicatedNetworkAcl else []
}

# Generate private subnet inbound ACL rules
_generatePrivateInboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates inbound Network ACL rules for private subnets.

    Args:
        config: Configuration object

    Returns:
        List of inbound ACL rule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("private-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-private-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "private"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) | ({toPort = rule.toPort} if rule?.toPort else {}) | ({icmpType = rule.icmpType} if rule?.icmpType else {}) | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.privateInboundAclRules
    ] if config.privateDedicatedNetworkAcl else []
}

# Generate private subnet outbound ACL rules
_generatePrivateOutboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates outbound Network ACL rules for private subnets.

    Args:
        config: Configuration object

    Returns:
        List of outbound ACL rule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("private-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-private-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "private"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) | ({toPort = rule.toPort} if rule?.toPort else {}) | ({icmpType = rule.icmpType} if rule?.icmpType else {}) | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.privateOutboundAclRules
    ] if config.privateDedicatedNetworkAcl else []
}

# ============================================================================
# MAIN NACL GENERATOR
# ============================================================================

# Generate all Network ACL resources
generateAllNACLs = lambda config: {str: any} -> [any] {
    """
    Generates all Network ACL resources.

    Args:
        config: Configuration object containing all NACL parameters

    Returns:
        List of all Network ACL resources
    """
    _generatePublicNetworkAcl(config) + \
    _generatePublicInboundAclRules(config) + \
    _generatePublicOutboundAclRules(config) + \
    _generatePrivateNetworkAcl(config) + \
    _generatePrivateInboundAclRules(config) + \
    _generatePrivateOutboundAclRules(config)
}
