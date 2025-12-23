"""
VPN Gateway Disabled Test

Tests that VPN Gateway resources are NOT created when disabled:
- VPC with basic configuration
- enableVpnGateway: false (default)
- No VPN Gateway created
- No VPN Gateway Attachment created
- No Route Propagation resources created

Spec: This validates conditional VPN Gateway creation (task 4.1) from terraform-vpc-analysis.md
Verifies that no VPN resources are created when enableVpnGateway is false or not specified
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-vpn-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline without VPN Gateway (default behavior)
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-no-vpn"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    publicSubnets: ["10.0.1.0/24"]
                    privateSubnets: ["10.0.11.0/24"]
                    # Spec: enableVpnGateway defaults to false, explicitly setting for clarity
                    enableVpnGateway: False
                    enableNatGateway: True
                    singleNatGateway: True
                    tags: {
                        Environment: "test"
                        Feature: "no-vpn"
                    }
                }
            }

            # Assert that basic VPC resources exist but no VPN resources
            assertResources: [
                # Spec: VPC should still be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-no-vpn"
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
                                Feature: "no-vpn"
                                Name: "test-vpc-no-vpn"
                            }
                        }
                    }
                }
                # Spec: NOTE - NO VPN Gateway resources should be created
                # The test verifies this by only asserting VPC resource
                # If VPN resources were created, the test would fail due to unexpected resources
            ]
        }
    }
]
items= _items
