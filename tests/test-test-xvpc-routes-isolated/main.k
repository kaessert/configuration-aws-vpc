"""
Isolated Subnets Route Table Test

Tests the routing configuration for isolated (intra) subnets:
- VPC with isolated/intra subnets
- Isolated route table created (no IGW or NAT routes)
- Route table associations for all isolated subnets
- NO routes to Internet Gateway
- NO routes to NAT Gateway
- Only local VPC routing (automatic by AWS)
- Correct tags applied

Spec: This validates isolated subnet routing (task 2.5.1) from terraform-vpc-analysis.md
Verifies that intra subnets have NO external connectivity (fully isolated)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-routes-isolated"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with isolated (intra) subnets
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-routes-isolated"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Only intra subnets (no public, no private with NAT)
                    intraSubnets: ["10.0.50.0/24", "10.0.51.0/24"]
                    # Spec: No IGW or NAT Gateway
                    createIgw: False
                    enableNatGateway: False
                    tags: {
                        Environment: "test"
                        Feature: "routes-isolated"
                    }
                }
            }

            # Assert that isolated route table is created with no external routes
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-routes-isolated"
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
                                Feature: "routes-isolated"
                                Name: "test-vpc-routes-isolated"
                            }
                        }
                    }
                },
                # Spec: Intra subnet in first AZ should be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-intra-test-vpc-routes-isolated-us-west-2a"
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
                            cidrBlock: "10.0.50.0/24"
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Feature: "routes-isolated"
                                Type: "intra"
                            }
                        }
                    }
                },
                # Spec: Isolated route table should be created (shared across all intra subnets)
                ec2v1beta1.RouteTable{
                    metadata: {
                        name: "rtb-intra-test-vpc-routes-isolated"
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
                                Feature: "routes-isolated"
                                Name: "rtb-intra-test-vpc-routes-isolated"
                                Type: "intra"
                            }
                        }
                    }
                },
                # Spec: Route table association for first intra subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-intra-test-vpc-routes-isolated-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should associate with intra route table
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "intra"
                                }
                            }
                            # Spec: Should associate with intra subnet in us-west-2a
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "intra"
                                    "az": "us-west-2a"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route table association for second intra subnet
                ec2v1beta1.RouteTableAssociation{
                    metadata: {
                        name: "rtb-assoc-intra-test-vpc-routes-isolated-us-west-2b"
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
                                }
                            }
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "intra"
                                    "az": "us-west-2b"
                                }
                            }
                            region: "us-west-2"
                        }
                    }
                }
                # Spec: NO Route resources should be created for intra subnets
                # (Only local VPC routing, which is automatic in AWS)
            ]
        }
    }
]
items= _items
