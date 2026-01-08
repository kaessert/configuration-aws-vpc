"""
E2E Test: VPN Gateway

Validates VPN Gateway implementation with real AWS resources:
- VPC with VPN Gateway enabled
- VPN Gateway attached to VPC
- Custom Amazon-side ASN configuration (65000)
- Route propagation to private route tables
- VPN Gateway resources reach Ready/Synced state
- Resource lifecycle (create → ready → synced → delete)

This test validates Task 4.1 (VPN Gateway Support) implementation.

Spec: VPN Gateway enables hybrid cloud connectivity between AWS VPC and on-premises networks.
This test validates the basic VPN Gateway setup with route propagation.
"""

import models.io.upbound.aws.cloudwatchlogs.v1beta1 as cloudwatchlogsv1beta1
import models.io.upbound.aws.cloudwatchlogs.v1beta2 as cloudwatchlogsv1beta2
import models.io.upbound.aws.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.aws.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.aws.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.aws.elasticache.v1beta2 as elasticachev1beta2
import models.io.upbound.aws.iam.v1beta1 as iamv1beta1
import models.io.upbound.aws.rds.v1beta1 as rdsv1beta1
import models.io.upbound.aws.rds.v1beta2 as rdsv1beta2
import models.io.upbound.aws.rds.v1beta3 as rdsv1beta3
import models.io.upbound.aws.redshift.v1beta1 as redshiftv1beta1
import models.io.upbound.aws.redshift.v1beta2 as redshiftv1beta2
import models.io.upbound.aws.s3.v1beta1 as s3v1beta1
import models.io.upbound.aws.s3.v1beta2 as s3v1beta2
import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as awsmcloudwatchlogsv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as awsmec2v1beta1
import models.io.upbound.awsm.elasticache.v1beta1 as awsmelasticachev1beta1
import models.io.upbound.awsm.iam.v1beta1 as awsmiamv1beta1
import models.io.upbound.awsm.rds.v1beta1 as awsmrdsv1beta1
import models.io.upbound.awsm.redshift.v1beta1 as awsmredshiftv1beta1
import models.io.upbound.awsm.s3.v1beta1 as awsms3v1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-vpn"
        spec= {
            # CRITICAL: Always specify Crossplane version for v2
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Timeouts for AWS resource creation (30 min) and cleanup (10 min)
            # Spec: VPN Gateway creation typically takes 5-10 minutes
            timeoutSeconds: 1800
            cleanupTimeoutSeconds: 600

            # CRITICAL: Always cleanup resources
            skipDelete: False

            # Test manifest: VPC Claim with VPN Gateway enabled
            # Spec: This validates VPN Gateway creation, attachment, and route propagation
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-vpc-vpn"
                        namespace: "default"
                    }
                    spec: {
                        # Basic VPC configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]

                        # Spec: Public subnets with IGW for internet connectivity
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                        createIgw: True

                        # Spec: Private subnets with NAT Gateway (creates private route tables)
                        privateSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                        enableNatGateway: True
                        singleNatGateway: True  # Cost optimization for E2E test

                        # Spec: VPN Gateway configuration
                        enableVpnGateway: True
                        amazonSideAsn: 65000  # Custom ASN (default is 64512)

                        # Spec: Route propagation to private route tables
                        # This allows on-premises networks to communicate with private subnets
                        propagatePrivateRouteTablesVgw: True

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "vpn-gateway"
                            ManagedBy: "upbound-e2e"
                            Feature: "vpn-gateway"
                        }
                        vpnGatewayTags: {
                            Component: "vpn"
                            Purpose: "hybrid-connectivity"
                        }
                    }
                }
            ]

            # CRITICAL: ProviderConfig with web identity (NO static credentials)
            # Spec: Uses Upbound web identity federation with IAM role for secure authentication
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
