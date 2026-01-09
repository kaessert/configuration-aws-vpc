"""
Database IGW Route Test (Task 4.7)

Tests database subnet routing via Internet Gateway:
- VPC with database subnets
- Internet Gateway for public database access (WARNING: security risk)
- Separate route table for database subnets
- Route to IGW (0.0.0.0/0 → IGW) for public database access

Spec: Validates Task 4.7 (createDatabaseInternetGatewayRoute flag)
Reference: Terraform supports public database access (not recommended for production)
WARNING: This creates publicly accessible database subnets - use with caution
TDD Status: RED phase - Feature NOT implemented yet
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-routes-database-igw"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-database-igw"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    databaseSubnets: ["10.0.31.0/24", "10.0.32.0/24"]
                    createIgw: True

                    # NEW FEATURES: Database IGW route (public database access - security risk!)
                    createDatabaseSubnetRouteTable: True
                    createDatabaseInternetGatewayRoute: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-database-igw"
                        Warning: "public-database-access"
                    }
                }
            }

            assertResources: [
                # Spec: IGW should be created
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-routes-database-igw"
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
                                Feature: "routes-database-igw"
                                Name: "igw-test-routes-database-igw"
                            }
                        }
                    }
                },
                # Spec: Separate route table for database subnets
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-database-test-routes-database-igw"
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
                                Feature: "routes-database-igw"
                                Name: "rtb-database-test-routes-database-igw"
                                Type: "database"
                            }
                        }
                    }
                },
                # Spec: Route to IGW for database subnets (WARNING: public access)
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-database-igw-test-routes-database-igw"
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
                            gatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            destinationCidrBlock: "0.0.0.0/0"
                        }
                    }
                },
                # Spec: Route table associations for database subnets
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-database-test-routes-database-igw-us-west-2a"
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
                                    "az": "us-west-2a"
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
