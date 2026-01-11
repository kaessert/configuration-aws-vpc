"""
VPC Flow Logs Composition Tests

Tests VPC Flow Logs functionality with various configurations:
- **disabled**: Flow Logs disabled (default)
- **cloudwatch**: Flow Logs to CloudWatch Logs with IAM role
- **s3**: Flow Logs to S3 bucket

Spec: This validates Task 3.4 - VPC Flow Logs support implementation

Reference: thoughts/TASKS.md Task 3.4, terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as cloudwatchlogsv1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1
import models.io.upbound.awsm.s3.v1beta1 as s3v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: Flow Logs Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-flowlogs-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-no-flowlogs"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: Flow Logs disabled (default: false)
                enableFlowLog: False
                tags: {
                    Name: "test-vpc-no-flowlogs"
                    Environment: "test"
                    Feature: "no-flow-logs"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-no-flowlogs" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-no-flowlogs"
                            Environment: "test"
                            Feature: "no-flow-logs"
                        }
                    }
                }
            }
            # Spec: NO FlowLog resource should be created
            # (assertResources only contains VPC - no FlowLog means it's not created)
        ]
    }
}

# Test 2: Flow Logs to CloudWatch Logs
_test_cloudwatch = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-flowlogs-cloudwatch"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-flowlogs-cw"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: Enable Flow Logs
                enableFlowLog: True
                # Spec: Create CloudWatch Log Group
                createFlowLogCloudwatchLogGroup: True
                # Spec: Traffic type (default: ALL)
                flowLogTrafficType: "ALL"
                # Spec: Aggregation interval (default: 600 seconds)
                flowLogMaxAggregationInterval: 600
                tags: {
                    Name: "test-vpc-flowlogs-cw"
                    Environment: "test"
                    Feature: "flow-logs"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-flowlogs-cw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-flowlogs-cw"
                            Environment: "test"
                            Feature: "flow-logs"
                        }
                    }
                }
            },
            # Spec: CloudWatch Log Group for Flow Logs
            cloudwatchlogsv1beta1.Group{
                metadata: { name: "flowlog-loggroup-test-vpc-flowlogs-cw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        tags: {
                            Name: "flowlog-loggroup-test-vpc-flowlogs-cw"
                            Environment: "test"
                            Feature: "flow-logs"
                        }
                    }
                }
            },
            # Spec: IAM Role for Flow Logs
            iamv1beta1.Role{
                metadata: { name: "flowlog-role-test-vpc-flowlogs-cw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Trust policy for VPC Flow Logs service
                        assumeRolePolicy: """{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"vpc-flow-logs.amazonaws.com"},"Action":"sts:AssumeRole"}]}"""
                        tags: {
                            Name: "flowlog-role-test-vpc-flowlogs-cw"
                            Environment: "test"
                            Feature: "flow-logs"
                        }
                    }
                }
            },
            # Spec: IAM Role Policy for CloudWatch Logs permissions
            iamv1beta1.RolePolicy{
                metadata: { name: "flowlog-policy-test-vpc-flowlogs-cw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Policy grants CloudWatch Logs permissions
                        policy: """{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Resource":"*"}]}"""
                        roleSelector: { matchControllerRef: True }
                    }
                }
            },
            # Spec: FlowLog should be created when enableFlowLog: true
            ec2v1beta1.FlowLog{
                metadata: { name: "flowlog-test-vpc-flowlogs-cw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: FlowLog attached to VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: Traffic type set to ALL
                        trafficType: "ALL"
                        # Spec: Max aggregation interval set to 600 seconds
                        maxAggregationInterval: 600
                        # Spec: Destination type is CloudWatch Logs
                        logDestinationType: "cloud-watch-logs"
                        # Spec: IAM Role for permissions
                        iamRoleArnSelector: { matchControllerRef: True }
                        # Spec: Log destination (CloudWatch Log Group)
                        logDestinationSelector: { matchControllerRef: True }
                        # Spec: Correct tags applied
                        tags: {
                            Name: "flowlog-test-vpc-flowlogs-cw"
                            Environment: "test"
                            Feature: "flow-logs"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: Flow Logs to S3 Bucket
_test_s3 = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-flowlogs-s3"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-flowlogs-s3"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: Enable Flow Logs
                enableFlowLog: True
                # Spec: Create S3 bucket for Flow Logs
                createFlowLogS3Bucket: True
                # Spec: CloudWatch should NOT be created
                createFlowLogCloudwatchLogGroup: False
                # Spec: Traffic type (default: ALL)
                flowLogTrafficType: "ALL"
                # Spec: Aggregation interval (default: 600 seconds)
                flowLogMaxAggregationInterval: 600
                # Spec: S3-specific options
                flowLogFileFormat: "plain-text"
                flowLogHiveCompatiblePartitions: False
                flowLogPerHourPartition: False
                tags: {
                    Name: "test-vpc-flowlogs-s3"
                    Environment: "test"
                    Feature: "flow-logs-s3"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-flowlogs-s3" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-vpc-flowlogs-s3"
                            Environment: "test"
                            Feature: "flow-logs-s3"
                        }
                    }
                }
            },
            # Spec: S3 Bucket for Flow Logs
            s3v1beta1.Bucket{
                metadata: { name: "flowlog-bucket-test-vpc-flowlogs-s3" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        tags: {
                            Name: "flowlog-bucket-test-vpc-flowlogs-s3"
                            Environment: "test"
                            Feature: "flow-logs-s3"
                        }
                    }
                }
            },
            # Spec: FlowLog should be created when enableFlowLog: true
            ec2v1beta1.FlowLog{
                metadata: { name: "flowlog-test-vpc-flowlogs-s3" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: FlowLog attached to VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: Traffic type set to ALL
                        trafficType: "ALL"
                        # Spec: Max aggregation interval set to 600 seconds
                        maxAggregationInterval: 600
                        # Spec: Destination type is S3
                        logDestinationType: "s3"
                        # Spec: Log destination (S3 bucket ARN via selector)
                        logDestinationSelector: { matchControllerRef: True }
                        # Spec: S3-specific destination options
                        destinationOptions: {
                            fileFormat: "plain-text"
                            hiveCompatiblePartitions: False
                            perHourPartition: False
                        }
                        # Spec: Correct tags applied
                        tags: {
                            Name: "flowlog-test-vpc-flowlogs-s3"
                            Environment: "test"
                            Feature: "flow-logs-s3"
                        }
                    }
                }
            }
            # Spec: NO IAM Role or CloudWatch Log Group (S3 doesn't need them)
        ]
    }
}

items = [
    _test_disabled,
    _test_cloudwatch,
    _test_s3
]
