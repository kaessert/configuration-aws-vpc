"""
VPN Gateway Enabled Test

Tests VPN Gateway creation when enableVpnGateway is enabled:
- VPC with basic configuration
- VPN Gateway created with default Amazon-side ASN (64512)
- VPN Gateway attached to VPC via VPNGatewayAttachment
- Route propagation to public route tables (default)
- Route propagation to private route tables (default)
- Correct tags applied

Spec: This validates VPN Gateway creation (task 4.1) from terraform-vpc-analysis.md
Verifies that VPN Gateway is created when enableVpnGateway: true
Verifies default route propagation behavior (public and private only)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-vpn-enabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with VPN Gateway enabled
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-vpn"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                    # Spec: Enable VPN Gateway
                    enableVpnGateway: True
                    # Spec: Enable NAT Gateway with single NAT for testing route propagation
                    enableNatGateway: True
                    singleNatGateway: True
                    # Spec: Route propagation defaults - public and private enabled
                    # propagatePublicRouteTablesVgw: true (default)
                    # propagatePrivateRouteTablesVgw: true (default)
                    tags: {
                        Environment: "test"
                        Feature: "vpn-gateway"
                    }
                }
            }

            # Assert that VPN Gateway resources are created
            assertResources: [
                # Spec: VPN Gateway should be created when enableVpnGateway: true
                ec2v1beta1.VPNGateway{
                    metadata: {
                        name: "vgw-test-vpc-vpn"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Default Amazon-side ASN should be 64512
                            amazonSideAsn: "64512"
                            region: "us-west-2"
                            # Spec: VPN Gateway should have correct tags
                            tags: {
                                Environment: "test"
                                Feature: "vpn-gateway"
                                Name: "vgw-test-vpc-vpn"
                            }
                        }
                    }
                },
                # Spec: VPN Gateway Attachment should be created
                ec2v1beta1.VPNGatewayAttachment{
                    metadata: {
                        name: "vgw-attachment-test-vpc-vpn"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Attachment should reference VPC via selector
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            # Spec: Attachment should reference VPN Gateway via selector
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route propagation to public route table (default enabled)
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata: {
                        name: "vgw-prop-public-test-vpc-vpn"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should target public route tables via label selector
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "public"
                                }
                            }
                            # Spec: Should reference VPN Gateway via selector
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Route propagation to private route table (default enabled, single NAT = single route table)
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata: {
                        name: "vgw-prop-private-test-vpc-vpn"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Should target private route tables via label selector
                            routeTableIdSelector: {
                                matchLabels: {
                                    "route-table-type": "private"
                                }
                            }
                            # Spec: Should reference VPN Gateway via selector
                            vpnGatewayIdSelector: {
                                matchControllerRef: True
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
