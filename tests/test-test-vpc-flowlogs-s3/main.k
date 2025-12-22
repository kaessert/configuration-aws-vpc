"""
VPC Flow Logs - S3 Destination Test

Tests VPC Flow Log creation with S3 bucket destination:
- VPC with basic configuration
- FlowLog created when enableFlowLog is enabled
- Logs sent to S3 bucket
- S3 bucket created when createFlowLogS3Bucket is enabled
- Traffic type configurable (ACCEPT, REJECT, ALL)
- Max aggregation interval configurable
- FlowLog attached to VPC via vpcIdSelector
- S3-specific options: file format, hive partitions, per-hour partition
- Correct tags applied
- NO IAM role or CloudWatch Log Group (S3 doesn't need them)

Spec: This validates VPC Flow Logs with S3 destination (task 3.4) from TASKS.md
Verifies Flow Logs to S3 based on terraform-aws-vpc module behavior

Reference:
- Terraform module: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/vpc-flow-logs.tf
- S3 destination options: flow_log_file_format, flow_log_hive_compatible_partitions, flow_log_per_hour_partition
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.s3.v1beta1 as s3v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-flowlogs-s3"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with Flow Logs to S3 enabled
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
                        Environment: "test"
                        Feature: "flow-logs-s3"
                    }
                }
            }

            # Assert that VPC, S3 Bucket, and FlowLog are created
            # NO IAM Role, NO CloudWatch Log Group (S3 doesn't need them)
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-flowlogs-s3"
                    }
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
                                Environment: "test"
                                Feature: "flow-logs-s3"
                                Name: "test-vpc-flowlogs-s3"
                            }
                        }
                    }
                },
                # Spec: S3 Bucket for Flow Logs
                s3v1beta1.Bucket{
                    metadata: {
                        name: "flowlog-bucket-test-vpc-flowlogs-s3"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            tags: {
                                Environment: "test"
                                Feature: "flow-logs-s3"
                                Name: "flowlog-bucket-test-vpc-flowlogs-s3"
                            }
                        }
                    }
                },
                # Spec: FlowLog should be created when enableFlowLog: true
                ec2v1beta1.FlowLog{
                    metadata: {
                        name: "flowlog-test-vpc-flowlogs-s3"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: FlowLog attached to VPC
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Traffic type set to ALL
                            trafficType: "ALL"
                            # Spec: Max aggregation interval set to 600 seconds
                            maxAggregationInterval: 600
                            # Spec: Destination type is S3
                            logDestinationType: "s3"
                            # Spec: Log destination (S3 bucket ARN via selector)
                            logDestinationSelector: {
                                matchControllerRef: True
                            }
                            # Spec: S3-specific destination options
                            destinationOptions: {
                                fileFormat: "plain-text"
                                hiveCompatiblePartitions: False
                                perHourPartition: False
                            }
                            # Spec: Correct tags applied
                            tags: {
                                Environment: "test"
                                Feature: "flow-logs-s3"
                                Name: "flowlog-test-vpc-flowlogs-s3"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
