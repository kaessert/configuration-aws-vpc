"""
ElastiCache Separate Routing with NAT Test (Task 4.7)

Tests ElastiCache separate route table with NAT Gateway:
- VPC with ElastiCache subnets in 2 AZs
- NAT Gateway created for internet access
- Separate route table for ElastiCache subnets
- Route to NAT Gateway (0.0.0.0/0 → NAT) for ElastiCache subnets
- Route table associations for all ElastiCache subnets

Spec: This validates Task 4.7 requirement (createElastiCache

SubnetRouteTable + createElasticacheNatGatewayRoute)
Reference: terraform-aws-modules/terraform-aws-vpc supports separate ElastiCache routing

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
        metadata.name: "test-routes-elasticache-nat"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with ElastiCache separate routing
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-elasticache-nat"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    elasticacheSubnets: ["10.0.11.0/24", "10.0.12.0/24"]

                    # NAT Gateway for ElastiCache internet access
                    enableNatGateway: True
                    singleNatGateway: True

                    # NEW FEATURES: Separate route table for ElastiCache with NAT access
                    createElasticacheSubnetRouteTable: True
                    createElasticacheNatGatewayRoute: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-elasticache-nat"
                    }
                }
            }

            # Assert that separate ElastiCache route table with NAT route is created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-routes-elasticache-nat"
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
                                Feature: "routes-elasticache-nat"
                                Name: "test-routes-elasticache-nat"
                            }
                        }
                    }
                },
                # Spec: NAT Gateway should be created for ElastiCache internet access
                ec2v1beta1.NATGateway{
                    metadata: {
                        name: "nat-test-routes-elasticache-nat-us-west-2a"
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
                                Feature: "routes-elasticache-nat"
                                Name: "nat-test-routes-elasticache-nat-us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Separate route table for ElastiCache subnets
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-elasticache-test-routes-elasticache-nat"
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
                                Feature: "routes-elasticache-nat"
                                Name: "rtb-elasticache-test-routes-elasticache-nat"
                                Type: "elasticache"
                            }
                        }
                    }
                },
                # Spec: Route to NAT Gateway for ElastiCache subnets
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-elasticache-nat-test-routes-elasticache-nat"
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
                                    "route-table-type": "elasticache"
                                }
                            }
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
                # Spec: Route table association for ElastiCache subnet in us-west-2a
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-elasticache-test-routes-elasticache-nat-us-west-2a"
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
                                    "route-table-type": "elasticache"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "elasticache"
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for ElastiCache subnet in us-west-2b
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-elasticache-test-routes-elasticache-nat-us-west-2b"
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
                                    "route-table-type": "elasticache"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "elasticache"
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
