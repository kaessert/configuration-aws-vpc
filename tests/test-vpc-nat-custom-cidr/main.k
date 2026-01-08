"""
NAT Gateway with Custom Destination CIDR Test

Tests the NAT Gateway routes with custom destination CIDR block:
- VPC with basic configuration
- Public subnets in multiple AZs
- Private subnets in multiple AZs
- Internet Gateway created
- NAT Gateway created (single NAT for simplicity)
- EIP allocated for NAT Gateway
- Private route table with custom destination CIDR (10.0.0.0/8) instead of default 0.0.0.0/0
- Correct tags applied

Spec: This validates NAT Gateway with natGatewayDestinationCidrBlock custom value (task 4.4) from TASKS.md
Verifies ability to route only specific CIDR ranges through NAT Gateway
This is important for non-standard routing scenarios (e.g., route only private RFC1918 ranges through NAT)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nat-custom-cidr"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with custom NAT destination CIDR
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nat-custom-cidr"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    # Spec: Enable NAT Gateway with single NAT for simplicity
                    enableNatGateway: True
                    singleNatGateway: True
                    # Spec: Custom destination CIDR for NAT routes (10.0.0.0/8 instead of default 0.0.0.0/0)
                    natGatewayDestinationCidrBlock: "10.0.0.0/8"
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "nat-custom-cidr"
                    }
                }
            }

            # Assert that VPC, IGW, NAT, EIP, and routes with custom CIDR are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nat-custom-cidr"
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
                                Feature: "nat-custom-cidr"
                                Name: "test-vpc-nat-custom-cidr"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-nat-custom-cidr"
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
                                Feature: "nat-custom-cidr"
                                Name: "igw-test-vpc-nat-custom-cidr"
                            }
                        }
                    }
                },
                # Spec: EIP should be allocated for NAT Gateway
                ec2v1beta1.EIP{
                    metadata: {
                        name: "eip-nat-test-vpc-nat-custom-cidr-us-west-2a"
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
                                Feature: "nat-custom-cidr"
                                Name: "eip-nat-test-vpc-nat-custom-cidr-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-nat-custom-cidr-us-west-2a"
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
                                Feature: "nat-custom-cidr"
                                Name: "nat-test-vpc-nat-custom-cidr-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Private route table should be created
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-private-test-vpc-nat-custom-cidr"
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
                                Feature: "nat-custom-cidr"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Private route should use custom destination CIDR (10.0.0.0/8) instead of 0.0.0.0/0
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-nat-test-vpc-nat-custom-cidr"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Route table selector should match the private route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                            }
                            # Spec: NAT Gateway selector should match the NAT Gateway
                            natGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            # Spec: CRITICAL - Destination should be 10.0.0.0/8 (NOT default 0.0.0.0/0)
                            destinationCidrBlock: "10.0.0.0/8"
                            region: "us-west-2"
                        }
                    }
                }
            ]
        }
    }
]
items= _items