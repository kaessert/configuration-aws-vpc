"""
Default DHCP Options Composition Test

Tests VPC without custom DHCP options:
- VPC created without custom DHCP options
- NO VPCDHCPOptions resource created
- NO VPCDHCPOptionsAssociation resource created
- VPC uses AWS default DHCP options

Spec: This validates that DHCP options are optional (terraform-aws-vpc default behavior)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-dhcp-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline - VPC without custom DHCP options
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-no-dhcp"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    # Spec: enableDhcpOptions not set (defaults to false)
                    # No DHCP option fields configured

                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                }
            }

            # Assert that only VPC is created (no DHCP resources)
            assertResources: [
                # Spec: VPC should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-no-dhcp"
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
                                ManagedBy: "upbound"
                                Name: "test-vpc-no-dhcp"
                            }
                        }
                    }
                }
                # Spec: NO VPCDHCPOptions resource should be created
                # Spec: NO VPCDHCPOptionsAssociation resource should be created
                # (AWS uses default DHCP options)
            ]
        }
    }
]
items= _items
