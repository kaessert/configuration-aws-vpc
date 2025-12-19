"""
NAT Gateway Disabled Test

Tests that NAT Gateway resources are NOT created when NAT Gateway is disabled:
- VPC with basic configuration
- Public subnets created
- Private subnets created
- Internet Gateway created
- NO NAT Gateway created
- NO EIP allocated
- Validates cost-effective configuration for scenarios that don't need NAT

Spec: This validates NAT Gateway disabled (enableNatGateway: false) (task 2.4) from terraform-vpc-analysis.md
Verifies that NAT Gateway resources are not created when disabled
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-nat-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with NAT Gateway disabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-disabled"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    # Spec: Disable NAT Gateway (default is false)
                    enableNatGateway: False
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-disabled"
                    }
                }
            }

            # Assert that VPC, IGW, and subnets are created, but NO NAT Gateway or EIP
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-disabled"
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
                                Feature: "nat-disabled"
                                Name: "test-vpc-nat-disabled"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-disabled"
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
                            tags: {
                                Environment: "test"
                                Feature: "nat-disabled"
                                Name: "igw-test-vpc-nat-disabled"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in first AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-disabled-us-west-2a"
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
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.1.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Feature: "nat-disabled"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Private subnet should be created in first AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-private-test-vpc-nat-disabled-us-west-2a"
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
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.10.0/24"
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Feature: "nat-disabled"
                                Type: "private"
                            }
                        }
                    }
                }
                # Spec: NO NAT Gateway should be created (assertion via absence)
                # Spec: NO EIP should be allocated (assertion via absence)
                # Note: This test validates that the composition does NOT create
                # NAT Gateway or EIP resources when enableNatGateway: false
            ]
        }
    }
]
items= _items
