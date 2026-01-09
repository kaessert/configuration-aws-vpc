"""
VPC Interface Endpoints - Multiple Services Test

Tests Interface VPC Endpoint creation for multiple AWS services:
- VPC with public and private subnets
- Multiple Interface endpoints (EC2, SSM, RDS) created
- All endpoints placed in private subnets
- Private DNS enabled for all endpoints
- Correct tags applied

NOTE: Security groups cannot be specified (provider limitation) - endpoints use VPC default SG

Spec: This validates Interface VPC Endpoints (task 4.5) from TASKS.md
Verifies multiple Interface endpoints can coexist in same VPC
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-interface-endpoints-multiple"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with multiple Interface endpoints enabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-interface-multiple"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    # Spec: Enable Interface Endpoints with multiple services
                    enableInterfaceEndpoints: True
                    interfaceEndpointServices: ["ec2", "ssm", "rds"]
                    enableInterfaceEndpointPrivateDns: True
                    createIgw: True
                    enableNatGateway: True
                    singleNatGateway: True
                    tags: {
                        Environment: "test"
                        Feature: "interface-endpoints-multiple"
                    }
                }
            }

            # Assert that VPC and 3 Interface Endpoints are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-interface-multiple"
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
                                Feature: "interface-endpoints-multiple"
                                Name: "test-vpc-interface-multiple"
                            }
                        }
                    }
                },
                # Spec: EC2 Interface Endpoint
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-ec2-test-vpc-interface-multiple"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            serviceName: "com.amazonaws.us-west-2.ec2"
                            vpcEndpointType: "Interface"
                            privateDnsEnabled: True
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
                            tags: {
                                Environment: "test"
                                Feature: "interface-endpoints-multiple"
                                Service: "ec2"
                                Name: "vpce-ec2-test-vpc-interface-multiple"
                            }
                        }
                    }
                },
                # Spec: SSM Interface Endpoint
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-ssm-test-vpc-interface-multiple"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: SSM service name
                            serviceName: "com.amazonaws.us-west-2.ssm"
                            vpcEndpointType: "Interface"
                            privateDnsEnabled: True
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
                            tags: {
                                Environment: "test"
                                Feature: "interface-endpoints-multiple"
                                Service: "ssm"
                                Name: "vpce-ssm-test-vpc-interface-multiple"
                            }
                        }
                    }
                },
                # Spec: RDS Interface Endpoint
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-rds-test-vpc-interface-multiple"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: RDS service name
                            serviceName: "com.amazonaws.us-west-2.rds"
                            vpcEndpointType: "Interface"
                            privateDnsEnabled: True
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
                            tags: {
                                Environment: "test"
                                Feature: "interface-endpoints-multiple"
                                Service: "rds"
                                Name: "vpce-rds-test-vpc-interface-multiple"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
