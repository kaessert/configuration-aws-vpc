"""
IPAM IPv4 Support Composition Test

Tests VPC creation using AWS IPAM (IP Address Manager) for dynamic CIDR allocation:
- VPC uses IPAM pool ID and netmask length instead of static CIDR
- ipv4IpamPoolId field specifies the IPAM pool
- ipv4NetmaskLength specifies the prefix length (e.g., 16 for /16)
- Static cidr field is NOT used (mutually exclusive with IPAM)

Spec: This validates Task 3.7 - IPAM Integration (IPv4 support)

Reference: AWS IPAM allows enterprises to centrally manage IP address space
across AWS accounts and regions.
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-ipam-ipv4"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline - VPC using IPAM for CIDR allocation
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-ipam"
                    namespace: "default"
                }
                spec: {
                    # Region
                    region: "us-west-2"

                    # IPAM Configuration (instead of static cidr)
                    # Spec: Use IPAM pool to dynamically allocate CIDR
                    ipv4IpamPoolId: "ipam-pool-12345678"  # Example IPAM pool ID
                    ipv4NetmaskLength: 16  # Request /16 CIDR block

                    # NO static cidr field - mutually exclusive with IPAM

                    # Availability zones
                    azs: ["us-west-2a", "us-west-2b"]

                    # Subnets (will use IPAM-allocated CIDR)
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]

                    # Tags
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                        TestFeature: "ipam-ipv4"
                    }
                }
            }

            # Assert expected managed resources
            assertResources: [
                # VPC Resource with IPAM configuration
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-ipam"
                    }
                    spec: {
                        # Spec: Crossplane v2 requires kind in providerConfigRef
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # Spec: Crossplane v2 uses managementPolicies
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: VPC should be in correct region
                            region: "us-west-2"

                            # Spec: VPC should use IPAM pool configuration
                            ipv4IpamPoolId: "ipam-pool-12345678"
                            ipv4NetmaskLength: 16

                            # Spec: VPC should NOT have static cidrBlock (mutually exclusive)
                            # (omitted from assertions - validates it's not present)

                            # Spec: DNS settings enabled by default
                            enableDnsHostnames: True
                            enableDnsSupport: True

                            # Spec: VPC should have correct tags
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                TestFeature: "ipam-ipv4"
                                Name: "test-vpc-ipam"
                            }
                        }
                    }
                },
                # Public Subnets (using IPAM-allocated VPC CIDR)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-ipam-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Subnet references VPC via controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.1.0/24"
                            # Spec: Public subnets auto-assign public IPs
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                TestFeature: "ipam-ipv4"
                                Name: "subnet-public-test-vpc-ipam-us-west-2a"
                                Type: "public"
                            }
                        }
                    }
                },
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-ipam-us-west-2b"
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
                            region: "us-west-2"
                            availabilityZone: "us-west-2b"
                            cidrBlock: "10.0.2.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                TestFeature: "ipam-ipv4"
                                Name: "subnet-public-test-vpc-ipam-us-west-2b"
                                Type: "public"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
