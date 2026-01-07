"""
VPC Flow Logs - CloudWatch Test

Tests VPC Flow Log creation with CloudWatch Logs destination:
- VPC with basic configuration
- FlowLog created when enableFlowLog is enabled
- Logs sent to CloudWatch Logs
- Traffic type configurable (ACCEPT, REJECT, ALL)
- Max aggregation interval configurable
- FlowLog attached to VPC via vpcIdSelector
- Correct tags applied

Spec: This validates VPC Flow Logs (task 3.4) from TASKS.md
Verifies Flow Logs to CloudWatch based on terraform-aws-vpc module behavior

Reference:
- Terraform module: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/vpc-flow-logs.tf
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as cloudwatchlogsv1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-flowlogs-cloudwatch"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with Flow Logs to CloudWatch enabled
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
                        Environment: "test"
                        Feature: "flow-logs"
                    }
                }
            }

            # Assert that VPC, CloudWatch Log Group, IAM Role, and FlowLog are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-flowlogs-cw"
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
                                Feature: "flow-logs"
                                Name: "test-vpc-flowlogs-cw"
                            }
                        }
                    }
                },
                # Spec: CloudWatch Log Group for Flow Logs
                cloudwatchlogsv1beta1.Group{
                    metadata: {
                        name: "flowlog-loggroup-test-vpc-flowlogs-cw"
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
                                Feature: "flow-logs"
                                Name: "flowlog-loggroup-test-vpc-flowlogs-cw"
                            }
                        }
                    }
                },
                # Spec: IAM Role for Flow Logs
                iamv1beta1.Role{
                    metadata: {
                        name: "flowlog-role-test-vpc-flowlogs-cw"
                    }
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
                                Environment: "test"
                                Feature: "flow-logs"
                                Name: "flowlog-role-test-vpc-flowlogs-cw"
                            }
                        }
                    }
                },
                # Spec: IAM Role Policy for CloudWatch Logs permissions
                iamv1beta1.RolePolicy{
                    metadata: {
                        name: "flowlog-policy-test-vpc-flowlogs-cw"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Policy grants CloudWatch Logs permissions
                            policy: """{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Resource":"*"}]}"""
                            roleSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },
                # Spec: FlowLog should be created when enableFlowLog: true
                ec2v1beta1.FlowLog{
                    metadata: {
                        name: "flowlog-test-vpc-flowlogs-cw"
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
                            # Spec: Destination type is CloudWatch Logs
                            logDestinationType: "cloud-watch-logs"
                            # Spec: IAM Role for permissions
                            iamRoleArnSelector: {
                                matchControllerRef: True
                            }
                            # Spec: Log destination (CloudWatch Log Group)
                            logDestinationSelector: {
                                matchControllerRef: True
                            }
                            # Spec: Correct tags applied
                            tags: {
                                Environment: "test"
                                Feature: "flow-logs"
                                Name: "flowlog-test-vpc-flowlogs-cw"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
