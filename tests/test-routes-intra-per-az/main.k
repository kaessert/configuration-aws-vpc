"""
Per-AZ Intra Route Tables Test (Task 4.7)

Tests per-AZ intra (isolated) route table configuration:
- VPC with intra subnets in 3 AZs
- THREE intra route tables (one per AZ) for enhanced isolation
- NO routes to IGW or NAT (isolated subnets)
- Each route table associated with subnets in its AZ only

Spec: Validates Task 4.7 (oneIntraRouteTablePerAz flag)
Reference: Terraform supports per-AZ intra routing for enhanced isolation
TDD Status: RED phase - Feature NOT implemented yet
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-routes-intra-per-az"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-routes-intra-per-az"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                    intraSubnets: ["10.0.51.0/24", "10.0.52.0/24", "10.0.53.0/24"]

                    # NEW FEATURE: One intra route table per AZ
                    oneIntraRouteTablePerAz: True

                    tags: {
                        Environment: "test"
                        Feature: "routes-intra-per-az"
                    }
                }
            }

            assertResources: [
                # Spec: Intra route table for us-west-2a (isolated, no external routes)
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-intra-test-routes-intra-per-az-us-west-2a"
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
                                Feature: "routes-intra-per-az"
                                Name: "rtb-intra-test-routes-intra-per-az-us-west-2a"
                                Type: "intra"
                                AZ: "us-west-2a"
                            }
                        }
                    }
                },
                # Spec: Intra route table for us-west-2b
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-intra-test-routes-intra-per-az-us-west-2b"
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
                                Feature: "routes-intra-per-az"
                                Name: "rtb-intra-test-routes-intra-per-az-us-west-2b"
                                Type: "intra"
                                AZ: "us-west-2b"
                            }
                        }
                    }
                },
                # Spec: Intra route table for us-west-2c
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-intra-test-routes-intra-per-az-us-west-2c"
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
                                Feature: "routes-intra-per-az"
                                Name: "rtb-intra-test-routes-intra-per-az-us-west-2c"
                                Type: "intra"
                                AZ: "us-west-2c"
                            }
                        }
                    }
                },
                # Spec: Route table associations (one per AZ)
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-intra-test-routes-intra-per-az-us-west-2a"
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
                                    "route-table-type": "intra"
                                    "az": "us-west-2a"
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "intra"
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
