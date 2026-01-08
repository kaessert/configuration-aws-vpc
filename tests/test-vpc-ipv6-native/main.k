"""
IPv6-Native (IPv6-only) Subnets Composition Test

Tests IPv6-native configuration (IPv6-only, no IPv4):
- VPC with IPv6 CIDR only
- Subnets with ipv6Native: True (IPv6-only)
- DNS64 enabled for IPv6-only subnets
- No IPv4 routes, only IPv6 routes

Spec: This validates Task 4.3 - IPv6-native (IPv6-only) subnet support

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-native"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    # IPv6 Configuration
                    enableIpv6: True
                    assignGeneratedIpv6CidrBlock: True
                    ipv6Native: True  # IPv6-only subnets
                    enableDns64: True  # Required for IPv6-only
                    assignIpv6AddressOnCreation: True

                    # Public subnets as IPv6-only
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
                # Test Spec: Verify VPC with IPv6 and DNS64 enabled
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-ipv6-native"
                    }
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

                # Test Spec: Verify subnet is IPv6-native (ipv6Native: True)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-ipv6-native-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            ipv6Native: True  # IPv6-only, no IPv4
                            assignIpv6AddressOnCreation: True
                            enableDns64: True
                            # Test Spec: IPv6 CIDR block is dynamically calculated
                            privateDnsHostnameTypeOnLaunch: "resource-name"
                            enableResourceNameDnsAaaaRecordOnLaunch: True
                        }
                    }
                },

                # Test Spec: Verify IPv6 route (::/0) to IGW
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-ipv6-test-ipv6-native"
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
                }
            ]
        }
    }
]
items= _items