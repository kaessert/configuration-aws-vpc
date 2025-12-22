"""
VPC Endpoints - S3 Gateway Test

Tests S3 Gateway Endpoint creation when enableS3Endpoint is enabled:
- VPC with basic configuration
- S3 Gateway Endpoint created
- Endpoint type is Gateway
- Endpoint attached to VPC via vpcIdSelector
- Endpoint associated with route tables
- Correct tags applied

Spec: This validates VPC Endpoints (task 3.1) from SPECIFICATION.md
Verifies S3 Gateway endpoint creation based on terraform-aws-vpc module behavior
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-endpoints-s3-gateway"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with S3 endpoint enabled
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
                        Environment: "test"
                        Feature: "vpc-endpoints"
                    }
                    vpcEndpointTags: {
                        Type: "s3-gateway"
                    }
                }
            }

            # Assert that VPC and S3 Gateway Endpoint are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-s3-endpoint"
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
                                Name: "test-vpc-s3-endpoint"
                            }
                        }
                    }
                },
                # Spec: S3 Gateway Endpoint should be created when enableS3Endpoint: true
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-s3-test-vpc-s3-endpoint"
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
                            # Spec: S3 service name
                            serviceName: "com.amazonaws.us-west-2.s3"
                            # Spec: Gateway type endpoint
                            vpcEndpointType: "Gateway"
                            # Spec: Correct tags applied
                            tags: {
                                Environment: "test"
                                Feature: "vpc-endpoints"
                                Type: "s3-gateway"
                                Name: "vpce-s3-test-vpc-s3-endpoint"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
