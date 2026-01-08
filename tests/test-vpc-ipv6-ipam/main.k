"""
IPv6 IPAM Pool Allocation Composition Test

Tests IPv6 IPAM integration:
- VPC with IPv6 allocated from IPAM pool
- ipv6IpamPoolId and ipv6NetmaskLength specified

Spec: This validates Task 4.3 - IPv6 IPAM pool allocation

Reference: thoughts/TASKS.md Task 4.3
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipv6-ipam"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: True
            timeoutSeconds: 60

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

                    # IPv6 IPAM Configuration
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
                # Test Spec: Verify VPC uses IPAM pool for IPv6
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-ipv6-ipam"
                    }
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
]
items= _items
