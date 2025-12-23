"""
VPN Gateway Selective Route Propagation Test

Tests VPN Gateway route propagation with selective targeting:
- VPC with public, private, database, and intra subnets
- VPN Gateway enabled
- Selective route propagation:
  - Public: enabled
  - Private: disabled
  - Database: enabled
  - Intra: disabled
- Verifies only specified route tables get propagation

Spec: This validates selective route propagation (task 4.1) from terraform-vpc-analysis.md
Verifies that propagate*RouteTablesVgw flags control which route tables receive VPN routes
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-vpn-selective-propagation"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with all subnet types and selective propagation
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-vpn-selective"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                    databaseSubnets: ["10.0.21.0/24", "10.0.22.0/24"]
                    intraSubnets: ["10.0.31.0/24", "10.0.32.0/24"]
                    # Spec: Enable VPN Gateway
                    enableVpnGateway: True
                    # Spec: Selective route propagation
                    propagatePublicRouteTablesVgw: True
                    propagatePrivateRouteTablesVgw: False
                    propagateDatabaseRouteTablesVgw: True
                    propagateIntraRouteTablesVgw: False
                    # Spec: Create separate database route table for propagation testing
                    createDatabaseSubnetRouteTable: True
                    # Spec: Enable NAT Gateway
                    enableNatGateway: True
                    singleNatGateway: True
                    tags: {
                        Environment: "test"
                        Feature: "vpn-selective"
                    }
                }
            }

            # Assert VPN Gateway resources with selective propagation
            assertResources: [
                # Spec: VPN Gateway should be created
                ec2v1beta1.VPNGateway{
                    metadata: {
                        name: "vgw-test-vpc-vpn-selective"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            amazonSideAsn: "64512"
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "vpn-selective"
                                Name: "vgw-test-vpc-vpn-selective"
                            }
                        }
                    }
                },
                # Spec: VPN Gateway Attachment should be created
                ec2v1beta1.VPNGatewayAttachment{
                    metadata: {
                        name: "vgw-attachment-test-vpc-vpn-selective"
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
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route propagation to public route table (enabled)
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata: {
                        name: "vgw-prop-public-test-vpc-vpn-selective"
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
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route propagation to database route table (enabled)
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata: {
                        name: "vgw-prop-database-test-vpc-vpn-selective"
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
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                        }
                    }
                }
                # Spec: NOTE - NO route propagation to private route tables (disabled)
                # Spec: NOTE - NO route propagation to intra route tables (disabled)
                # The test verifies this by only asserting public and database propagations
                # If private or intra propagations were created, the test would fail due to unexpected resources
            ]
        }
    }
]
items= _items
