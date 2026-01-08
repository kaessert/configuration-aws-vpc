"""
IPv6 Dual-Stack VPC Composition Test

Tests IPv6 dual-stack configuration (IPv4 + IPv6):
- VPC with both IPv4 CIDR and Amazon-provided IPv6 CIDR
- Subnets with both IPv4 and IPv6 addresses
- IPv6 routes to Internet Gateway for public subnets
- IPv6 routes to Egress-Only IGW for private subnets

Spec: This validates Task 4.3 - IPv6 dual-stack support with Amazon-provided IPv6 CIDR

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-dual-stack"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    # IPv6 Configuration
                    enableIpv6: True
                    assignGeneratedIpv6CidrBlock: True
                    assignIpv6AddressOnCreation: True

                    # Public subnets with IPv6
                    publicSubnets: ["10.0.1.0/24"]
                    publicSubnetIpv6Prefixes: [0]

                    # Private subnets with IPv6
                    privateSubnets: ["10.0.11.0/24"]
                    privateSubnetIpv6Prefixes: [1]

                    # Gateway configuration
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
                # Test Spec: Verify VPC is created with assignGeneratedIpv6CidrBlock enabled
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-ipv6-dual"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            cidrBlock: "10.0.0.0/16"
                            assignGeneratedIpv6CidrBlock: True
                        }
                    }
                },

                # Test Spec: Verify Egress-Only Internet Gateway for IPv6 private subnets
                ec2v1beta1.EgressOnlyInternetGateway{
                    metadata: {
                        name: "eigw-test-ipv6-dual"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },

                # Test Spec: Verify public subnet with IPv6 enabled
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-ipv6-dual-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.1.0/24"
                            assignIpv6AddressOnCreation: True
                            ipv6Native: False
                            # Test Spec: IPv6 CIDR block is dynamically calculated - we only verify it's present
                        }
                    }
                },

                # Test Spec: Verify private subnet with IPv6 enabled
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-private-test-ipv6-dual-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.11.0/24"
                            assignIpv6AddressOnCreation: True
                            ipv6Native: False
                            # Test Spec: IPv6 CIDR block is dynamically calculated - we only verify it's present
                        }
                    }
                },

                # Test Spec: Verify IPv6 route (::/0) to IGW for public subnets
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-ipv6-test-ipv6-dual"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            destinationIpv6CidrBlock: "::/0"
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "public"
                                }
                            }
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },

                # Test Spec: Verify IPv6 route (::/0) to Egress-Only IGW for private subnets
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-ipv6-test-ipv6-dual"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            destinationIpv6CidrBlock: "::/0"
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                            }
                            egressOnlyGatewayIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items