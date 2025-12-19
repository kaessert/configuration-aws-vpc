"""
Simple VPC E2E Test

Tests the terraform-aws-modules/vpc "simple" example scenario with real AWS resources:
- VPC with basic configuration
- Public subnets across multiple AZs
- Resources created and reach Ready/Synced state
- Proper cleanup after test

Spec: This validates the MINIMAL VPC test case from terraform-vpc-analysis.md in a real AWS environment
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-xvpc-simple"
        spec= {
            # Crossplane configuration
            crossplane: {
                version: "2.0.2-up.5"
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts (30 minutes for resource creation, 10 minutes for cleanup)
            timeoutSeconds: 1800
            cleanupTimeoutSeconds: 600

            # Ensure cleanup happens
            skipDelete: False

            # Validation: Check that resources reach Ready and Synced states
            defaultConditions: ["Ready", "Synced"]

            # Main test manifests - VPC Claim
            # Spec: Create a simple VPC with public subnets matching Terraform simple example
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"  # Using Claim, not XVPC
                    metadata: {
                        name: "e2e-test-vpc"
                        namespace: "default"
                    }
                    spec: {
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "e2e-test"
                            ManagedBy: "upbound"
                            TestType: "composition"
                        }
                        publicSubnetTags: {
                            Tier: "public"
                        }
                    }
                }
            ]

            # Extra resources - ProviderConfig for AWS authentication
            # IMPORTANT: Use IAM role, NEVER static credentials
            # Spec: Uses solutions org IAM role for E2E testing
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
                        # Use assumeRoleChain with IAM role (never static credentials!)
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