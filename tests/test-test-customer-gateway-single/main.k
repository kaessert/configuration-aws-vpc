"""
Customer Gateway Single Test

Tests Customer Gateway creation with single gateway configuration:
- VPC with basic configuration
- Single Customer Gateway with BGP ASN and IP address
- Correct tags applied
- Device name specified

Spec: This validates Customer Gateway creation (task 4.2) from terraform-vpc-analysis.md
Verifies that Customer Gateway is created with proper configuration
Verifies BGP ASN, IP address, type, device name, and tags
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-customer-gateway-single"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with Customer Gateway configuration
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

            # Assert that Customer Gateway resource is created
            assertResources: [
                # Spec: Customer Gateway should be created with correct configuration
                ec2v1beta1.CustomerGateway{
                    metadata: {
                        name: "cgw-main-test-cgw-single"
                    }
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
]
items= _items
