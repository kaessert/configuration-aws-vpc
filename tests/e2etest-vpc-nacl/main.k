"""
E2E Test: VPC with Dedicated Network ACLs

Validates Network ACL functionality with real AWS resources:
- VPC creation with specified CIDR block
- Public and private subnets
- Dedicated Network ACL for public subnets with custom rules
- Internet Gateway and NAT Gateway
- Resource lifecycle (create → ready → synced → delete)

This test validates task 3.2 (Network ACLs) implementation.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-nacl"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with dedicated Network ACLs
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-vpc-nacl"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a"]

                        # Public and private subnets
                        publicSubnets: ["10.0.1.0/24"]
                        privateSubnets: ["10.0.10.0/24"]

                        # Enable gateways
                        createIgw: True
                        enableNatGateway: True
                        singleNatGateway: True  # Cost optimization for E2E test

                        # Network ACL configuration for public subnets
                        publicDedicatedNetworkAcl: True
                        publicInboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 80
                                toPort: 80
                            },
                            {
                                ruleNumber: 110
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 443
                                toPort: 443
                            },
                            {
                                ruleNumber: 120
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 22
                                toPort: 22
                            },
                            {
                                ruleNumber: 130
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 1024
                                toPort: 65535
                            }
                        ]
                        publicOutboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "-1"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 0
                                toPort: 0
                            }
                        ]

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "vpc-nacl"
                            ManagedBy: "upbound-e2e"
                            Feature: "network-acls"
                        }
                        publicAclTags: {
                            Type: "public-nacl"
                            E2ETest: "true"
                        }
                    }
                }
            ]

            # ProviderConfig with IAM role (no static credentials)
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
        }
    }
]
items= _items
