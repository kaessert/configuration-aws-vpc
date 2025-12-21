"""
Private Route Tables with NAT per AZ Test

Tests the routing configuration for private subnets with one NAT Gateway per AZ:
- VPC with public and private subnets across 3 AZs
- One NAT Gateway per AZ (high availability)
- Separate private route table per AZ
- Each route table has route to its AZ's NAT Gateway (0.0.0.0/0 → NAT)
- Route table associations for each AZ's private subnets
- Correct tags applied

Spec: This validates private subnet routing with NAT per AZ (task 2.5.1) from terraform-vpc-analysis.md
Verifies high-availability setup where each AZ has its own NAT Gateway and routing
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-routes-private-per-az"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with private subnets and NAT Gateway per AZ
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-routes-private-per-az"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]  # Testing with 2 AZs for simplicity
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    # Spec: Enable NAT Gateway per AZ for high availability
                    enableNatGateway: True
                    oneNatGatewayPerAz: True
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "routes-private-per-az"
                    }
                }
            }

            # Assert that separate route tables and routes are created for each AZ
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-routes-private-per-az"
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
                                Feature: "routes-private-per-az"
                                Name: "test-vpc-routes-private-per-az"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway for first AZ should exist
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-routes-private-per-az-us-west-2a"
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
                                Feature: "routes-private-per-az"
                                Name: "nat-test-vpc-routes-private-per-az-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway for second AZ should exist
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-routes-private-per-az-us-west-2b"
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
                                Feature: "routes-private-per-az"
                                Name: "nat-test-vpc-routes-private-per-az-us-west-2b"
                            }
                        }
                    }
                },
                # Spec: Private route table for first AZ
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-private-test-vpc-routes-private-per-az-us-west-2a"
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
                                Feature: "routes-private-per-az"
                                Name: "rtb-private-test-vpc-routes-private-per-az-us-west-2a"
                                Type: "private"
                                AZ: "us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Private route table for second AZ
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-private-test-vpc-routes-private-per-az-us-west-2b"
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
                                Feature: "routes-private-per-az"
                                Name: "rtb-private-test-vpc-routes-private-per-az-us-west-2b"
                                Type: "private"
                                AZ: "us-west-2b"
                            }
                        }
                    }
                },
                # Spec: Route to NAT Gateway for first AZ
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-nat-test-vpc-routes-private-per-az-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should match route table for us-west-2a
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                    "az": "us-west-2a"
                                }
                            }
                            # Spec: Should match NAT Gateway for us-west-2a
                            natGatewayIdSelector: {
                                matchLabels: {
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route to NAT Gateway for second AZ
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-nat-test-vpc-routes-private-per-az-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should match route table for us-west-2b
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                    "az": "us-west-2b"
                                }
                            }
                            # Spec: Should match NAT Gateway for us-west-2b
                            natGatewayIdSelector: {
                                matchLabels: {
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table association for first AZ's private subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-private-test-vpc-routes-private-per-az-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with private route table for us-west-2a
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                    "az": "us-west-2a"
                                }
                            }
                            # Spec: Should associate with private subnet in us-west-2a
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "private"
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for second AZ's private subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-private-test-vpc-routes-private-per-az-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with private route table for us-west-2b
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                    "az": "us-west-2b"
                                }
                            }
                            # Spec: Should associate with private subnet in us-west-2b
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "private"
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                }
            ]
        }
    }
]
items= _items
