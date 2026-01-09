"""
VPC Interface Endpoint - No Private DNS Test

Tests Interface VPC Endpoint with private DNS disabled:
- VPC with private subnets
- Interface endpoint (EC2) created
- Private DNS explicitly disabled
- Validates privateDnsEnabled: False

Spec: This validates Interface VPC Endpoints (task 4.5) from TASKS.md
Verifies private DNS can be disabled for Interface endpoints
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-interface-endpoint-no-private-dns"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with private DNS disabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-interface-no-dns"
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
                    # Spec: Explicitly disable private DNS
                    enableInterfaceEndpointPrivateDns: False
                    tags: {
                        Environment: "test"
                        Feature: "interface-endpoint-no-dns"
                    }
                }
            }

            # Assert that VPC and Interface Endpoint are created with privateDnsEnabled: False
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-interface-no-dns"
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
                                Feature: "interface-endpoint-no-dns"
                                Name: "test-vpc-interface-no-dns"
                            }
                        }
                    }
                },
                # Spec: EC2 Interface Endpoint with privateDnsEnabled: False
                ec2v1beta1.VPCEndpoint{
                    metadata: {
                        name: "vpce-ec2-test-vpc-interface-no-dns"
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
                            # Spec: Private DNS explicitly disabled
                            privateDnsEnabled: False
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
                                Feature: "interface-endpoint-no-dns"
                                Service: "ec2"
                                Name: "vpce-ec2-test-vpc-interface-no-dns"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
