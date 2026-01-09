"""
Redshift Public Routing Test (Task 4.7)

Tests Redshift public subnet routing via IGW:
- VPC with Redshift subnets
- Internet Gateway for public access
- Separate public route table for Redshift subnets
- Route to IGW (0.0.0.0/0 → IGW) for public Redshift access

Spec: Validates Task 4.7 (createRedshiftPublicSubnetRouteTable + enablePublicRedshift)
Reference: Terraform supports public Redshift clusters
TDD Status: RED phase - Feature NOT implemented yet
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-routes-redshift-public"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-redshift-public"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    redshiftSubnets: ["10.0.21.0/24", "10.0.22.0/24"]
                    createIgw: True

                    # NEW FEATURES: Public Redshift routing
                    createRedshiftPublicSubnetRouteTable: True
                    enablePublicRedshift: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-redshift-public"
                    }
                }
            }

            assertResources: [
                # Spec: IGW should be created for public access
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-routes-redshift-public"
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
                                Feature: "routes-redshift-public"
                                Name: "igw-test-routes-redshift-public"
                            }
                        }
                    }
                },
                # Spec: Separate public route table for Redshift subnets
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-redshift-public-test-routes-redshift-public"
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
                                Feature: "routes-redshift-public"
                                Name: "rtb-redshift-public-test-routes-redshift-public"
                                Type: "redshift-public"
                            }
                        }
                    }
                },
                # Spec: Route to IGW for public Redshift access
                ec2v1beta1.Route{
                    metadata: {
                        name: "route-redshift-public-igw-test-routes-redshift-public"
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
                                    "route-table-type": "redshift-public"
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
                # Spec: Route table associations for Redshift subnets
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-redshift-public-test-routes-redshift-public-us-west-2a"
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
                                    "route-table-type": "redshift-public"
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
