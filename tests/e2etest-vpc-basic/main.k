"""
E2E Test: Basic VPC with Public Subnets and IGW

Validates the core VPC functionality with real AWS resources:
- VPC creation with specified CIDR block
- Public subnets across multiple availability zones
- Internet Gateway attachment
- Public routing configuration
- Resource lifecycle (create → ready → synced → delete)

This test validates tasks 2.1, 2.2, and 2.3 implementation.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-basic"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: Basic VPC with public subnets and IGW
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-basic-vpc"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Public subnets
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

                        # Enable Internet Gateway
                        createIgw: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "basic-vpc"
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