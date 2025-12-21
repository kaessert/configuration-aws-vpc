"""
Single NAT Gateway Test

Tests the NAT Gateway creation with single NAT Gateway strategy:
- VPC with basic configuration
- Public subnets in multiple AZs
- Private subnets in multiple AZs
- Internet Gateway created
- Single NAT Gateway created (cost-optimized)
- Single EIP allocated for NAT Gateway
- NAT Gateway placed in first public subnet
- Correct tags applied to NAT Gateway and EIP

Spec: This validates NAT Gateway with singleNatGateway: true (task 2.4) from terraform-vpc-analysis.md
Verifies cost-optimized single NAT Gateway strategy where all AZs share one NAT Gateway
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nat-single"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with single NAT Gateway strategy
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-single"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable NAT Gateway with single NAT strategy for cost optimization
                    enableNatGateway: True
                    singleNatGateway: True
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-single"
                    }
                }
            }

            # Assert that VPC, IGW, single NAT Gateway, and single EIP are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-single"
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
                                Feature: "nat-single"
                                Name: "test-vpc-nat-single"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-single"
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
                                Feature: "nat-single"
                                Name: "igw-test-vpc-nat-single"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in first AZ (where NAT will be placed)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-single-us-west-2a"
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
                                Feature: "nat-single"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Private subnet should be created in first AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-private-test-vpc-nat-single-us-west-2a"
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
                                Feature: "nat-single"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Single EIP should be allocated for the NAT Gateway
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-single-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: EIP should be vpc-scoped
                            domain: "vpc"
                            tags: {
                                Environment: "test"
                                Feature: "nat-single"
                                Name: "eip-nat-test-vpc-nat-single-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Single NAT Gateway should be created in first public subnet
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-single-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: NAT Gateway should be placed in first public subnet
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2a"
                                }
                            }
                            # Spec: NAT Gateway should use the allocated EIP
                            allocationIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-single"
                                Name: "nat-test-vpc-nat-single-us-west-2a"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
