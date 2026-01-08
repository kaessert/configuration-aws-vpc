"""
IPv6 Routing Composition Test

Tests IPv6 routing configuration:
- IPv6 routes (::/0) to IGW for public subnets
- IPv6 routes (::/0) to Egress-Only IGW for private subnets

Spec: This validates Task 4.3 - IPv6 routing

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-routing"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    tags: {
                        Name: "test-ipv6-routes"
                    }
                }
            }

            assertResources: [
                # Test Spec: Verify IPv6 public route (::/0) to IGW
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-ipv6-test-ipv6-routes"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            destinationIpv6CidrBlock: "::/0"
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "public"
                                }
                                matchControllerRef: True
                            }
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },

                # Test Spec: Verify IPv6 private route (::/0) to Egress-Only IGW
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-ipv6-test-ipv6-routes"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            destinationIpv6CidrBlock: "::/0"
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                                matchControllerRef: True
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
