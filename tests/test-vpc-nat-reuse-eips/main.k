"""
NAT Gateway with Reuse EIPs Test

Tests the NAT Gateway creation with external EIP allocation IDs:
- VPC with basic configuration
- Public subnets in multiple AZs
- Private subnets in multiple AZs
- Internet Gateway created
- NAT Gateways created (one per AZ)
- NO new EIPs allocated (reuseNatIps: true)
- NAT Gateways use provided external EIP allocation IDs
- Correct tags applied to NAT Gateways

Spec: This validates NAT Gateway with reuseNatIps: true and externalNatIpIds (task 4.4) from TASKS.md
Verifies ability to use pre-allocated EIP allocation IDs instead of creating new ones
This is important for organizations with reserved/whitelisted IP addresses
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nat-reuse-eips"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with external EIP reuse
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-reuse-eips"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable NAT Gateway with NAT per AZ
                    enableNatGateway: True
                    oneNatGatewayPerAz: True
                    # Spec: Reuse existing EIPs instead of creating new ones
                    reuseNatIps: True
                    externalNatIpIds: ["eipalloc-12345678", "eipalloc-87654321", "eipalloc-abcdef12"]
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-reuse-eips"
                    }
                }
            }

            # Assert that VPC, IGW, 3 NAT Gateways are created (but NO EIPs)
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-reuse-eips"
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
                                Feature: "nat-reuse-eips"
                                Name: "test-vpc-nat-reuse-eips"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-reuse-eips"
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
                                Feature: "nat-reuse-eips"
                                Name: "igw-test-vpc-nat-reuse-eips"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in first AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2a"
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
                                Feature: "nat-reuse-eips"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in second AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2b"
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
                                Feature: "nat-reuse-eips"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet should be created in third AZ
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2c"
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
                                Feature: "nat-reuse-eips"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in first AZ with external EIP
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-reuse-eips-us-west-2a"
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
                            # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                            allocationId: "eipalloc-12345678"
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-reuse-eips"
                                Name: "nat-test-vpc-nat-reuse-eips-us-west-2a"
                                AZ: "us-west-2a"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in second AZ with external EIP
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-reuse-eips-us-west-2b"
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
                                    "az": "us-west-2b"
                                }
                            }
                            # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                            allocationId: "eipalloc-87654321"
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-reuse-eips"
                                Name: "nat-test-vpc-nat-reuse-eips-us-west-2b"
                                AZ: "us-west-2b"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created in third AZ with external EIP
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-reuse-eips-us-west-2c"
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
                                    "az": "us-west-2c"
                                }
                            }
                            # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                            allocationId: "eipalloc-abcdef12"
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "nat-reuse-eips"
                                Name: "nat-test-vpc-nat-reuse-eips-us-west-2c"
                                AZ: "us-west-2c"
                            }
                        }
                    }
                }
                # NOTE: NO EIP resources should be created when reuseNatIps: true
            ]
        }
    }
]
items= _items