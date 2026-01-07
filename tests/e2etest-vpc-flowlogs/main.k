"""
VPC Flow Logs E2E Test

Tests VPC Flow Logs with CloudWatch Logs destination in real AWS environment:
- VPC with basic configuration
- Flow Logs enabled with CloudWatch destination
- CloudWatch Log Group created
- IAM Role with VPC Flow Logs trust policy created
- IAM Role Policy with CloudWatch permissions created
- FlowLog resource created and attached to VPC
- All resources reach Ready/Synced state
- Proper cleanup after test

Spec: This validates VPC Flow Logs (task 3.4) in a real AWS environment
Verifies Flow Logs to CloudWatch based on terraform-aws-vpc module behavior

Reference:
- Terraform module: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/vpc-flow-logs.tf
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-flowlogs"
        spec= {
            # Crossplane configuration
            crossplane: {
                version: "2.0.2-up.5"
                autoUpgrade: {
                    channel: "Rapid"
                }
            }

            # Timeouts
            # Spec: Flow Logs resources may take longer to create (IAM roles, log groups, flow logs)
            # 30 minutes for resource creation, 10 minutes for cleanup
            timeoutSeconds: 1800
            cleanupTimeoutSeconds: 600

            # Ensure cleanup happens
            skipDelete: False

            # Validation: Check that resources reach Ready and Synced states
            # Spec: All resources (VPC, CloudWatch Log Group, IAM Role, IAM Policy, FlowLog) must be Ready
            defaultConditions: ["Ready", "Synced"]

            # Main test manifests - VPC Claim with Flow Logs enabled
            # Spec: Create a VPC with Flow Logs enabled, matching Terraform flow logs implementation
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"  # Using namespaced claim (v2)
                    metadata: {
                        name: "e2e-test-vpc-flowlogs"
                        namespace: "default"
                    }
                    spec: {
                        # Core VPC configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a"]
                        publicSubnets: ["10.0.1.0/24"]

                        # Spec: Enable Flow Logs with CloudWatch destination
                        enableFlowLog: True
                        createFlowLogCloudwatchLogGroup: True

                        # Spec: Configure Flow Logs behavior
                        flowLogTrafficType: "ALL"  # Capture all traffic (ACCEPT, REJECT, ALL)
                        flowLogMaxAggregationInterval: 600  # 10 minutes aggregation

                        # Tags for identification
                        tags: {
                            Environment: "e2e-test"
                            ManagedBy: "upbound"
                            TestType: "flowlogs"
                            Feature: "vpc-flow-logs"
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
                                    # Spec: IAM role for E2E testing in solutions org
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
