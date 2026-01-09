"""
E2E Test: Default Resource Management

Validates Task 4.8 default resource management with real AWS resources:
- DefaultSecurityGroup - with empty ingress/egress (security hardening)
- DefaultNetworkACL - with custom HTTP/HTTPS rules
- DefaultRouteTable - with custom route to IGW
- Resource lifecycle (create → ready → synced → delete)

This test validates the implementation of managing AWS-created default resources
for enhanced security and centralized routing configuration.

Reference: terraform-aws-modules/terraform-aws-vpc default resource management
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-default-resources"
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

            # Test manifest: VPC with all three default resource types managed
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-test-default-resources"
                        namespace: "default"
                    }
                    spec: {
                        # Core VPC config
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"

                        # Enable IGW for default route table routing
                        createIgw: True

                        # Default Security Group Management (Security Hardening)
                        manageDefaultSecurityGroup: True
                        defaultSecurityGroupTags: {
                            Type: "default-security-group"
                            Managed: "true"
                        }

                        # Default Network ACL Management
                        manageDefaultNetworkAcl: True
                        defaultNetworkAclIngressRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.0.0.0/16"
                                fromPort: 443
                                toPort: 443
                            },
                            {
                                ruleNumber: 110
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "10.0.0.0/16"
                                fromPort: 80
                                toPort: 80
                            }
                        ]
                        defaultNetworkAclEgressRules: [
                            {
                                ruleNumber: 100
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 443
                                toPort: 443
                            },
                            {
                                ruleNumber: 110
                                protocol: "tcp"
                                ruleAction: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 80
                                toPort: 80
                            }
                        ]
                        defaultNetworkAclTags: {
                            Type: "default-nacl"
                            Managed: "true"
                        }

                        # Default Route Table Management
                        manageDefaultRouteTable: True
                        defaultRouteTableRoutes: [
                            {
                                destinationCidrBlock: "0.0.0.0/0"
                                gatewayType: "igw"
                            }
                        ]
                        defaultRouteTableTags: {
                            Type: "default-route-table"
                            Managed: "true"
                        }

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "default-resources"
                            ManagedBy: "upbound-e2e"
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
