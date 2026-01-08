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
# DATABASE SUBNET NETWORK ACLs
# ============================================================================

# Generate Database Network ACL
_generateDatabaseNetworkAcl = lambda config: {str: any} -> [any] {
    """
    Generates the Database subnet Network ACL.

    Args:
        config: Configuration object containing:
            - databaseDedicatedNetworkAcl: Whether to create dedicated NACL
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - region: AWS region
            - defaultV2Spec: Default v2 spec configuration
            - tags: Base tags
            - databaseAclTags: Additional database-specific tags

    Returns:
        List containing the Database NACL resource (or empty list if disabled)
    """
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("database-nacl") | {
                name = "nacl-database-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.databaseAclTags) | {
                    "subnet-type": "database"
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
                            "subnet-type": "database"
                        }
                    }
                    tags = config.tags | config.databaseAclTags | {
                        Name = "nacl-database-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.databaseDedicatedNetworkAcl else []
}

# Generate Database Inbound ACL Rules
_generateDatabaseInboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates inbound ACL rules for Database subnets.

    Args:
        config: Configuration object containing:
            - databaseDedicatedNetworkAcl: Whether database NACL is enabled
            - databaseInboundAclRules: List of inbound rule configurations
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - region: AWS region
            - defaultV2Spec: Default v2 spec configuration

    Returns:
        List of NetworkACLRule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("database-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-database-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "database"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.databaseInboundAclRules
    ] if config.databaseDedicatedNetworkAcl and len(config.databaseInboundAclRules) > 0 else []
}

# Generate Database Outbound ACL Rules
_generateDatabaseOutboundAclRules = lambda config: {str: any} -> [any] {
    """
    Generates outbound ACL rules for Database subnets.

    Args:
        config: Configuration object containing:
            - databaseDedicatedNetworkAcl: Whether database NACL is enabled
            - databaseOutboundAclRules: List of outbound rule configurations
            - metadata: Metadata helper function
            - vpcName: Name of the VPC
            - region: AWS region
            - defaultV2Spec: Default v2 spec configuration

    Returns:
        List of NetworkACLRule resources
    """
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("database-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-database-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = {
                            "subnet-type": "database"
                        }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.databaseOutboundAclRules
    ] if config.databaseDedicatedNetworkAcl and len(config.databaseOutboundAclRules) > 0 else []
}

# ============================================================================
# ELASTICACHE SUBNET NETWORK ACLs
# ============================================================================

# Generate ElastiCache Network ACL
_generateElastiCacheNetworkAcl = lambda config: {str: any} -> [any] {
    """Generates the ElastiCache subnet Network ACL."""
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("elasticache-nacl") | {
                name = "nacl-elasticache-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.elasticacheAclTags) | {
                    "subnet-type": "elasticache"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = { matchControllerRef = True }
                    subnetIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "elasticache" }
                    }
                    tags = config.tags | config.elasticacheAclTags | {
                        Name = "nacl-elasticache-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.elasticacheDedicatedNetworkAcl else []
}

# Generate ElastiCache Inbound ACL Rules
_generateElastiCacheInboundAclRules = lambda config: {str: any} -> [any] {
    """Generates inbound ACL rules for ElastiCache subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("elasticache-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-elasticache-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "elasticache" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.elasticacheInboundAclRules
    ] if config.elasticacheDedicatedNetworkAcl and len(config.elasticacheInboundAclRules) > 0 else []
}

# Generate ElastiCache Outbound ACL Rules
_generateElastiCacheOutboundAclRules = lambda config: {str: any} -> [any] {
    """Generates outbound ACL rules for ElastiCache subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("elasticache-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-elasticache-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "elasticache" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.elasticacheOutboundAclRules
    ] if config.elasticacheDedicatedNetworkAcl and len(config.elasticacheOutboundAclRules) > 0 else []
}

# ============================================================================
# REDSHIFT SUBNET NETWORK ACLs
# ============================================================================

# Generate Redshift Network ACL
_generateRedshiftNetworkAcl = lambda config: {str: any} -> [any] {
    """Generates the Redshift subnet Network ACL."""
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("redshift-nacl") | {
                name = "nacl-redshift-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.redshiftAclTags) | {
                    "subnet-type": "redshift"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = { matchControllerRef = True }
                    subnetIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "redshift" }
                    }
                    tags = config.tags | config.redshiftAclTags | {
                        Name = "nacl-redshift-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.redshiftDedicatedNetworkAcl else []
}

# Generate Redshift Inbound ACL Rules
_generateRedshiftInboundAclRules = lambda config: {str: any} -> [any] {
    """Generates inbound ACL rules for Redshift subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("redshift-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-redshift-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "redshift" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.redshiftInboundAclRules
    ] if config.redshiftDedicatedNetworkAcl and len(config.redshiftInboundAclRules) > 0 else []
}

# Generate Redshift Outbound ACL Rules
_generateRedshiftOutboundAclRules = lambda config: {str: any} -> [any] {
    """Generates outbound ACL rules for Redshift subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("redshift-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-redshift-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "redshift" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.redshiftOutboundAclRules
    ] if config.redshiftDedicatedNetworkAcl and len(config.redshiftOutboundAclRules) > 0 else []
}

# ============================================================================
# INTRA SUBNET NETWORK ACLs
# ============================================================================

# Generate Intra Network ACL
_generateIntraNetworkAcl = lambda config: {str: any} -> [any] {
    """Generates the Intra subnet Network ACL."""
    [
        ec2v1beta1.NetworkACL{
            metadata = config.metadata("intra-nacl") | {
                name = "nacl-intra-${config.vpcName}"
                labels = config.sanitizeLabels(config.tags | config.intraAclTags) | {
                    "subnet-type": "intra"
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    vpcIdSelector = { matchControllerRef = True }
                    subnetIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "intra" }
                    }
                    tags = config.tags | config.intraAclTags | {
                        Name = "nacl-intra-${config.vpcName}"
                    }
                }
            }
        }
    ] if config.intraDedicatedNetworkAcl else []
}

# Generate Intra Inbound ACL Rules
_generateIntraInboundAclRules = lambda config: {str: any} -> [any] {
    """Generates inbound ACL rules for Intra subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("intra-inbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-intra-in-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "intra" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = False
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.intraInboundAclRules
    ] if config.intraDedicatedNetworkAcl and len(config.intraInboundAclRules) > 0 else []
}

# Generate Intra Outbound ACL Rules
_generateIntraOutboundAclRules = lambda config: {str: any} -> [any] {
    """Generates outbound ACL rules for Intra subnets."""
    [
        ec2v1beta1.NetworkACLRule{
            metadata = config.metadata("intra-outbound-rule-${rule.ruleNumber}") | {
                name = "nacl-rule-intra-out-${rule.ruleNumber}-${config.vpcName}"
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    region = config.region
                    networkAclIdSelector = {
                        matchControllerRef = True
                        matchLabels = { "subnet-type": "intra" }
                    }
                    ruleNumber = rule.ruleNumber
                    protocol = _protocolToNumber(rule.protocol)
                    ruleAction = rule.ruleAction
                    cidrBlock = rule.cidrBlock
                    egress = True
                } | ({fromPort = rule.fromPort} if rule?.fromPort else {}) \
                  | ({toPort = rule.toPort} if rule?.toPort else {}) \
                  | ({icmpType = rule.icmpType} if rule?.icmpType else {}) \
                  | ({icmpCode = rule.icmpCode} if rule?.icmpCode else {})
            }
        }
        for rule in config.intraOutboundAclRules
    ] if config.intraDedicatedNetworkAcl and len(config.intraOutboundAclRules) > 0 else []
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
    _generatePrivateOutboundAclRules(config) + \
    _generateDatabaseNetworkAcl(config) + \
    _generateDatabaseInboundAclRules(config) + \
    _generateDatabaseOutboundAclRules(config) + \
    _generateElastiCacheNetworkAcl(config) + \
    _generateElastiCacheInboundAclRules(config) + \
    _generateElastiCacheOutboundAclRules(config) + \
    _generateRedshiftNetworkAcl(config) + \
    _generateRedshiftInboundAclRules(config) + \
    _generateRedshiftOutboundAclRules(config) + \
    _generateIntraNetworkAcl(config) + \
    _generateIntraInboundAclRules(config) + \
    _generateIntraOutboundAclRules(config)
}
