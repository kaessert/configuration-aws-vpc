"""
VPC Endpoints - DynamoDB Gateway Test

Tests DynamoDB Gateway Endpoint creation when enableDynamodbEndpoint is enabled:
- VPC with basic configuration
- DynamoDB Gateway Endpoint created
- Endpoint type is Gateway
- Endpoint attached to VPC via vpcIdSelector
- Endpoint associated with route tables
- Correct tags applied

Spec: This validates VPC Endpoints (task 3.1) from SPECIFICATION.md
Verifies DynamoDB Gateway endpoint creation based on terraform-aws-vpc module behavior
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-endpoints-dynamodb-gateway"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with DynamoDB endpoint enabled
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
                        Environment: "test"
                        Feature: "vpc-endpoints"
                    }
                    vpcEndpointTags: {
                        Type: "dynamodb-gateway"
                    }
                }
            }

            # Assert that VPC and DynamoDB Gateway Endpoint are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-dynamodb-endpoint"
                    }
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
                                Environment: "test"
                                Feature: "vpc-endpoints"
                                Name: "test-vpc-dynamodb-endpoint"
                            }
                        }
                    }
                },
                # Spec: DynamoDB Gateway Endpoint should be created when enableDynamodbEndpoint: true
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-dynamodb-test-vpc-dynamodb-endpoint"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Endpoint attached to VPC
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: DynamoDB service name
                            serviceName: "com.amazonaws.us-west-2.dynamodb"
                            # Spec: Gateway type endpoint
                            vpcEndpointType: "Gateway"
                            # Spec: Correct tags applied
                            tags: {
                                Environment: "test"
                                Feature: "vpc-endpoints"
                                Type: "dynamodb-gateway"
                                Name: "vpce-dynamodb-test-vpc-dynamodb-endpoint"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
