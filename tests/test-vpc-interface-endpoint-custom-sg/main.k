"""
VPC Interface Endpoint - Minimal Configuration Test

Tests Interface VPC Endpoint with minimal configuration:
- VPC with private subnets only
- Interface endpoint (EC2) created
- Private DNS enabled
- Uses VPC default security group (provider limitation)
- Validates minimal setup works

Spec: This validates Interface VPC Endpoints (task 4.5) from TASKS.md
Verifies Interface endpoints work with minimal configuration
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-interface-endpoint-custom-sg"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with minimal configuration
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-interface-custom-sg"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    privateSubnets: ["10.0.10.0/24"]
                    # Spec: Enable Interface Endpoints
                    enableInterfaceEndpoints: True
                    interfaceEndpointServices: ["ec2"]
                    enableInterfaceEndpointPrivateDns: True
                    tags: {
                        Environment: "test"
                        Feature: "interface-endpoint-minimal"
                    }
                }
            }

            # Assert that VPC and Interface Endpoint are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-interface-custom-sg"
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
                                Feature: "interface-endpoint-minimal"
                                Name: "test-vpc-interface-custom-sg"
                            }
                        }
                    }
                },
                # Spec: EC2 Interface Endpoint with minimal configuration
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-ec2-test-vpc-interface-custom-sg"
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
                                Feature: "interface-endpoint-minimal"
                                Service: "ec2"
                                Name: "vpce-ec2-test-vpc-interface-custom-sg"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
