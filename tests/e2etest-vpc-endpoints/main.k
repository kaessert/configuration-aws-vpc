"""
E2E Test: VPC with S3 and DynamoDB Gateway Endpoints

Validates VPC Endpoints functionality with real AWS resources:
- VPC creation with specified CIDR block
- Public and private subnets
- Internet Gateway and NAT Gateway
- S3 Gateway Endpoint creation and configuration
- DynamoDB Gateway Endpoint creation and configuration
- Resource lifecycle (create → ready → synced → delete)

This test validates task 3.1 (VPC Endpoints) implementation.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-endpoints"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes (endpoints can take time to provision)
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with S3 and DynamoDB Gateway Endpoints
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-vpc-endpoints"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]

                        # Public and private subnets
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                        privateSubnets: ["10.0.10.0/24", "10.0.20.0/24"]

                        # Enable gateways
                        createIgw: True
                        enableNatGateway: True
                        singleNatGateway: True  # Cost optimization for E2E test

                        # VPC Endpoints configuration
                        enableS3Endpoint: True
                        s3EndpointType: "Gateway"
                        enableDynamodbEndpoint: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "vpc-endpoints"
                            ManagedBy: "upbound-e2e"
                            Feature: "vpc-endpoints"
                        }
                        vpcEndpointTags: {
                            Type: "gateway-endpoint"
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
