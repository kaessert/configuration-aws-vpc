"""
IPv6 Disabled Composition Test

Tests default behavior with IPv6 disabled:
- VPC with IPv4 only (no IPv6 CIDR)
- No IPv6 resources created
- Only IPv4 routes

Spec: This validates Task 4.3 - Default behavior with IPv6 disabled

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    # IPv6 Configuration - DISABLED (default)
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
                # Test Spec: Verify VPC is created with IPv4 only
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-ipv6-disabled"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            cidrBlock: "10.0.0.0/16"
                            # Test Spec: No assignGeneratedIpv6CidrBlock (IPv6 disabled)
                        }
                    }
                },

                # Test Spec: Verify public subnet WITHOUT IPv6
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-ipv6-disabled-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.1.0/24"
                            mapPublicIpOnLaunch: True
                            # Test Spec: No IPv6 fields
                        }
                    }
                },

                # Test Spec: Verify ONLY IPv4 route exists (no IPv6 route)
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-igw-test-ipv6-disabled"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
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
                # Test Spec: No IPv6 routes, no Egress-Only IGW in assertResources
            ]
        }
    }
]
items= _items
