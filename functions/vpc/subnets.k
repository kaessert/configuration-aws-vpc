"""
Subnets Module

This module handles generation of all subnet types:
- Public subnets (with public IP mapping)
- Private subnets
- Database subnets
- ElastiCache subnets
- Redshift subnets
- Intra (isolated) subnets

Supports both IPv4 and IPv6 configurations.
"""

# Import AWS EC2 provider models (v2 - namespaced resources)
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1

# Helper function to calculate IPv6 CIDR block for a subnet
_calculateSubnetIpv6Cidr = lambda vpcIpv6Cidr: str, prefix: int -> str {
    """
    Calculates the IPv6 CIDR block for a subnet given the VPC's IPv6 CIDR and a prefix index.

    AWS assigns VPCs a /56 IPv6 CIDR block. Subnets use /64 blocks.
    This function implements cidrsubnet(vpcIpv6Cidr, 8, prefix) logic.

    Args:
        vpcIpv6Cidr: The VPC's IPv6 CIDR block (e.g., "2600:1f13:d6f:5800::/56")
        prefix: The subnet prefix index (0-255)

    Returns:
        The calculated /64 CIDR block for the subnet

    Example:
        vpcIpv6Cidr = "2600:1f13:d6f:5800::/56"
        prefix = 0 -> "2600:1f13:d6f:5800::/64"
        prefix = 1 -> "2600:1f13:d6f:5801::/64"
        prefix = 5 -> "2600:1f13:d6f:5805::/64"
    """
    # Extract the base address (without /56 suffix)
    baseAddr = vpcIpv6Cidr.split("/")[0]

    # AWS /56 CIDR explanation:
    # - VPC gets /56 like "2600:1f13:d6f:5800::/56"
    # - 56 bits = 3.5 segments = segments 0-2 (48 bits) + upper 8 bits of segment 3
    # - Lower 8 bits of segment 3 are the subnet prefix (00-ff)
    # - For /64, we extend to full segment 3, then segments 4-7 are all zeros
    #
    # Example: "2600:1f13:d6f:5800::/56" with prefix 5
    # - segment[3] = "5800" (58 is the network, 00 is initially)
    # - Add prefix to lower 8 bits: 58 + 05 = "5805"
    # - Result: "2600:1f13:d6f:5805::/64"

    # Handle :: compression by expanding to full form
    if "::" in baseAddr:
        # Split on :: to get before and after parts
        parts = baseAddr.split("::")
        beforePart = parts[0] if parts[0] else ""
        afterPart = parts[1] if len(parts) > 1 and parts[1] else ""

        # Get non-empty segments from each part
        beforeSegs = [s for s in beforePart.split(":") if s] if beforePart else []
        afterSegs = [s for s in afterPart.split(":") if s] if afterPart else []

        # Calculate how many zero segments to insert
        existingCount = len(beforeSegs) + len(afterSegs)
        zeroCount = 8 - existingCount

        # Build full 8-segment address
        segments = beforeSegs + ["0"] * zeroCount + afterSegs
    else:
        # No compression - split and filter empty strings
        rawSegs = [s for s in baseAddr.split(":") if s]
        # Pad to 8 segments if needed
        segCount = len(rawSegs)
        padCount = 8 - segCount if segCount < 8 else 0
        segments = rawSegs + ["0"] * padCount

    # Ensure we have exactly 8 segments and all are valid hex strings
    # Clean up segments: strip whitespace, ensure non-empty, default to "0"
    cleanedSegs = [(s.strip() if s and s.strip() else "0") for s in segments]

    # Ensure exactly 8 segments (take first 8 or pad to 8)
    finalSegCount = len(cleanedSegs)
    segments = cleanedSegs[:8] if finalSegCount >= 8 else cleanedSegs + ["0"] * (8 - finalSegCount)

    # Get the base value of segment 3 and add the prefix
    # segment[3] has the upper 8 bits of the /56 network
    # Safely parse as hex, defaulting to 0 if invalid
    segment3Str = segments[3] if len(segments) > 3 else "0"
    segment3Value = int(segment3Str, 16) if segment3Str and segment3Str != "" else 0

    # Clear lower 8 bits and add prefix
    baseValue = (segment3Value // 256) * 256  # Keep upper 8 bits
    newSegment3 = baseValue + prefix
    hexPrefix = "{:x}".format(newSegment3)
    segments[3] = hexPrefix

    # For /64, segments 4-7 are all host bits (set to 0 for the network address)
    segments[4] = "0"
    segments[5] = "0"
    segments[6] = "0"
    segments[7] = "0"

    # Compress trailing zeros: if segments 4-7 are all "0", use :: notation
    # Result: "2600:1f13:d6f:5800::" instead of "2600:1f13:d6f:5800:0:0:0:0"
    compressedAddr = ":".join(segments[:4]) + "::"

    "${compressedAddr}/64"
}

# Helper function to build IPv6 configuration for subnets
_buildIpv6Config = lambda config, i: int, prefixList: [int] -> {str: any} {
    """
    Builds IPv6 configuration fields for a subnet.

    Args:
        config: Configuration object containing IPv6 settings
        i: Index of the subnet
        prefixList: List of IPv6 prefixes for this subnet type

    Returns:
        Dictionary with IPv6 configuration fields (empty if IPv6 disabled)
    """
    ipv6Config = {}

    if config.enableIpv6:
        # Calculate and set the IPv6 CIDR block if we have the VPC's IPv6 CIDR (late binding)
        # On first composition pass, observedVpcIpv6CidrBlock will be None
        # On subsequent passes, we'll calculate and set the subnet's IPv6 CIDR block
        if config.observedVpcIpv6CidrBlock and len(prefixList) > i:
            subnetPrefix = prefixList[i]
            subnetIpv6Cidr = _calculateSubnetIpv6Cidr(config.observedVpcIpv6CidrBlock, subnetPrefix)
            ipv6Config = ipv6Config | {ipv6CidrBlock = subnetIpv6Cidr}

            # Only set assignIpv6AddressOnCreation AFTER the IPv6 CIDR block is set
            # AWS requires the CIDR block to exist before this flag can be enabled
            if config.assignIpv6AddressOnCreation:
                ipv6Config = ipv6Config | {assignIpv6AddressOnCreation = True}

        # Add IPv6-native configuration
        # For dual-stack mode (IPv4 + IPv6), explicitly set ipv6Native = False
        # For IPv6-only mode, set ipv6Native = True
        ipv6Config = ipv6Config | {ipv6Native = config.ipv6Native if config.ipv6Native else False}

        # IPv6-native subnets typically need DNS64
        if config.ipv6Native and config.enableDns64:
            ipv6Config = ipv6Config | {enableDns64 = True}

        # For IPv6-native subnets, set DNS configuration defaults
        if config.ipv6Native:
            # Enable AAAA record for IPv6-native subnets
            ipv6Config = ipv6Config | {enableResourceNameDnsAaaaRecordOnLaunch = True}
            # Set DNS hostname type to resource-name for IPv6-native subnets
            ipv6Config = ipv6Config | {privateDnsHostnameTypeOnLaunch = "resource-name"}
        else:
            # For dual-stack mode, only add if explicitly configured
            if config.enableResourceNameDnsAaaaRecordOnLaunch:
                ipv6Config = ipv6Config | {enableResourceNameDnsAaaaRecordOnLaunch = True}
            if config.privateDnsHostnameTypeOnLaunch:
                ipv6Config = ipv6Config | {privateDnsHostnameTypeOnLaunch = config.privateDnsHostnameTypeOnLaunch}

    ipv6Config
}

# Generate public subnets distributed across AZs
_generatePublicSubnets = lambda config: {str: any} -> [any] {
    """
    Generates public subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of public subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("public-subnet-${i}") | {
                name = "subnet-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.publicSubnetTags) | {
                    "subnet-type": "public"
                    "subnet-index": str(i)
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = config.mapPublicIpOnLaunch
                    region = config.region
                    tags = config.tags | config.publicSubnetTags | {
                        Name = "subnet-public-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "public"
                    }
                } | _buildIpv6Config(config, i, config.publicSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.publicSubnets
    ] if len(config.publicSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate private subnets distributed across AZs
_generatePrivateSubnets = lambda config: {str: any} -> [any] {
    """
    Generates private subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of private subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("private-subnet-${i}") | {
                name = "subnet-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.privateSubnetTags) | {
                    "subnet-type": "private"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.privateSubnetTags | {
                        Name = "subnet-private-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "private"
                    }
                } | _buildIpv6Config(config, i, config.privateSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.privateSubnets
    ] if len(config.privateSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate database subnets distributed across AZs
_generateDatabaseSubnets = lambda config: {str: any} -> [any] {
    """
    Generates database subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of database subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("database-subnet-${i}") | {
                name = "subnet-database-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.databaseSubnetTags) | {
                    "subnet-type": "database"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.databaseSubnetTags | {
                        Name = "subnet-database-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "database"
                    }
                } | _buildIpv6Config(config, i, config.databaseSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.databaseSubnets
    ] if len(config.databaseSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate elasticache subnets distributed across AZs
_generateElasticacheSubnets = lambda config: {str: any} -> [any] {
    """
    Generates ElastiCache subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of elasticache subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("elasticache-subnet-${i}") | {
                name = "subnet-elasticache-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.elasticacheSubnetTags) | {
                    "subnet-type": "elasticache"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.elasticacheSubnetTags | {
                        Name = "subnet-elasticache-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "elasticache"
                    }
                } | _buildIpv6Config(config, i, config.elasticacheSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.elasticacheSubnets
    ] if len(config.elasticacheSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate redshift subnets distributed across AZs
_generateRedshiftSubnets = lambda config: {str: any} -> [any] {
    """
    Generates Redshift subnets distributed across availability zones.

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of redshift subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("redshift-subnet-${i}") | {
                name = "subnet-redshift-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.redshiftSubnetTags) | {
                    "subnet-type": "redshift"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.redshiftSubnetTags | {
                        Name = "subnet-redshift-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "redshift"
                    }
                } | _buildIpv6Config(config, i, config.redshiftSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.redshiftSubnets
    ] if len(config.redshiftSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate intra (isolated) subnets distributed across AZs
_generateIntraSubnets = lambda config: {str: any} -> [any] {
    """
    Generates intra (isolated) subnets distributed across availability zones.
    These subnets have no route to the internet (no IGW or NAT Gateway).

    Args:
        config: Configuration object containing subnet parameters

    Returns:
        List of intra subnet resources
    """
    [
        ec2v1beta1.Subnet{
            metadata = config.metadata("intra-subnet-${i}") | {
                name = "subnet-intra-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                labels = config.sanitizeLabels(config.tags | config.intraSubnetTags) | {
                    "subnet-type": "intra"
                    "az": config.azs[i % len(config.azs)]
                }
            }
            spec = config.defaultV2Spec | {
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    availabilityZone = config.azs[i % len(config.azs)]
                    cidrBlock = subnetCidr
                    mapPublicIpOnLaunch = False
                    region = config.region
                    tags = config.tags | config.intraSubnetTags | {
                        Name = "subnet-intra-${config.vpcName}-${config.azs[i % len(config.azs)]}"
                        Type = "intra"
                    }
                } | _buildIpv6Config(config, i, config.intraSubnetIpv6Prefixes)
            }
        }
        for i, subnetCidr in config.intraSubnets
    ] if len(config.intraSubnets) > 0 and len(config.azs) > 0 else []
}

# Generate all subnets
generateAllSubnets = lambda config: {str: any} -> [any] {
    """
    Generates all subnet types.

    Args:
        config: Configuration object containing all subnet parameters

    Returns:
        List of all subnet resources
    """
    _generatePublicSubnets(config) + \
    _generatePrivateSubnets(config) + \
    _generateDatabaseSubnets(config) + \
    _generateElasticacheSubnets(config) + \
    _generateRedshiftSubnets(config) + \
    _generateIntraSubnets(config)
}
