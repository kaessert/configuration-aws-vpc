"""
Shared Resource Builder Functions

Common builder functions for creating test resources with consistent patterns.
Reduces boilerplate and ensures consistency across tests.

Usage Pattern:
-------------
Import and use builder functions to create resources with standard configuration:

Example:
    import builders

    _vpc = builders._buildVPC({
        name: "vpc-test",
        region: "us-west-2",
        cidrBlock: "10.0.0.0/16",
        tags: { Environment: "test" }
    })

Alternative (Recommended):
-------------------------
Define builder functions locally within each test file for better self-containment:

    # Within tests/test-my-feature/main.k
    _buildSubnet = lambda config: {str: any} {
        ec2v1beta1.Subnet {
            metadata: { name: config.name }
            spec: {
                providerConfigRef: { kind: "ProviderConfig", name: "default" }
                managementPolicies: ["*"]
                forProvider: {
                    region: config.region
                    cidrBlock: config.cidrBlock
                    availabilityZone: config.az
                    vpcIdSelector: { matchControllerRef: True }
                    tags: config.tags
                }
            }
        }
    }

NOTE: Cross-directory imports in KCL have limitations. Local builder definitions
within test files are recommended for better self-containment.

Reference: KCL lambda functions and resource building patterns
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1


# Builder for VPC resources
# Usage: _buildVPC({ name: "vpc-test", region: "us-west-2", cidrBlock: "10.0.0.0/16", tags: {...} })
_buildVPC = lambda config: {str: any} {
    ec2v1beta1.VPC {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                cidrBlock: config.cidrBlock
                enableDnsHostnames: config.get("enableDnsHostnames", True)
                enableDnsSupport: config.get("enableDnsSupport", True)
                tags: config.tags
            }
        }
    }
}

# Builder for Subnet resources
# Usage: _buildSubnet({ name: "subnet-test", region: "us-west-2", cidrBlock: "10.0.1.0/24", az: "us-west-2a", tags: {...} })
_buildSubnet = lambda config: {str: any} {
    ec2v1beta1.Subnet {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                cidrBlock: config.cidrBlock
                availabilityZone: config.az
                vpcIdSelector: { matchControllerRef: True }
                mapPublicIpOnLaunch: config.get("mapPublicIpOnLaunch", False)
                tags: config.tags
            }
        }
    }
}

# Builder for Internet Gateway resources
# Usage: _buildInternetGateway({ name: "igw-test", region: "us-west-2", tags: {...} })
_buildInternetGateway = lambda config: {str: any} {
    ec2v1beta1.InternetGateway {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                vpcIdSelector: { matchControllerRef: True }
                tags: config.tags
            }
        }
    }
}

# Builder for NAT Gateway resources
# Usage: _buildNATGateway({ name: "nat-test", region: "us-west-2", subnetLabels: {...}, tags: {...} })
_buildNATGateway = lambda config: {str: any} {
    ec2v1beta1.NATGateway {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                subnetIdSelector: {
                    matchControllerRef: True
                    matchLabels: config.subnetLabels
                }
                tags: config.tags
            }
        }
    }
}

# Builder for Route Table resources
# Usage: _buildRouteTable({ name: "rt-test", region: "us-west-2", tags: {...} })
_buildRouteTable = lambda config: {str: any} {
    ec2v1beta1.RouteTable {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                vpcIdSelector: { matchControllerRef: True }
                tags: config.tags
            }
        }
    }
}

# Builder for Security Group resources
# Usage: _buildSecurityGroup({ name: "sg-test", region: "us-west-2", description: "Test SG", tags: {...} })
_buildSecurityGroup = lambda config: {str: any} {
    ec2v1beta1.SecurityGroup {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                description: config.description
                vpcIdSelector: { matchControllerRef: True }
                tags: config.tags
            }
        }
    }
}

# Builder for Network ACL resources
# Usage: _buildNetworkACL({ name: "nacl-test", region: "us-west-2", tags: {...} })
_buildNetworkACL = lambda config: {str: any} {
    ec2v1beta1.NetworkACL {
        metadata: {
            name: config.name
        }
        spec: {
            providerConfigRef: {
                kind: "ProviderConfig"
                name: "default"
            }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                vpcIdSelector: { matchControllerRef: True }
                tags: config.tags
            }
        }
    }
}

# Helper function to merge tags
# Usage: mergeTags({ Environment: "test" }, { Feature: "vpc" }) -> { Environment: "test", Feature: "vpc" }
mergeTags = lambda baseTags: {str: str}, additionalTags: {str: str} -> {str: str} {
    {**baseTags, **additionalTags}
}

# Helper function to build subnet name
# Usage: buildSubnetName("test-vpc", "public", "us-west-2a") -> "subnet-public-test-vpc-us-west-2a"
buildSubnetName = lambda vpcName: str, subnetType: str, az: str -> str {
    "subnet-${subnetType}-${vpcName}-${az}"
}

# Helper function to build resource name with prefix
# Usage: buildResourceName("nat", "test-vpc", "us-west-2a") -> "nat-test-vpc-us-west-2a"
buildResourceName = lambda resourceType: str, vpcName: str, suffix: str -> str {
    "${resourceType}-${vpcName}-${suffix}" if suffix else "${resourceType}-${vpcName}"
}
