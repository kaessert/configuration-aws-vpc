"""
E2E Test: IPv6 Dual-Stack VPC

Tests a complete IPv6 dual-stack VPC deployment in AWS:
- VPC with both IPv4 CIDR and Amazon-provided IPv6 CIDR
- Public and private subnets with IPv6
- Internet Gateway for public IPv4 and IPv6 traffic
- NAT Gateway for private IPv4 traffic
- Egress-Only Internet Gateway for private IPv6 traffic
- Complete routing for both IPv4 and IPv6

This test validates Task 4.3 - IPv6 support in a real AWS environment.

Expected duration: 30-40 minutes
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-ipv6-dual-stack"
        spec= {
            crossplane: {
                version: "2.0.2-up.5"
                autoUpgrade: {
                    channel: "Rapid"
                }
            }
            defaultConditions: ["Ready"]
            timeoutSeconds: 4500  # 75 minutes for IPv6 resource creation
            skipDelete: False

            # Extra resources - ProviderConfig needs to be in extraResources
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"
                            upbound: {
                                webIdentity: {
                                    roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
                    }
                }
            ]

            manifests: [
                # IPv6 Dual-Stack VPC Configuration
                awsv1alpha1.VPC{
                    metadata.name: "e2e-ipv6-dual-stack"
                    metadata.namespace: "default"
                    spec: {
                        region: "us-west-2"
                        cidr: "10.50.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # IPv6 Configuration
                        enableIpv6: True
                        assignGeneratedIpv6CidrBlock: True
                        assignIpv6AddressOnCreation: True

                        # Public subnets with IPv6
                        publicSubnets: [
                            "10.50.1.0/24"
                            "10.50.2.0/24"
                            "10.50.3.0/24"
                        ]
                        publicSubnetIpv6Prefixes: [0, 1, 2]
                        mapPublicIpOnLaunch: True

                        # Private subnets with IPv6
                        privateSubnets: [
                            "10.50.11.0/24"
                            "10.50.12.0/24"
                            "10.50.13.0/24"
                        ]
                        privateSubnetIpv6Prefixes: [3, 4, 5]

                        # Gateway configuration
                        createIgw: True
                        enableNatGateway: True
                        singleNatGateway: True  # Cost-optimized for testing
                        createEgressOnlyIgw: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        tags: {
                            Name: "e2e-ipv6-dual-stack"
                            Environment: "test"
                            TestType: "e2e-ipv6-dual-stack"
                            ManagedBy: "crossplane"
                        }
                    }
                }
            ]
        }
    }
]
items= _items
