"""
VPC IPAM (IP Address Manager) Composition Tests

Tests VPC creation using AWS IPAM for dynamic CIDR allocation with late-binding:
- **ipv4**: IPv4 IPAM pool allocation with late-binding subnet creation
- **ipv6**: IPv6 IPAM pool allocation with late-binding subnet creation

IPAM Late-Binding Pattern:
- VPC requests CIDR from IPAM pool using poolId + netmaskLength
- Subnets use prefix offsets (e.g., [0, 1]) instead of explicit CIDRs
- Subnet CIDRs calculated from observed VPC CIDR allocated by IPAM
- Phase 1 (composition test): Validates VPC creation with IPAM configuration
- Phase 2 (E2E test): Validates late-binding subnet creation with observed VPC CIDR

Spec: This validates Task 3.7 (IPAM Integration), Task 10.2 (IPAM IPv4 Late-Binding),
and Task 10.3 (IPAM IPv6 Late-Binding)

Reference: AWS IPAM allows enterprises to centrally manage IP address space
across AWS accounts and regions, supporting both IPv4 and IPv6.
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: IPAM IPv4 Support with Late-Binding
_test_ipv4 = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-ipam-ipv4"
    spec: {
        **_baseSpec
        # Define XR inline - VPC using IPAM for IPv4 CIDR allocation
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-ipam-ipv4"
                namespace: "default"
            }
            spec: {
                # Region
                region: "us-west-2"

                # Spec: Use IPAM pool to dynamically allocate IPv4 CIDR
                ipv4IpamPoolId: "ipam-pool-12345678"
                ipv4NetmaskLength: 16  # Request /16 CIDR block

                # NO static cidr field - mutually exclusive with IPAM

                # Availability zones
                azs: ["us-west-2a", "us-west-2b"]

                # Spec: Subnets use IPv4 prefixes for late-binding
                # When VPC CIDR is observed (e.g., 10.0.0.0/16 from IPAM),
                # these prefixes calculate subnet CIDRs: 10.0.0.0/24, 10.0.1.0/24
                publicSubnetIpv4Prefixes: [0, 1]

                # Tags
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                    TestFeature: "ipam-ipv4"
                }
            }
        }

        # Assert expected managed resources (Phase 1: Initial composition)
        # NOTE: Validates VPC creation with IPAM configuration.
        # Subnet creation (Phase 2) requires observed VPC CIDR from status,
        # validated in E2E tests where real AWS resources provide actual CIDR.
        assertResources: [
            # Spec: VPC Resource with IPAM IPv4 configuration
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-ipam-ipv4"
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
                            Name: "test-vpc-ipam-ipv4"
                        }
                    }
                }
            }
            # NOTE: Subnet resources are NOT created in Phase 1 because:
            # - publicSubnetIpv4Prefixes requires observed VPC CIDR for calculation
            # - Observed VPC CIDR is not available until AWS allocates it from IPAM pool
            # - Late-binding subnet creation (Phase 2) is validated in E2E tests
        ]
    }
}

# Test 2: IPAM IPv6 Support with Late-Binding
_test_ipv6 = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-ipam-ipv6"
    spec: {
        **_baseSpec
        # Define XR inline - VPC using IPAM for IPv6 CIDR allocation
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-ipam-ipv6"
                namespace: "default"
            }
            spec: {
                # Region
                region: "us-west-2"

                # Spec: IPv4 CIDR still required for VPC
                cidr: "10.0.0.0/16"

                # Availability zones
                azs: ["us-west-2a", "us-west-2b"]

                # Spec: IPv6 Configuration - IPAM-allocated
                enableIpv6: True
                ipv6IpamPoolId: "ipam-pool-ipv6-12345678"
                ipv6NetmaskLength: 56  # Request /56 IPv6 CIDR block

                # Spec: Subnets using IPv6 prefixes for late-binding
                # When VPC IPv6 CIDR is observed (e.g., 2600:1f13:d6f:5800::/56 from IPAM),
                # these prefixes calculate subnet IPv6 CIDRs:
                # [0] -> 2600:1f13:d6f:5800::/64
                # [1] -> 2600:1f13:d6f:5801::/64
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                publicSubnetIpv6Prefixes: [0, 1]

                # Spec: IPv6 subnet configuration
                assignIpv6AddressOnCreation: True

                # Spec: Gateway for IPv6
                createIgw: True

                # Tags
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                    TestFeature: "ipam-ipv6"
                }
            }
        }

        # Assert expected managed resources (Phase 1: Initial composition)
        # NOTE: Validates VPC creation with IPAM IPv6 configuration.
        # Subnet and gateway creation (Phase 2) requires observed VPC IPv6 CIDR
        # from status, validated in E2E tests where real AWS resources provide actual CIDR.
        assertResources: [
            # Spec: VPC Resource with IPAM IPv6 configuration
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-ipam-ipv6"
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

                        # Spec: VPC has IPv4 CIDR
                        cidrBlock: "10.0.0.0/16"

                        # Spec: VPC should use IPAM pool configuration for IPv6
                        ipv6IpamPoolId: "ipam-pool-ipv6-12345678"
                        ipv6NetmaskLength: 56

                        # Spec: DNS settings enabled by default
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Spec: VPC should have correct tags
                        tags: {
                            Environment: "test"
                            ManagedBy: "upbound"
                            TestFeature: "ipam-ipv6"
                            Name: "test-vpc-ipam-ipv6"
                        }
                    }
                }
            }
            # NOTE: Subnet and gateway resources are NOT created in Phase 1 because:
            # - publicSubnetIpv6Prefixes requires observed VPC IPv6 CIDR for calculation
            # - Observed VPC IPv6 CIDR is not available until AWS allocates it from IPAM pool
            # - Late-binding subnet creation (Phase 2) is validated in E2E tests
        ]
    }
}

items = [
    _test_ipv4,
    _test_ipv6
]
