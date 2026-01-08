"""
NAT Gateway Per Subnet Test

Tests the NAT Gateway creation with one NAT per subnet strategy:
- VPC with basic configuration
- Public subnets in multiple AZs
- Private subnets in multiple AZs
- Internet Gateway created
- One NAT Gateway per public subnet (maximum availability)
- One EIP allocated per NAT Gateway
- Each NAT Gateway placed in its corresponding public subnet
- Correct tags applied to NAT Gateways and EIPs

Spec: This validates NAT Gateway with oneNatGatewayPerSubnet: true (task 4.4) from TASKS.md
Verifies maximum availability NAT Gateway strategy where each public subnet gets its own NAT Gateway
This is the Terraform module's default behavior when neither singleNatGateway nor oneNatGatewayPerAz is set
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nat-per-subnet"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with NAT per subnet strategy
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-per-subnet"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable NAT Gateway with one NAT per subnet strategy for maximum availability
                    enableNatGateway: True
                    oneNatGatewayPerSubnet: True
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-per-subnet"
                    }
                }
            }

            # Assert that VPC, IGW, 3 NAT Gateways, and 3 EIPs are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-per-subnet"
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
                                Feature: "nat-per-subnet"
                                Name: "test-vpc-nat-per-subnet"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-per-subnet"
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
                                Feature: "nat-per-subnet"
                                Name: "igw-test-vpc-nat-per-subnet"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in first AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-subnet-us-west-2a"
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
                                Feature: "nat-per-subnet"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in second AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-subnet-us-west-2b"
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
                            availabilityZone: "us-west-2b"
                            cidrBlock: "10.0.2.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-subnet"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in third AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-subnet-us-west-2c"
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
                            availabilityZone: "us-west-2c"
                            cidrBlock: "10.0.3.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-subnet"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: EIP should be allocated for first NAT Gateway
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-subnet-0"
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
                                Feature: "nat-per-subnet"
                                Name: "eip-nat-test-vpc-nat-per-subnet-0"
                            }
                        }
                    }
                },
                # Spec: EIP should be allocated for second NAT Gateway
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-subnet-1"
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
                                Feature: "nat-per-subnet"
                                Name: "eip-nat-test-vpc-nat-per-subnet-1"
                            }
                        }
                    }
                },
                # Spec: EIP should be allocated for third NAT Gateway
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-subnet-2"
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
                                Feature: "nat-per-subnet"
                                Name: "eip-nat-test-vpc-nat-per-subnet-2"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in first public subnet
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-subnet-0"
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
                                    "subnet-index": "0"
                                }
                            }
                            # Spec: NAT Gateway should use its allocated EIP
                            allocationIdSelector: {
                                matchLabels: {
                                    "eip-index": "0"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-subnet"
                                Name: "nat-test-vpc-nat-per-subnet-0"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in second public subnet
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-subnet-1"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: NAT Gateway should be placed in second public subnet
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "subnet-index": "1"
                                }
                            }
                            # Spec: NAT Gateway should use its allocated EIP
                            allocationIdSelector: {
                                matchLabels: {
                                    "eip-index": "1"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-subnet"
                                Name: "nat-test-vpc-nat-per-subnet-1"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in third public subnet
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-subnet-2"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: NAT Gateway should be placed in third public subnet
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "subnet-index": "2"
                                }
                            }
                            # Spec: NAT Gateway should use its allocated EIP
                            allocationIdSelector: {
                                matchLabels: {
                                    "eip-index": "2"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-subnet"
                                Name: "nat-test-vpc-nat-per-subnet-2"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
