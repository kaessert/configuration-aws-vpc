"""
Custom DHCP Options Composition Test

Tests custom DHCP options configuration:
- VPC with custom DHCP options set
- Custom domain name configured
- Custom DNS servers configured
- Custom NTP servers configured
- Custom NetBIOS name servers configured
- NetBIOS node type configured
- VPCDHCPOptionsAssociation created to link DHCP options to VPC

Spec: This validates DHCP Options support from terraform-aws-vpc module
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-dhcp-custom"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline - VPC with custom DHCP options
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-dhcp"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]

                    # Spec: Enable custom DHCP options
                    enableDhcpOptions: True
                    # Spec: Custom domain name
                    dhcpOptionsDomainName: "example.internal"
                    # Spec: Custom DNS servers
                    dhcpOptionsDomainNameServers: ["10.0.0.2", "10.0.0.3"]
                    # Spec: Custom NTP servers
                    dhcpOptionsNtpServers: ["169.254.169.123"]
                    # Spec: Custom NetBIOS name servers
                    dhcpOptionsNetbiosNameServers: ["10.0.0.4"]
                    # Spec: NetBIOS node type (2 recommended by AWS)
                    dhcpOptionsNetbiosNodeType: 2

                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                }
            }

            # Assert that DHCP Options and Association are created
            assertResources: [
                # Spec: VPC should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-dhcp"
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
                                Name: "test-vpc-dhcp"
                            }
                        }
                    }
                },
                # Spec: VPCDHCPOptions resource with custom configuration
                ec2v1beta1.VPCDHCPOptions{
                    metadata: {
                        name: "dhcp-options-test-vpc-dhcp"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: Custom domain name for DHCP
                            domainName: "example.internal"
                            # Spec: Custom DNS servers
                            domainNameServers: ["10.0.0.2", "10.0.0.3"]
                            # Spec: Custom NTP servers
                            ntpServers: ["169.254.169.123"]
                            # Spec: Custom NetBIOS name servers
                            netbiosNameServers: ["10.0.0.4"]
                            # Spec: NetBIOS node type
                            netbiosNodeType: "2"
                            # Spec: Tags should be applied
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                Name: "test-vpc-dhcp-dhcp-options"
                            }
                        }
                    }
                },
                # Spec: VPCDHCPOptionsAssociation links DHCP options to VPC
                ec2v1beta1.VPCDHCPOptionsAssociation{
                    metadata: {
                        name: "dhcp-association-test-vpc-dhcp"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: DHCP options selected by controller ref
                            dhcpOptionsIdSelector: {
                                matchControllerRef: True
                            }
                            # Spec: VPC selected by controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
