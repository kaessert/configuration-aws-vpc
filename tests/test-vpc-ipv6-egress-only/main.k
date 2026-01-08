"""
IPv6 Egress-Only Internet Gateway Composition Test

Tests Egress-Only IGW for IPv6 private subnets:
- Egress-Only IGW created when createEgressOnlyIgw: True
- Used for outbound-only IPv6 connectivity from private subnets

Spec: This validates Task 4.3 - Egress-Only Internet Gateway

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-egress-only"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    # Egress-Only IGW for IPv6 private subnets
                    createEgressOnlyIgw: True

                    tags: {
                        Name: "test-ipv6-eigw"
                    }
                }
            }

            assertResources: [
                # Test Spec: Verify Egress-Only Internet Gateway is created
                ec2v1beta1.EgressOnlyInternetGateway{
                    metadata: {
                        name: "eigw-test-ipv6-eigw"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            tags: {
                                Name: "eigw-test-ipv6-eigw"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
