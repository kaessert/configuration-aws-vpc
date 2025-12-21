"""
Database Subnets with NAT Route Table Test

Tests the routing configuration for database subnets with NAT Gateway access:
- VPC with database subnets
- NAT Gateway for internet access
- Separate database route table (createDatabaseSubnetRouteTable: true)
- Route to NAT Gateway (createDatabaseNatGatewayRoute: true)
- Route table associations for all database subnets
- Correct tags applied

Spec: This validates database subnet routing with NAT access (task 2.5.1) from terraform-vpc-analysis.md
Verifies that database subnets can optionally have internet access via NAT Gateway
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-routes-database-nat"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with database subnets and NAT Gateway access
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-routes-database-nat"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    databaseSubnets: ["10.0.20.0/24", "10.0.21.0/24"]
                    # Spec: Enable NAT Gateway for database subnet internet access
                    enableNatGateway: True
                    singleNatGateway: True
                    createIgw: True
                    # Spec: Create separate route table for database subnets
                    createDatabaseSubnetRouteTable: True
                    # Spec: Add route to NAT Gateway for database subnets
                    createDatabaseNatGatewayRoute: True
                    tags: {
                        Environment: "test"
                        Feature: "routes-database-nat"
                    }
                }
            }

            # Assert that database route table with NAT route is created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-routes-database-nat"
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
                                Feature: "routes-database-nat"
                                Name: "test-vpc-routes-database-nat"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should exist (for database routing)
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-vpc-routes-database-nat-us-west-2a"
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
                                Feature: "routes-database-nat"
                                Name: "nat-test-vpc-routes-database-nat-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Database subnet in first AZ should be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-database-test-vpc-routes-database-nat-us-west-2a"
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
                            cidrBlock: "10.0.20.0/24"
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Feature: "routes-database-nat"
                                Type: "database"
                            }
                        }
                    }
                },
                # Spec: Separate database route table should be created
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-database-test-vpc-routes-database-nat"
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
                                Feature: "routes-database-nat"
                                Name: "rtb-database-test-vpc-routes-database-nat"
                                Type: "database"
                            }
                        }
                    }
                },
                # Spec: Route to NAT Gateway should be created for database subnets
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-database-nat-test-vpc-routes-database-nat"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Route table selector should match the database route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "database"
                                }
                            }
                            # Spec: NAT Gateway selector should match the NAT Gateway
                            natGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Default route to NAT Gateway for internet access
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table association for first database subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-database-test-vpc-routes-database-nat-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with database route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "database"
                                }
                            }
                            # Spec: Should associate with database subnet in us-west-2a
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "database"
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for second database subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-database-test-vpc-routes-database-nat-us-west-2b"
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
                                    "route-table-type": "database"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "database"
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
