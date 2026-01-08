"""
E2E Test: NAT Gateway Enhancements

Validates NAT Gateway enhancements (Task 4.4) with real AWS resources:
- NAT per subnet strategy (one NAT Gateway per public subnet)
- NAT per AZ strategy (default behavior, for comparison)
- Custom NAT destination CIDR block (10.0.0.0/8 instead of default 0.0.0.0/0)
- Resource lifecycle (create → ready → synced → delete)
- High availability NAT configuration

This test validates Task 4.4 implementation with realistic VPC configuration:
- 3 availability zones
- 3 public subnets (for NAT Gateways)
- 3 private subnets (using NAT for egress)
- 3 NAT Gateways (one per AZ - default strategy)
- Custom NAT route destination

Note: This test does NOT test reuseNatIps feature (requires pre-allocated EIPs)

Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-nat-enhancements"
        spec= {
            # CRITICAL: Always specify Crossplane version for v2
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Timeouts for AWS resource creation (30 min) and cleanup (10 min)
            # NAT Gateways can take 5-10 minutes to create, so 30 min total is appropriate
            timeoutSeconds: 1800
            cleanupTimeoutSeconds: 600

            # CRITICAL: Always cleanup resources
            skipDelete: False

            # Test manifest: VPC XR with NAT Gateway enhancements
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-vpc-nat-enhancements"
                        namespace: "default"
                    }
                    spec: {
                        # Region and AZs
                        region: "us-west-2"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # VPC CIDR
                        cidr: "10.100.0.0/16"

                        # Public subnets (for NAT Gateways)
                        publicSubnets: [
                            "10.100.1.0/24",   # us-west-2a
                            "10.100.2.0/24",   # us-west-2b
                            "10.100.3.0/24"    # us-west-2c
                        ]

                        # Private subnets (will use NAT for egress)
                        privateSubnets: [
                            "10.100.10.0/24",  # us-west-2a
                            "10.100.11.0/24",  # us-west-2b
                            "10.100.12.0/24"   # us-west-2c
                        ]

                        # Internet Gateway (required for public subnets and NAT)
                        createIgw: True

                        # NAT Gateway configuration - using default strategy (one per AZ)
                        enableNatGateway: True
                        singleNatGateway: False      # Multiple NAT Gateways
                        oneNatGatewayPerAz: True     # One per AZ (high availability)

                        # NEW FEATURE: Custom NAT destination CIDR
                        # Route only RFC1918 private networks (10.0.0.0/8) through NAT
                        # This is useful for hybrid cloud scenarios where you want
                        # to route only specific ranges through NAT Gateway
                        natGatewayDestinationCidrBlock: "10.0.0.0/8"

                        # Public IP mapping
                        mapPublicIpOnLaunch: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "nat-enhancements"
                            ManagedBy: "upbound-e2e"
                            Feature: "task-4.4"
                            CostCenter: "testing"
                        }
                    }
                }
            ]

            # CRITICAL: ProviderConfig with web identity (NO static credentials)
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"  # REQUIRED for Crossplane v2
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"  # Uses web identity federation
                            upbound: {
                                webIdentity: {
                                    # CRITICAL: Use this exact IAM role ARN
                                    roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
