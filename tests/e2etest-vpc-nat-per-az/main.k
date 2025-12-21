"""
E2E Test: VPC with NAT Gateway Per AZ

Validates VPC with NAT Gateway per AZ strategy with real AWS resources:
- VPC with public and private subnets across multiple AZs
- Internet Gateway for public subnets
- Multiple NAT Gateways (one per AZ for high availability)
- Multiple Elastic IPs (one per NAT Gateway)
- Public routing (via IGW)
- Private routing (each AZ's private subnets route via their AZ's NAT)
- Resource lifecycle (create → ready → synced → delete)

This test validates tasks 2.4 (per-AZ NAT strategy) and 2.5 (per-AZ routing).
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-nat-per-az"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with NAT Gateway per AZ
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-nat-per-az-vpc"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.2.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Public subnets (for IGW and NAT placement)
                        publicSubnets: ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]

                        # Private subnets (each AZ routes via its own NAT)
                        privateSubnets: ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]

                        # Enable Internet Gateway
                        createIgw: True

                        # Enable NAT Gateway - PER AZ strategy (high availability)
                        enableNatGateway: True
                        singleNatGateway: False
                        oneNatGatewayPerAz: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "nat-per-az"
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
