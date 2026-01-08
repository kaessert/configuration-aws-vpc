"""
E2E Test: Extended Network ACL Support

Validates extended NACL support (Task 4.6) with real AWS resources:
- Database subnet dedicated NACLs with custom rules
- ElastiCache subnet dedicated NACLs with custom rules
- Redshift subnet dedicated NACLs with custom rules
- Intra subnet dedicated NACLs with custom rules
- Resource lifecycle (create → ready → synced → delete)

This test validates Task 4.6 implementation with comprehensive VPC configuration:
- 2 availability zones
- 4 specialized subnet types (database, elasticache, redshift, intra)
- 4 dedicated Network ACLs (one per subnet type)
- Custom ACL rules for each subnet type

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
        metadata.name: "e2etest-vpc-nacl-extended"
        spec= {
            # CRITICAL: Always specify Crossplane version for v2
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "Rapid"
            }

            # Validation conditions
            defaultConditions: ["Ready", "Synced"]

            # Timeouts for AWS resource creation (30 min) and cleanup (10 min)
            timeoutSeconds: 1800
            cleanupTimeoutSeconds: 600

            # CRITICAL: Always cleanup resources
            skipDelete: False

            # Test manifest: VPC XR with extended NACL support
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-vpc-nacl-extended"
                        namespace: "default"
                    }
                    spec: {
                        # Region and AZs
                        region: "us-west-2"
                        azs: ["us-west-2a", "us-west-2b"]

                        # VPC CIDR
                        cidr: "10.200.0.0/16"

                        # Database subnets with dedicated NACL
                        databaseSubnets: [
                            "10.200.101.0/24",  # us-west-2a
                            "10.200.102.0/24"   # us-west-2b
                        ]
                        databaseDedicatedNetworkAcl: True
                        databaseInboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 3306
                                toPort: 3306
                            },
                            {
                                ruleNumber: 110
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 5432
                                toPort: 5432
                            }
                        ]
                        databaseOutboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 1024
                                toPort: 65535
                            }
                        ]
                        databaseAclTags: {
                            Type: "database"
                            Tier: "data"
                        }

                        # ElastiCache subnets with dedicated NACL
                        elasticacheSubnets: [
                            "10.200.201.0/24",  # us-west-2a
                            "10.200.202.0/24"   # us-west-2b
                        ]
                        elasticacheDedicatedNetworkAcl: True
                        elasticacheInboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 6379
                                toPort: 6379
                            },
                            {
                                ruleNumber: 110
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 11211
                                toPort: 11211
                            }
                        ]
                        elasticacheOutboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 1024
                                toPort: 65535
                            }
                        ]
                        elasticacheAclTags: {
                            Type: "elasticache"
                            Tier: "cache"
                        }

                        # Redshift subnets with dedicated NACL
                        redshiftSubnets: [
                            "10.200.151.0/24",  # us-west-2a
                            "10.200.152.0/24"   # us-west-2b
                        ]
                        redshiftDedicatedNetworkAcl: True
                        redshiftInboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 5439
                                toPort: 5439
                            }
                        ]
                        redshiftOutboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 1024
                                toPort: 65535
                            }
                        ]
                        redshiftAclTags: {
                            Type: "redshift"
                            Tier: "analytics"
                        }

                        # Intra subnets with dedicated NACL
                        intraSubnets: [
                            "10.200.51.0/24",  # us-west-2a
                            "10.200.52.0/24"   # us-west-2b
                        ]
                        intraDedicatedNetworkAcl: True
                        intraInboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 443
                                toPort: 443
                            }
                        ]
                        intraOutboundAclRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.200.0.0/16"
                                fromPort: 443
                                toPort: 443
                            }
                        ]
                        intraAclTags: {
                            Type: "intra"
                            Tier: "isolated"
                        }

                        # DNS settings
                        enableDnsHostnames: True
                        enableDnsSupport: True

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "nacl-extended"
                            ManagedBy: "upbound-e2e"
                            Feature: "task-4.6"
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
