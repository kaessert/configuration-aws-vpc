"""
IPv6 Composition Tests

Tests IPv6 functionality with various configurations:
- **disabled**: IPv6 disabled (default, IPv4 only)
- **dual-stack**: Dual-stack VPC (IPv4 + IPv6) with late-binding pattern
- **egress-only**: Egress-Only IGW for IPv6 private subnets
- **ipam**: IPv6 IPAM pool allocation
- **native**: IPv6-native (IPv6-only) subnets with DNS64
- **routing**: IPv6 routing to IGW and Egress-Only IGW

Spec: This validates Task 4.3 - IPv6 support implementation

Reference: thoughts/TASKS.md Task 4.3, terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: IPv6 Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-disabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                # Spec: IPv6 disabled by default
                enableIpv6: False
                publicSubnets: ["10.0.1.0/24"]
                createIgw: True
                tags: {
                    Name: "test-ipv6-disabled"
                    TestType: "ipv6-disabled"
                }
            }
        }
        assertResources: [
            # Spec: VPC with IPv4 only (no IPv6)
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-ipv6-disabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        # Spec: No assignGeneratedIpv6CidrBlock (IPv6 disabled)
                    }
                }
            },
            # Spec: Public subnet WITHOUT IPv6
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-ipv6-disabled-us-west-2a-0" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        # Spec: No IPv6 fields
                    }
                }
            },
            # Spec: ONLY IPv4 route (no IPv6 route)
            ec2v1beta1.Route{
                metadata: { name: "route-public-igw-test-ipv6-disabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
            # Spec: No IPv6 routes, no Egress-Only IGW in assertResources
        ]
    }
}

# Test 2: IPv6 Dual-Stack (IPv4 + IPv6) with late-binding
_test_dual_stack = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-dual-stack-phase1-initial"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-dual"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                # Spec: IPv6 dual-stack configuration
                enableIpv6: True
                assignGeneratedIpv6CidrBlock: True
                assignIpv6AddressOnCreation: True
                publicSubnets: ["10.0.1.0/24"]
                publicSubnetIpv6Prefixes: [0]
                privateSubnets: ["10.0.11.0/24"]
                privateSubnetIpv6Prefixes: [1]
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                createEgressOnlyIgw: True
                tags: {
                    Name: "test-ipv6-dual"
                    TestType: "ipv6-dual-stack"
                }
            }
        }
        assertResources: [
            # Spec: VPC with assignGeneratedIpv6CidrBlock enabled
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-ipv6-dual" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        assignGeneratedIpv6CidrBlock: True
                    }
                }
            },
            # Spec: Egress-Only Internet Gateway for IPv6 private subnets
            ec2v1beta1.EgressOnlyInternetGateway{
                metadata: { name: "eigw-test-ipv6-dual" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: Public subnet - Phase 1 (no IPv6 CIDR yet due to late-binding)
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-ipv6-dual-us-west-2a-0" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        ipv6Native: False
                        # NO ipv6CidrBlock or assignIpv6AddressOnCreation yet
                    }
                }
            },
            # Spec: Private subnet - Phase 1 (no IPv6 CIDR yet due to late-binding)
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-private-test-ipv6-dual-us-west-2a-1" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.11.0/24"
                        ipv6Native: False
                        # NO ipv6CidrBlock or assignIpv6AddressOnCreation yet
                    }
                }
            },
            # Spec: IPv6 route (::/0) to IGW for public subnets
            ec2v1beta1.Route{
                metadata: { name: "route-public-ipv6-test-ipv6-dual" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationIpv6CidrBlock: "::/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: IPv6 route (::/0) to Egress-Only IGW for private subnets
            ec2v1beta1.Route{
                metadata: { name: "route-private-ipv6-test-ipv6-dual" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationIpv6CidrBlock: "::/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                        }
                        egressOnlyGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

# Test 3: IPv6 Egress-Only Internet Gateway
_test_egress_only = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-egress-only"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-eigw"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                enableIpv6: True
                assignGeneratedIpv6CidrBlock: True
                privateSubnets: ["10.0.11.0/24"]
                privateSubnetIpv6Prefixes: [0]
                # Spec: Egress-Only IGW for IPv6 private subnets
                createEgressOnlyIgw: True
                tags: { Name: "test-ipv6-eigw" }
            }
        }
        assertResources: [
            # Spec: Egress-Only Internet Gateway is created
            ec2v1beta1.EgressOnlyInternetGateway{
                metadata: { name: "eigw-test-ipv6-eigw" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        tags: { Name: "eigw-test-ipv6-eigw" }
                    }
                }
            }
        ]
    }
}

# Test 4: IPv6 IPAM Pool Allocation
_test_ipam = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-ipam"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-ipam"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                # Spec: IPv6 IPAM pool configuration
                enableIpv6: True
                ipv6IpamPoolId: "ipam-pool-12345678"
                ipv6NetmaskLength: 56
                publicSubnets: ["10.0.1.0/24"]
                createIgw: True
                tags: {
                    Name: "test-ipv6-ipam"
                    TestType: "ipv6-ipam"
                }
            }
        }
        assertResources: [
            # Spec: VPC uses IPAM pool for IPv6
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-ipv6-ipam" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        ipv6IpamPoolId: "ipam-pool-12345678"
                        ipv6NetmaskLength: 56
                    }
                }
            }
        ]
    }
}

# Test 5: IPv6-Native (IPv6-only) Subnets with DNS64
_test_native = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-native-phase1-initial"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-native"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"  # VPC still needs IPv4, but subnets are IPv6-only
                azs: ["us-west-2a"]
                # Spec: IPv6-native (IPv6-only) configuration
                enableIpv6: True
                assignGeneratedIpv6CidrBlock: True
                ipv6Native: True
                enableDns64: True
                assignIpv6AddressOnCreation: True
                publicSubnets: ["10.0.1.0/24"]
                publicSubnetIpv6Prefixes: [0]
                createIgw: True
                tags: {
                    Name: "test-ipv6-native"
                    TestType: "ipv6-native"
                }
            }
        }
        assertResources: [
            # Spec: VPC with IPv6 and DNS64 enabled
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-ipv6-native" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        assignGeneratedIpv6CidrBlock: True
                        enableDnsHostnames: True
                        enableDnsSupport: True
                    }
                }
            },
            # Spec: Subnet is IPv6-native (ipv6Native: True) - Phase 1
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-ipv6-native-us-west-2a-0" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        ipv6Native: True  # IPv6-only, no IPv4
                        enableDns64: True
                        # NO ipv6CidrBlock or assignIpv6AddressOnCreation yet
                        privateDnsHostnameTypeOnLaunch: "resource-name"
                        enableResourceNameDnsAaaaRecordOnLaunch: True
                    }
                }
            },
            # Spec: IPv6 route (::/0) to IGW
            ec2v1beta1.Route{
                metadata: { name: "route-public-ipv6-test-ipv6-native" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationIpv6CidrBlock: "::/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

# Test 6: IPv6 Routing
_test_routing = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-ipv6-routing"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-ipv6-routes"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                enableIpv6: True
                assignGeneratedIpv6CidrBlock: True
                publicSubnets: ["10.0.1.0/24"]
                privateSubnets: ["10.0.11.0/24"]
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                createEgressOnlyIgw: True
                tags: { Name: "test-ipv6-routes" }
            }
        }
        assertResources: [
            # Spec: IPv6 public route (::/0) to IGW
            ec2v1beta1.Route{
                metadata: { name: "route-public-ipv6-test-ipv6-routes" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationIpv6CidrBlock: "::/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                            matchControllerRef: True
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: IPv6 private route (::/0) to Egress-Only IGW
            ec2v1beta1.Route{
                metadata: { name: "route-private-ipv6-test-ipv6-routes" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        destinationIpv6CidrBlock: "::/0"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                            matchControllerRef: True
                        }
                        egressOnlyGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_dual_stack,
    _test_egress_only,
    _test_ipam,
    _test_native,
    _test_routing
]
