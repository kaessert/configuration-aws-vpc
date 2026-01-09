"""
Per-AZ Public Route Tables Test (Task 4.7)

Tests per-AZ public route table configuration:
- VPC with public subnets in 3 AZs
- Internet Gateway created
- THREE public route tables (one per AZ) instead of shared
- Each route table routes to IGW (0.0.0.0/0 → IGW)
- Each route table associated with subnets in its AZ only
- Correct labels and tags applied per AZ

Spec: This validates Task 4.7 requirement (onePublicRouteTablePerAz flag)
Reference: terraform-aws-modules/terraform-aws-vpc supports per-AZ public routing

TDD Status: RED phase - Feature NOT implemented yet
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-routes-public-per-az"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with onePublicRouteTablePerAz enabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-public-per-az"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    createIgw: True

                    # NEW FEATURE: One public route table per AZ
                    onePublicRouteTablePerAz: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-public-per-az"
                    }
                }
            }

            # Assert that 3 route tables (one per AZ) are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-routes-public-per-az"
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
                                Feature: "routes-public-per-az"
                                Name: "test-routes-public-per-az"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-routes-public-per-az"
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
                                Feature: "routes-public-per-az"
                                Name: "igw-test-routes-public-per-az"
                            }
                        }
                    }
                },
                # Spec: Public route table for us-west-2a
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-public-test-routes-public-per-az-us-west-2a"
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
                                Feature: "routes-public-per-az"
                                Name: "rtb-public-test-routes-public-per-az-us-west-2a"
                                Type: "public"
                                AZ: "us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Public route table for us-west-2b
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-public-test-routes-public-per-az-us-west-2b"
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
                                Feature: "routes-public-per-az"
                                Name: "rtb-public-test-routes-public-per-az-us-west-2b"
                                Type: "public"
                                AZ: "us-west-2b"
                            }
                        }
                    }
                },
                # Spec: Public route table for us-west-2c
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-public-test-routes-public-per-az-us-west-2c"
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
                                Feature: "routes-public-per-az"
                                Name: "rtb-public-test-routes-public-per-az-us-west-2c"
                                Type: "public"
                                AZ: "us-west-2c"
                            }
                        }
                    }
                },
                # Spec: Route to IGW for us-west-2a route table
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-igw-test-routes-public-per-az-us-west-2a"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2a"
                                }
                            }
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route to IGW for us-west-2b route table
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-igw-test-routes-public-per-az-us-west-2b"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2b"
                                }
                            }
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route to IGW for us-west-2c route table
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-igw-test-routes-public-per-az-us-west-2c"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2c"
                                }
                            }
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table association for public subnet in us-west-2a
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-routes-public-per-az-us-west-2a"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2a"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for public subnet in us-west-2b
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-routes-public-per-az-us-west-2b"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2b"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for public subnet in us-west-2c
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-routes-public-per-az-us-west-2c"
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
                                    "route-table-type": "public"
                                    "az": "us-west-2c"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "public"
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
