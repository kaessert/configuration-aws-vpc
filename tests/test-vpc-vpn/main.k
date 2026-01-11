"""
VPN Gateway Composition Tests

Tests VPN Gateway functionality with various configurations:
- **disabled**: VPN Gateway disabled (default)
- **enabled**: VPN Gateway enabled with default ASN (64512)
- **custom-asn**: VPN Gateway with custom Amazon-side ASN (65000)
- **selective-propagation**: VPN Gateway with selective route table propagation

Spec: This validates Task 4.6 - VPN Gateway support implementation

Reference: thoughts/TASKS.md Task 4.6, terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: VPN Gateway Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-vpn-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpn-disabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                # Spec: VPN Gateway disabled by default
                enableVpnGateway: False
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Name: "test-vpn-disabled"
                    TestType: "vpn-disabled"
                }
            }
        }
        assertResources: [
            # Spec: VPC created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpn-disabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                    }
                }
            }
            # Spec: No VPN Gateway resources (VPNGateway, VPNGatewayAttachment, VPNGatewayRoutePropagation)
            # should be created when enableVpnGateway: False
        ]
    }
}

# Test 2: VPN Gateway Enabled with Default ASN
_test_enabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-vpn-enabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpn-enabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                # Spec: VPN Gateway enabled with default settings
                enableVpnGateway: True
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Name: "test-vpn-enabled"
                    TestType: "vpn-enabled"
                }
            }
        }
        assertResources: [
            # Spec: VPN Gateway created with default Amazon-side ASN (64512)
            ec2v1beta1.VPNGateway{
                metadata: { name: "vgw-test-vpn-enabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        amazonSideAsn: "64512"
                        tags: {
                            Name: "vgw-test-vpn-enabled"
                            TestType: "vpn-enabled"
                        }
                    }
                }
            },
            # Spec: VPN Gateway Attachment to VPC
            ec2v1beta1.VPNGatewayAttachment{
                metadata: { name: "vgw-attachment-test-vpn-enabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for public route table
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-public-test-vpn-enabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for private route table
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-private-test-vpn-enabled" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

# Test 3: VPN Gateway with Custom Amazon-Side ASN
_test_custom_asn = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-vpn-custom-asn"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpn-custom-asn"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                # Spec: VPN Gateway with custom Amazon-side ASN
                enableVpnGateway: True
                amazonSideAsn: 65000
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Name: "test-vpn-custom-asn"
                    TestType: "vpn-custom-asn"
                }
            }
        }
        assertResources: [
            # Spec: VPN Gateway created with custom Amazon-side ASN (65000)
            ec2v1beta1.VPNGateway{
                metadata: { name: "vgw-test-vpn-custom-asn" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        amazonSideAsn: "65000"
                        tags: {
                            Name: "vgw-test-vpn-custom-asn"
                            TestType: "vpn-custom-asn"
                        }
                    }
                }
            },
            # Spec: VPN Gateway Attachment to VPC
            ec2v1beta1.VPNGatewayAttachment{
                metadata: { name: "vgw-attachment-test-vpn-custom-asn" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for public route table
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-public-test-vpn-custom-asn" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for private route table
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-private-test-vpn-custom-asn" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

# Test 4: VPN Gateway with Selective Route Table Propagation
_test_selective_propagation = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-vpn-selective-propagation"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpn-selective"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                databaseSubnets: ["10.0.101.0/24", "10.0.102.0/24"]
                intraSubnets: ["10.0.201.0/24", "10.0.202.0/24"]
                # Spec: VPN Gateway with selective route table propagation
                enableVpnGateway: True
                propagatePublicRouteTablesVgw: True
                propagatePrivateRouteTablesVgw: False
                propagateDatabaseRouteTablesVgw: True
                propagateIntraRouteTablesVgw: False
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                createDatabaseSubnetRouteTable: True
                tags: {
                    Name: "test-vpn-selective"
                    TestType: "vpn-selective-propagation"
                }
            }
        }
        assertResources: [
            # Spec: VPN Gateway created
            ec2v1beta1.VPNGateway{
                metadata: { name: "vgw-test-vpn-selective" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        amazonSideAsn: "64512"
                        tags: {
                            Name: "vgw-test-vpn-selective"
                            TestType: "vpn-selective-propagation"
                        }
                    }
                }
            },
            # Spec: VPN Gateway Attachment to VPC
            ec2v1beta1.VPNGatewayAttachment{
                metadata: { name: "vgw-attachment-test-vpn-selective" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for public route table (enabled)
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-public-test-vpn-selective" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: VPN Gateway Route Propagation for database route table (enabled)
            ec2v1beta1.VPNGatewayRoutePropagation{
                metadata: { name: "vgw-prop-database-test-vpn-selective" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "database" }
                        }
                        vpnGatewayIdSelector: { matchControllerRef: True }
                    }
                }
            }
            # Spec: No VPN Gateway Route Propagation for private or intra route tables
            # (propagatePrivateRouteTablesVgw: False, propagateIntraRouteTablesVgw: False)
        ]
    }
}

items = [
    _test_disabled,
    _test_enabled,
    _test_custom_asn,
    _test_selective_propagation
]
