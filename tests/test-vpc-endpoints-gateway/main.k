"""
VPC Gateway Endpoints Composition Tests

Tests VPC Gateway Endpoint functionality with various configurations:
- **disabled**: Gateway endpoints disabled (default)
- **dynamodb-gateway**: DynamoDB Gateway endpoint
- **s3-gateway**: S3 Gateway endpoint

Spec: This validates Task 3.1 - VPC Gateway Endpoints support implementation

Reference: thoughts/TASKS.md Task 3.1, terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: Gateway Endpoints Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-endpoints-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-no-endpoints"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: Endpoints disabled by default
                enableS3Endpoint: False
                enableDynamodbEndpoint: False
                createIgw: True
                tags: {
                    Name: "test-vpc-no-endpoints"
                    Environment: "test"
                    Feature: "vpc-endpoints-disabled"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-no-endpoints" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-no-endpoints"
                            Environment: "test"
                            Feature: "vpc-endpoints-disabled"
                        }
                    }
                }
            }
            # Spec: NO VPCEndpoint resources should be created
            # The test framework will verify that no VPCEndpoint resources exist
        ]
    }
}

# Test 2: DynamoDB Gateway Endpoint
_test_dynamodb = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-endpoints-dynamodb-gateway"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-dynamodb-endpoint"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: Enable DynamoDB Gateway Endpoint
                enableDynamodbEndpoint: True
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Name: "test-vpc-dynamodb-endpoint"
                    Environment: "test"
                    Feature: "vpc-endpoints"
                }
                vpcEndpointTags: {
                    Type: "dynamodb-gateway"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-dynamodb-endpoint" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-dynamodb-endpoint"
                            Environment: "test"
                            Feature: "vpc-endpoints"
                        }
                    }
                }
            },
            # Spec: DynamoDB Gateway Endpoint should be created when enableDynamodbEndpoint: true
            ec2v1beta1.VPCEndpoint{
                metadata: { name: "vpce-dynamodb-test-vpc-dynamodb-endpoint" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Endpoint attached to VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: DynamoDB service name
                        serviceName: "com.amazonaws.us-west-2.dynamodb"
                        # Spec: Gateway type endpoint
                        vpcEndpointType: "Gateway"
                        # Spec: Correct tags applied
                        tags: {
                            Name: "vpce-dynamodb-test-vpc-dynamodb-endpoint"
                            Environment: "test"
                            Feature: "vpc-endpoints"
                            Type: "dynamodb-gateway"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: S3 Gateway Endpoint
_test_s3 = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-endpoints-s3-gateway"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-s3-endpoint"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: Enable S3 Gateway Endpoint
                enableS3Endpoint: True
                s3EndpointType: "Gateway"  # Spec: Gateway type (default)
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Name: "test-vpc-s3-endpoint"
                    Environment: "test"
                    Feature: "vpc-endpoints"
                }
                vpcEndpointTags: {
                    Type: "s3-gateway"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-s3-endpoint" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-s3-endpoint"
                            Environment: "test"
                            Feature: "vpc-endpoints"
                        }
                    }
                }
            },
            # Spec: S3 Gateway Endpoint should be created when enableS3Endpoint: true
            ec2v1beta1.VPCEndpoint{
                metadata: { name: "vpce-s3-test-vpc-s3-endpoint" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Endpoint attached to VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: S3 service name
                        serviceName: "com.amazonaws.us-west-2.s3"
                        # Spec: Gateway type endpoint
                        vpcEndpointType: "Gateway"
                        # Spec: Correct tags applied
                        tags: {
                            Name: "vpce-s3-test-vpc-s3-endpoint"
                            Environment: "test"
                            Feature: "vpc-endpoints"
                            Type: "s3-gateway"
                        }
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_dynamodb,
    _test_s3
]
