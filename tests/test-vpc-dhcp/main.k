"""
VPC DHCP Options Composition Tests

Tests VPC DHCP Options functionality with various configurations:
- **disabled**: DHCP Options disabled (default, uses AWS default DHCP)
- **custom**: Custom DHCP Options with domain name, DNS, NTP, NetBIOS settings

Spec: This validates DHCP Options support from terraform-aws-vpc module

Reference: terraform-aws-modules/terraform-aws-vpc
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

# Test 1: DHCP Options Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-dhcp-disabled"
    spec: {
        **_baseSpec
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
                    Name: "test-vpc-no-dhcp"
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-no-dhcp" }
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
                            Name: "test-vpc-no-dhcp"
                            Environment: "test"
                            ManagedBy: "upbound"
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

# Test 2: Custom DHCP Options
_test_custom = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-dhcp-custom"
    spec: {
        **_baseSpec
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
                    Name: "test-vpc-dhcp"
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-dhcp" }
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
                            Name: "test-vpc-dhcp"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: VPCDHCPOptions resource with custom configuration
            ec2v1beta1.VPCDHCPOptions{
                metadata: { name: "dhcp-options-test-vpc-dhcp" }
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
                            Name: "test-vpc-dhcp-dhcp-options"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: VPCDHCPOptionsAssociation links DHCP options to VPC
            ec2v1beta1.VPCDHCPOptionsAssociation{
                metadata: { name: "dhcp-association-test-vpc-dhcp" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        # Spec: DHCP options selected by controller ref
                        dhcpOptionsIdSelector: { matchControllerRef: True }
                        # Spec: VPC selected by controller ref
                        vpcIdSelector: { matchControllerRef: True }
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_custom
]
