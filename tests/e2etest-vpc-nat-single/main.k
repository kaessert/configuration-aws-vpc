"""
E2E Test: VPC with Single NAT Gateway

Validates VPC with single NAT Gateway strategy with real AWS resources:
- VPC with public and private subnets
- Internet Gateway for public subnets
- Single NAT Gateway (cost-optimized, placed in first public subnet)
- Single Elastic IP for NAT Gateway
- Public routing (via IGW)
- Private routing (all private subnets route via single NAT)
- Resource lifecycle (create → ready → synced → delete)

This test validates tasks 2.4 (single NAT strategy) and 2.5 (routing).
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-nat-single"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with single NAT Gateway
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-nat-single-vpc"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.1.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Public subnets (for IGW and NAT placement)
                        publicSubnets: ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

                        # Private subnets (will route via single NAT)
                        privateSubnets: ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]

                        # Enable Internet Gateway
                        createIgw: True

                        # Enable NAT Gateway - SINGLE strategy
                        enableNatGateway: True
                        singleNatGateway: True
                        oneNatGatewayPerAz: False

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "nat-single"
                            ManagedBy: "upbound-e2e"
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
                        }
                        assumeRoleChain: [
                            {
                                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                            }
                        ]
                    }
                }
            ]
        }
    }
]
items= _items
