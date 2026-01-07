"""
E2E Test: Secondary CIDR Blocks

Validates VPC with secondary CIDR blocks with real AWS resources:
- VPC with primary CIDR block (10.0.0.0/16)
- Two secondary CIDR blocks (10.1.0.0/16, 10.2.0.0/16)
- Public subnets using primary CIDR
- Private subnets using first secondary CIDR
- Database subnets using second secondary CIDR
- VPCIPv4CidrBlockAssociation resources created and ready
- All subnets properly created across all CIDR blocks
- Resource lifecycle (create → ready → synced → delete)

This test validates Task 3.6 (Secondary CIDR Blocks) implementation.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-secondary-cidr"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with primary + 2 secondary CIDR blocks
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-secondary-cidr"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"

                        # Primary CIDR block
                        cidr: "10.0.0.0/16"

                        # Secondary CIDR blocks for IP space expansion
                        secondaryCidrBlocks: [
                            "10.1.0.0/16",
                            "10.2.0.0/16"
                        ]

                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Subnets distributed across all CIDR blocks
                        # Public subnets from primary CIDR (10.0.x.x)
                        publicSubnets: [
                            "10.0.1.0/24",
                            "10.0.2.0/24",
                            "10.0.3.0/24"
                        ]

                        # Private subnets from first secondary CIDR (10.1.x.x)
                        privateSubnets: [
                            "10.1.1.0/24",
                            "10.1.2.0/24",
                            "10.1.3.0/24"
                        ]

                        # Database subnets from second secondary CIDR (10.2.x.x)
                        databaseSubnets: [
                            "10.2.1.0/24",
                            "10.2.2.0/24",
                            "10.2.3.0/24"
                        ]

                        # Enable Internet Gateway for public subnets
                        createIgw: True

                        # Enable NAT Gateway for private subnet internet access
                        enableNatGateway: True
                        singleNatGateway: True  # Cost-optimized: single NAT

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags for resource identification
                        tags: {
                            Environment: "e2e-test"
                            TestName: "secondary-cidr-blocks"
                            ManagedBy: "upbound-e2e"
                            Feature: "secondary-cidr"
                            Purpose: "ip-space-expansion"
                        }

                        # Subnet-specific tags
                        publicSubnetTags: {
                            Type: "public-from-primary-cidr"
                            CIDRBlock: "10.0.0.0/16"
                        }
                        privateSubnetTags: {
                            Type: "private-from-secondary-cidr-1"
                            CIDRBlock: "10.1.0.0/16"
                        }
                        databaseSubnetTags: {
                            Type: "database-from-secondary-cidr-2"
                            CIDRBlock: "10.2.0.0/16"
                        }
                    }
                }
            ]

            # ProviderConfig with IAM role (no static credentials)
            # Uses Upbound's web identity federation
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
