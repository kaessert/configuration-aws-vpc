"""
Redshift Separate Routing with NAT Test (Task 4.7)

Tests Redshift separate route table with NAT Gateway:
- VPC with Redshift subnets
- NAT Gateway for internet access
- Separate route table for Redshift subnets
- Route to NAT Gateway for Redshift subnets

Spec: Validates Task 4.7 (createRedshiftSubnetRouteTable + createRedshiftNatGatewayRoute)
TDD Status: RED phase - Feature NOT implemented yet
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-routes-redshift-nat"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-redshift-nat"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    redshiftSubnets: ["10.0.21.0/24", "10.0.22.0/24"]
                    enableNatGateway: True
                    singleNatGateway: True

                    # NEW FEATURES
                    createRedshiftSubnetRouteTable: True
                    createRedshiftNatGatewayRoute: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-redshift-nat"
                    }
                }
            }

            assertResources: [
                # Spec: Separate route table for Redshift subnets
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-redshift-test-routes-redshift-nat"
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
                                Feature: "routes-redshift-nat"
                                Name: "rtb-redshift-test-routes-redshift-nat"
                                Type: "redshift"
                            }
                        }
                    }
                },
                # Spec: Route to NAT Gateway for Redshift subnets
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-redshift-nat-test-routes-redshift-nat"
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
                                    "route-table-type": "redshift"
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
                # Spec: Route table associations for Redshift subnets
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-redshift-test-routes-redshift-nat-us-west-2a"
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
                                    "route-table-type": "redshift"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "redshift"
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
