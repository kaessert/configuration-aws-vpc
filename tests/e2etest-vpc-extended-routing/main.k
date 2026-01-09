"""
E2E Test: VPC Extended Routing Options (Task 4.7)

Validates Task 4.7 extended routing features with real AWS resources:
- Per-AZ public route tables (onePublicRouteTablePerAz: true)
- ElastiCache separate routing with NAT Gateway access
- Database IGW route (WARNING: enables public database access - test only!)
- Multiple subnet types with custom routing configurations
- Resource lifecycle (create → ready → synced → delete)

This test creates a comprehensive VPC that exercises all new routing enhancements
introduced in Task 4.7, validating proper resource creation, configuration, and cleanup.

Reference: Task 4.7 - Extended Routing Options
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-extended-routing"
        spec= {
            # CRITICAL: Crossplane v2 configuration
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Timeouts for AWS resource creation and cleanup
            timeoutSeconds: 1800  # 30 minutes for resource creation
            cleanupTimeoutSeconds: 600  # 10 minutes for cleanup

            # CRITICAL: Always cleanup resources to avoid costs
            skipDelete: False

            # Test manifest: VPC with extended routing features
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-vpc-extended-routing"
                        namespace: "default"
                    }
                    spec: {
                        # Core VPC configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]

                        # Subnet configuration
                        publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                        elasticacheSubnets: ["10.0.11.0/24", "10.0.12.0/24"]
                        databaseSubnets: ["10.0.21.0/24", "10.0.22.0/24"]

                        # Gateway configuration
                        createIgw: True
                        enableNatGateway: True
                        singleNatGateway: True

                        # TASK 4.7 FEATURES: Extended Routing Options
                        # Feature 1: Per-AZ public route tables
                        onePublicRouteTablePerAz: True

                        # Feature 2: ElastiCache separate routing with NAT
                        createElasticacheSubnetRouteTable: True
                        createElasticacheNatGatewayRoute: True

                        # Feature 3: Database separate routing with IGW (WARNING: public access)
                        createDatabaseSubnetRouteTable: True
                        createDatabaseInternetGatewayRoute: True

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "vpc-extended-routing"
                            Task: "4.7"
                            ManagedBy: "upbound-e2e"
                            Purpose: "test-extended-routing-features"
                        }
                    }
                }
            ]

            # CRITICAL: ProviderConfig with web identity authentication
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
                                    # CRITICAL: Use exact IAM role ARN for E2E tests
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
