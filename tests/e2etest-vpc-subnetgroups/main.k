"""
E2E Test: Subnet Groups (RDS, ElastiCache, Redshift)

Validates subnet group creation with real AWS resources:
- VPC with database, elasticache, and redshift subnets
- Automatic subnet group creation for each service
- Subnet groups properly reference created subnets
- Resource lifecycle (create → ready → synced → delete)

This test validates Task 3.5 (Subnet Groups) implementation.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-subnetgroups"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 2400  # 40 minutes
            cleanupTimeoutSeconds: 600  # 10 minutes

            # Test manifest: VPC with database, elasticache, and redshift subnets + subnet groups
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-subnetgroups"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Subnets for each service type
                        databaseSubnets: ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
                        elasticacheSubnets: ["10.0.31.0/24", "10.0.32.0/24", "10.0.33.0/24"]
                        redshiftSubnets: ["10.0.41.0/24", "10.0.42.0/24", "10.0.43.0/24"]

                        # Enable subnet group creation
                        createDatabaseSubnetGroup: True
                        createElasticacheSubnetGroup: True
                        createRedshiftSubnetGroup: True

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "subnet-groups"
                            ManagedBy: "upbound-e2e"
                            Feature: "subnet-groups"
                        }
                        databaseSubnetGroupTags: {
                            Type: "database-subnet-group"
                        }
                        elasticacheSubnetGroupTags: {
                            Type: "elasticache-subnet-group"
                        }
                        redshiftSubnetGroupTags: {
                            Type: "redshift-subnet-group"
                        }
                    }
                }
            ]

            # ProviderConfig with IAM role (no static credentials)
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
