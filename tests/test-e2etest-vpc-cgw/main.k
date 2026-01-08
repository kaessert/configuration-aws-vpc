"""
E2E Test: Customer Gateways

Validates Customer Gateway implementation with real AWS resources:
- VPC with two Customer Gateways configured
- Customer Gateway with standard BGP ASN
- Customer Gateway with extended BGP ASN
- Customer Gateway resources reach Ready/Synced state
- Resource lifecycle (create → ready → synced → delete)

This test validates Task 4.2 (Customer Gateway Support) implementation.

Spec: Customer Gateways represent the customer side of VPN connections.
This test validates that multiple Customer Gateways can be created with different configurations.

NOTE: Customer Gateways are metadata objects and don't require actual on-premises infrastructure.
They use IP addresses from TEST-NET-1 (RFC 5737) which won't route but are valid for resource creation.
"""

import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-cgw"
        spec= {
            # CRITICAL: Always specify Crossplane version for v2
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Timeouts for AWS resource creation (20 min) and cleanup (10 min)
            # Spec: Customer Gateway creation is fast (< 1 minute)
            timeoutSeconds: 1200
            cleanupTimeoutSeconds: 600

            # CRITICAL: Always cleanup resources
            skipDelete: False

            # Test manifest: VPC Claim with Customer Gateways
            # Spec: This validates Customer Gateway creation with different configurations
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-vpc-cgw"
                        namespace: "default"
                    }
                    spec: {
                        # Basic VPC configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]

                        # Spec: Define two Customer Gateways with different configurations
                        customerGateways: {
                            # Spec: First gateway with standard BGP ASN
                            "headquarters": {
                                bgpAsn: 65000
                                ipAddress: "1.1.1.1"  # Valid public IP (Cloudflare DNS)
                                type: "ipsec.1"
                                deviceName: "hq-router"
                                tags: {
                                    Location: "headquarters"
                                    Priority: "high"
                                }
                            }
                            # Spec: Second gateway with extended BGP ASN
                            "branch-office": {
                                bgpAsnExtended: "4200000000"
                                ipAddress: "8.8.8.8"  # Valid public IP (Google DNS)
                                type: "ipsec.1"
                                deviceName: "branch-router"
                                tags: {
                                    Location: "branch-office"
                                    Priority: "medium"
                                }
                            }
                        }

                        tags: {
                            Environment: "e2e-test"
                            Feature: "customer-gateways"
                            ManagedBy: "upbound-e2e"
                        }
                    }
                }
            ]

            # Extra resources - ProviderConfig for AWS authentication
            # IMPORTANT: Use IAM role with Upbound Identity, NEVER static credentials
            # Spec: Uses solutions org IAM role for E2E testing via Upbound webIdentity
            extraResources: [
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"
                    }
                    spec: {
                        credentials: {
                            source: "Upbound"
                            upbound: {
                                webIdentity: {
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
