"""
E2E Test: Complete VPC with All Subnet Types

Validates comprehensive VPC configuration with all features:
- VPC with all 6 subnet types: public, private, database, elasticache, redshift, intra
- Internet Gateway for public subnets
- NAT Gateway (single) for private subnet internet access
- Elastic IP for NAT Gateway
- Isolated routing for intra subnets (no internet access)
- Database subnets with optional NAT routing
- All routing scenarios validated
- Resource lifecycle (create → ready → synced → delete)

This test validates all tasks (2.1-2.5) with a complete real-world configuration.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-complete"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }
            defaultConditions: ["Ready", "Synced"]
            skipDelete: False
            timeoutSeconds: 3000  # 50 minutes (more resources = longer)
            cleanupTimeoutSeconds: 900  # 15 minutes

            # Test manifest: Complete VPC with all subnet types
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-complete-vpc"
                        namespace: "default"
                    }
                    spec: {
                        # Core configuration
                        region: "us-west-2"
                        cidr: "10.3.0.0/16"
                        azs: ["us-west-2a", "us-west-2b", "us-west-2c"]

                        # Public subnets (for IGW and NAT placement)
                        publicSubnets: ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]

                        # Private subnets (route via NAT)
                        privateSubnets: ["10.3.11.0/24", "10.3.12.0/24", "10.3.13.0/24"]

                        # Database subnets (with NAT access)
                        databaseSubnets: ["10.3.21.0/24", "10.3.22.0/24", "10.3.23.0/24"]
                        createDatabaseSubnetRouteTable: True
                        createDatabaseNatGatewayRoute: True

                        # ElastiCache subnets
                        elasticacheSubnets: ["10.3.31.0/24", "10.3.32.0/24", "10.3.33.0/24"]

                        # Redshift subnets
                        redshiftSubnets: ["10.3.41.0/24", "10.3.42.0/24", "10.3.43.0/24"]

                        # Intra subnets (isolated, no internet access)
                        intraSubnets: ["10.3.51.0/24", "10.3.52.0/24", "10.3.53.0/24"]

                        # Enable Internet Gateway
                        createIgw: True

                        # Enable NAT Gateway - SINGLE strategy
                        enableNatGateway: True
                        singleNatGateway: True
                        oneNatGatewayPerAz: False

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags
                        tags: {
                            Environment: "e2e-test"
                            TestName: "complete"
                            ManagedBy: "upbound-e2e"
                        }

                        # Subnet-specific tags
                        publicSubnetTags: {
                            Tier: "Public"
                        }
                        privateSubnetTags: {
                            Tier: "Private"
                        }
                        databaseSubnetTags: {
                            Tier: "Database"
                        }
                        elasticacheSubnetTags: {
                            Tier: "ElastiCache"
                        }
                        redshiftSubnetTags: {
                            Tier: "Redshift"
                        }
                        intraSubnetTags: {
                            Tier: "Isolated"
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
