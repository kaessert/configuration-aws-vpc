"""
Public Route Table Test

Tests the routing configuration for public subnets:
- VPC with basic configuration
- Public subnets in multiple AZs
- Internet Gateway created
- Single public route table created (shared across all public subnets)
- Route to Internet Gateway (0.0.0.0/0 → IGW)
- Route table associations for all public subnets
- Correct tags applied

Spec: This validates public subnet routing (task 2.5.1) from terraform-vpc-analysis.md
Verifies that public subnets have proper internet access via Internet Gateway
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-routes-public"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with public subnets requiring routing
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-routes-public"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "routes-public"
                    }
                }
            }

            # Assert that route table, route, and associations are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-routes-public"
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
                                Feature: "routes-public"
                                Name: "test-vpc-routes-public"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-routes-public"
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
                                Feature: "routes-public"
                                Name: "igw-test-vpc-routes-public"
                            }
                        }
                    }
                },
                # Spec: Public subnet in first AZ should be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-routes-public-us-west-2a"
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
                                Feature: "routes-public"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public route table should be created (shared across all public subnets)
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-public-test-vpc-routes-public"
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
                                Feature: "routes-public"
                                Name: "rtb-public-test-vpc-routes-public"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Route to Internet Gateway should be created (0.0.0.0/0 → IGW)
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-public-igw-test-vpc-routes-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Route table selector should match the public route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "public"
                                }
                            }
                            # Spec: Internet Gateway selector should match the IGW
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Default route to internet
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table association for first public subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-vpc-routes-public-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with public route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "public"
                                }
                            }
                            # Spec: Should associate with public subnet in us-west-2a
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
                # Spec: Route table association for second public subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-vpc-routes-public-us-west-2b"
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
                # Spec: Route table association for third public subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-public-test-vpc-routes-public-us-west-2c"
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
