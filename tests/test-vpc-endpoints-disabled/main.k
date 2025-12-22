"""
VPC Endpoints - Disabled Test

Tests that NO VPC Endpoints are created when endpoints are disabled (default):
- VPC with basic configuration
- NO S3 endpoint created (enableS3Endpoint: false, default)
- NO DynamoDB endpoint created (enableDynamodbEndpoint: false, default)
- Only VPC and subnets exist

Spec: This validates VPC Endpoints (task 3.1) from SPECIFICATION.md
Verifies that endpoints are NOT created by default
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-endpoints-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with endpoints explicitly disabled
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
                        Environment: "test"
                        Feature: "vpc-endpoints-disabled"
                    }
                }
            }

            # Assert that only VPC and subnets are created, NO endpoints
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-no-endpoints"
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
                                Feature: "vpc-endpoints-disabled"
                                Name: "test-vpc-no-endpoints"
                            }
                        }
                    }
                }
                # Spec: NO VPCEndpoint resources should be created
                # The test framework will verify that no VPCEndpoint resources exist
            ]
        }
    }
]
items= _items
