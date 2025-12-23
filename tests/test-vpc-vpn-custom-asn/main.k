"""
VPN Gateway Custom ASN Test

Tests VPN Gateway creation with custom Amazon-side ASN:
- VPC with VPN Gateway
- Custom Amazon-side ASN (65000)
- VPN Gateway attached to VPC
- Route propagation configured

Spec: This validates custom ASN support (task 4.1) from terraform-vpc-analysis.md
Verifies that amazonSideAsn parameter is properly applied to VPN Gateway
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-vpn-custom-asn"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with VPN Gateway and custom ASN
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-vpn-asn"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    publicSubnets: ["10.0.1.0/24"]
                    privateSubnets: ["10.0.11.0/24"]
                    # Spec: Enable VPN Gateway
                    enableVpnGateway: True
                    # Spec: Specify custom Amazon-side ASN
                    amazonSideAsn: 65000
                    # Spec: Enable NAT Gateway
                    enableNatGateway: True
                    singleNatGateway: True
                    tags: {
                        Environment: "test"
                        Feature: "vpn-custom-asn"
                    }
                }
            }

            # Assert that VPN Gateway is created with custom ASN
            assertResources: [
                # Spec: VPN Gateway should be created with custom ASN
                ec2v1beta1.VPNGateway{
                    metadata: {
                        name: "vgw-test-vpc-vpn-asn"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Custom Amazon-side ASN should be 65000
                            amazonSideAsn: "65000"
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "vpn-custom-asn"
                                Name: "vgw-test-vpc-vpn-asn"
                            }
                        }
                    }
                },
                # Spec: VPN Gateway Attachment should be created
                ec2v1beta1.VPNGatewayAttachment{
                    metadata: {
                        name: "vgw-attachment-test-vpc-vpn-asn"
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
                # Spec: Route propagation to public route table
                ec2v1beta1.VPNGatewayRoutePropagation{
                    metadata: {
                        name: "vgw-prop-public-test-vpc-vpn-asn"
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
                }
            ]
        }
    }
]
items= _items
