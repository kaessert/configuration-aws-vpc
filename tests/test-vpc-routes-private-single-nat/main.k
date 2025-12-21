"""
Private Route Table with Single NAT Test

Tests the routing configuration for private subnets with single NAT Gateway:
- VPC with public and private subnets
- Single NAT Gateway in first public subnet (cost-optimized)
- Single private route table (shared across all private subnets)
- Route to NAT Gateway (0.0.0.0/0 → NAT)
- Route table associations for all private subnets
- Correct tags applied

Spec: This validates private subnet routing with single NAT (task 2.5.1) from terraform-vpc-analysis.md
Verifies that private subnets have internet access via single NAT Gateway (cost-optimized setup)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-routes-private-single-nat"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with private subnets and single NAT Gateway
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-routes-private-single-nat"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable single NAT Gateway for cost optimization
                    enableNatGateway: True
                    singleNatGateway: True
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "routes-private-single-nat"
                    }
                }
            }

            # Assert that private route table, route to NAT, and associations are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-routes-private-single-nat"
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
                                Feature: "routes-private-single-nat"
                                Name: "test-vpc-routes-private-single-nat"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should exist (for private routing)
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-routes-private-single-nat-us-west-2a"
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
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "routes-private-single-nat"
                                Name: "nat-test-vpc-routes-private-single-nat-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Private subnet in first AZ should be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-private-test-vpc-routes-private-single-nat-us-west-2a"
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
                                Feature: "routes-private-single-nat"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Single private route table should be created (shared across all private subnets)
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-private-test-vpc-routes-private-single-nat"
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
                                Feature: "routes-private-single-nat"
                                Name: "rtb-private-test-vpc-routes-private-single-nat"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Route to NAT Gateway should be created (0.0.0.0/0 → NAT)
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-private-nat-test-vpc-routes-private-single-nat"
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
                            # Spec: NAT Gateway selector should match the single NAT Gateway
                            natGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Default route to NAT Gateway for internet access
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table association for first private subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with private route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
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
                # Spec: Route table association for second private subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "private"
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for third private subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2c"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "private"
                                    "az": "us-west-2c"
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
