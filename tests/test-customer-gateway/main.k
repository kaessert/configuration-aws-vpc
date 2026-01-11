"""
Customer Gateway Composition Tests

Tests Customer Gateway creation with various configurations:
- **single**: Single Customer Gateway with standard BGP ASN
- **multiple**: Multiple Customer Gateways with different configurations (standard and extended BGP ASN, certificate ARN)

Spec: This validates Task 4.2 - Customer Gateway support

Reference: thoughts/TASKS.md Task 4.2, terraform-aws-modules/terraform-aws-vpc
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

# Test 1: Single Customer Gateway
_test_single = metav1alpha1.CompositionTest {
    metadata.name: "test-customer-gateway-single"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-cgw-single"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                # Spec: Define single Customer Gateway
                customerGateways: {
                    "main": {
                        bgpAsn: 65000
                        ipAddress: "203.0.113.12"
                        type: "ipsec.1"
                        deviceName: "main-office-router"
                        tags: {
                            Location: "headquarters"
                        }
                    }
                }
                tags: {
                    Environment: "test"
                    Feature: "customer-gateway"
                }
            }
        }
        assertResources: [
            # Spec: Customer Gateway should be created with correct configuration
            ec2v1beta1.CustomerGateway{
                metadata: { name: "cgw-main-test-cgw-single" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: BGP ASN should be set correctly
                        bgpAsn: "65000"
                        # Spec: IP address should match configuration
                        ipAddress: "203.0.113.12"
                        # Spec: Type should be ipsec.1
                        type: "ipsec.1"
                        # Spec: Device name should be set
                        deviceName: "main-office-router"
                        region: "us-west-2"
                        # Spec: Tags should be merged with common tags
                        tags: {
                            Environment: "test"
                            Feature: "customer-gateway"
                            Location: "headquarters"
                            Name: "cgw-main-test-cgw-single"
                        }
                    }
                }
            }
        ]
    }
}

# Test 2: Multiple Customer Gateways
_test_multiple = metav1alpha1.CompositionTest {
    metadata.name: "test-customer-gateway-multiple"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-cgw-multi"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                # Spec: Define multiple Customer Gateways
                customerGateways: {
                    "hq": {
                        bgpAsn: 65000
                        ipAddress: "203.0.113.12"
                        type: "ipsec.1"
                        deviceName: "hq-router"
                        tags: {
                            Location: "headquarters"
                            Priority: "high"
                        }
                    }
                    "branch": {
                        bgpAsnExtended: "4200000000"
                        ipAddress: "203.0.113.45"
                        type: "ipsec.1"
                        deviceName: "branch-router"
                        certificateArn: "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
                        tags: {
                            Location: "branch-office"
                            Priority: "medium"
                        }
                    }
                }
                tags: {
                    Environment: "test"
                    Feature: "customer-gateway-multi"
                }
            }
        }
        assertResources: [
            # Spec: First Customer Gateway with standard BGP ASN
            ec2v1beta1.CustomerGateway{
                metadata: { name: "cgw-hq-test-cgw-multi" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        bgpAsn: "65000"
                        ipAddress: "203.0.113.12"
                        type: "ipsec.1"
                        deviceName: "hq-router"
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "customer-gateway-multi"
                            Location: "headquarters"
                            Priority: "high"
                            Name: "cgw-hq-test-cgw-multi"
                        }
                    }
                }
            },
            # Spec: Second Customer Gateway with extended BGP ASN and certificate
            ec2v1beta1.CustomerGateway{
                metadata: { name: "cgw-branch-test-cgw-multi" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Extended BGP ASN should be used instead of bgpAsn
                        bgpAsnExtended: "4200000000"
                        ipAddress: "203.0.113.45"
                        type: "ipsec.1"
                        deviceName: "branch-router"
                        # Spec: Certificate ARN should be set
                        certificateArn: "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "customer-gateway-multi"
                            Location: "branch-office"
                            Priority: "medium"
                            Name: "cgw-branch-test-cgw-multi"
                        }
                    }
                }
            }
        ]
    }
}

items = [
    _test_single,
    _test_multiple
]
