"""
VPC Interface Endpoint - Single Service Test

Tests Interface VPC Endpoint creation for a single AWS service (EC2):
- VPC with public and private subnets
- Single Interface endpoint (EC2) created
- Endpoint type is Interface
- Endpoint placed in private subnets via subnetConfiguration
- Private DNS enabled
- Correct tags applied

NOTE: Security groups cannot be specified (provider limitation) - endpoints use VPC default SG

Spec: This validates Interface VPC Endpoints (task 4.5) from TASKS.md
Verifies Interface endpoint creation based on terraform-aws-vpc module behavior
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-interface-endpoint-single"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with single Interface endpoint enabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-interface-single"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    # Spec: Enable Interface Endpoints with single service
                    enableInterfaceEndpoints: True
                    interfaceEndpointServices: ["ec2"]
                    # Spec: Private DNS enabled by default
                    enableInterfaceEndpointPrivateDns: True
                    createIgw: True
                    enableNatGateway: True
                    singleNatGateway: True
                    tags: {
                        Environment: "test"
                        Feature: "interface-endpoints"
                    }
                    vpcEndpointTags: {
                        Type: "interface"
                    }
                }
            }

            # Assert that VPC and Interface Endpoint are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-interface-single"
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
                                Feature: "interface-endpoints"
                                Name: "test-vpc-interface-single"
                            }
                        }
                    }
                },
                # Spec: EC2 Interface Endpoint should be created when enableInterfaceEndpoints: true
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-ec2-test-vpc-interface-single"
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
                            # Spec: EC2 service name
                            serviceName: "com.amazonaws.us-west-2.ec2"
                            # Spec: Interface type endpoint
                            vpcEndpointType: "Interface"
                            # Spec: Private DNS enabled
                            privateDnsEnabled: True
                            # Spec: Placed in private subnets via subnetConfiguration
                            subnetConfiguration: [
                                {
                                    subnetIdSelector: {
                                        matchControllerRef: True
                                        matchLabels: {
                                            "subnet-type": "private"
                                        }
                                    }
                                }
                            ]
                            # Spec: Correct tags applied
                            tags: {
                                Environment: "test"
                                Feature: "interface-endpoints"
                                Type: "interface"
                                Service: "ec2"
                                Name: "vpce-ec2-test-vpc-interface-single"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
