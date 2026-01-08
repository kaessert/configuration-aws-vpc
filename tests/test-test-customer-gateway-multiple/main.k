"""
Customer Gateway Multiple Test

Tests Customer Gateway creation with multiple gateways:
- VPC with basic configuration
- Two Customer Gateways with different configurations
- One uses standard BGP ASN, one uses extended BGP ASN
- Certificate ARN specified for one gateway
- Correct tags applied independently

Spec: This validates Customer Gateway creation (task 4.2) from terraform-vpc-analysis.md
Verifies that multiple Customer Gateways can be created in one VPC
Verifies bgpAsnExtended field and certificateArn field work correctly
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-customer-gateway-multiple"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with multiple Customer Gateways
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

            # Assert that both Customer Gateway resources are created
            assertResources: [
                # Spec: First Customer Gateway with standard BGP ASN
                ec2v1beta1.CustomerGateway{
                    metadata: {
                        name: "cgw-hq-test-cgw-multi"
                    }
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
                    metadata: {
                        name: "cgw-branch-test-cgw-multi"
                    }
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
]
items= _items
