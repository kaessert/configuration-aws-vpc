"""
NAT Gateway Per AZ Test

Tests the NAT Gateway creation with one NAT Gateway per AZ strategy:
- VPC with basic configuration
- Public subnets in multiple AZs
- Private subnets in multiple AZs
- Internet Gateway created
- One NAT Gateway per AZ (high availability)
- One EIP allocated per NAT Gateway
- NAT Gateways distributed across all public subnets
- Correct tags applied to NAT Gateways and EIPs

Spec: This validates NAT Gateway with oneNatGatewayPerAz: true (task 2.4) from terraform-vpc-analysis.md
Verifies high-availability NAT Gateway strategy where each AZ gets its own NAT Gateway
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nat-per-az"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with NAT Gateway per AZ strategy
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-per-az"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable NAT Gateway with one NAT per AZ for high availability
                    enableNatGateway: True
                    oneNatGatewayPerAz: True
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-per-az"
                    }
                }
            }

            # Assert that VPC, IGW, NAT Gateways per AZ, and EIPs per AZ are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-per-az"
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
                                Feature: "nat-per-az"
                                Name: "test-vpc-nat-per-az"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-per-az"
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
                                Feature: "nat-per-az"
                                Name: "igw-test-vpc-nat-per-az"
                            }
                        }
                    }
                },
                # Spec: Public subnet in us-west-2a
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-az-us-west-2a"
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
                                Feature: "nat-per-az"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet in us-west-2b
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-az-us-west-2b"
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
                                Feature: "nat-per-az"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet in us-west-2c
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-per-az-us-west-2c"
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
                                Feature: "nat-per-az"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: EIP for NAT Gateway in us-west-2a
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-az-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            domain: "vpc"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2a"
                                Name: "eip-nat-test-vpc-nat-per-az-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: EIP for NAT Gateway in us-west-2b
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-az-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            domain: "vpc"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2b"
                                Name: "eip-nat-test-vpc-nat-per-az-us-west-2b"
                            }
                        }
                    }
                },
                # Spec: EIP for NAT Gateway in us-west-2c
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-per-az-us-west-2c"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            domain: "vpc"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2c"
                                Name: "eip-nat-test-vpc-nat-per-az-us-west-2c"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway in us-west-2a
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-az-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2a"
                                }
                            }
                            allocationIdSelector: {
                                matchLabels: {
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2a"
                                Name: "nat-test-vpc-nat-per-az-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway in us-west-2b
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-az-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2b"
                                }
                            }
                            allocationIdSelector: {
                                matchLabels: {
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2b"
                                Name: "nat-test-vpc-nat-per-az-us-west-2b"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway in us-west-2c
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-per-az-us-west-2c"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2c"
                                }
                            }
                            allocationIdSelector: {
                                matchLabels: {
                                    "az": "us-west-2c"
                                }
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-per-az"
                                AZ: "us-west-2c"
                                Name: "nat-test-vpc-nat-per-az-us-west-2c"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
