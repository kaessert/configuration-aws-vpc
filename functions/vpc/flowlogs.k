"""
VPC Flow Logs Module

This module generates AWS VPC Flow Logs resources including:
- CloudWatch Log Group for storing flow logs
- IAM Role with trust policy for VPC Flow Logs service
- IAM Role Policy granting CloudWatch Logs permissions
- FlowLog resource attached to VPC

Based on terraform-aws-modules/terraform-aws-vpc flow logs implementation.
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2
import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as cloudwatchlogs
import models.io.upbound.awsm.iam.v1beta1 as iam


# Generate CloudWatch Log Group for Flow Logs
_generateFlowLogGroup = lambda name: str, region: str, tags: {str:str} -> [any] {
    """
    Generate CloudWatch Log Group for VPC Flow Logs

    Args:
        name: VPC name for resource naming
        region: AWS region
        tags: Resource tags

    Returns:
        List containing CloudWatch Log Group resource
    """
    [
        cloudwatchlogs.Group {
            metadata.name = "flowlog-loggroup-${name}"
            spec = {
                providerConfigRef = {
                    kind = "ProviderConfig"
                    name = "default"
                }
                managementPolicies = ["*"]
                forProvider = {
                    region = region
                    tags = tags | {
                        Name = "flowlog-loggroup-${name}"
                    }
                }
            }
        }
    ]
}


# Generate IAM Role for Flow Logs
_generateFlowLogRole = lambda name: str, tags: {str:str} -> [any] {
    """
    Generate IAM Role for VPC Flow Logs with trust policy

    Args:
        name: VPC name for resource naming
        tags: Resource tags

    Returns:
        List containing IAM Role resource
    """
    trustPolicyJson = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"vpc-flow-logs.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

    [
        iam.Role {
            metadata.name = "flowlog-role-${name}"
            spec = {
                providerConfigRef = {
                    kind = "ProviderConfig"
                    name = "default"
                }
                managementPolicies = ["*"]
                forProvider = {
                    assumeRolePolicy = trustPolicyJson
                    tags = tags | {
                        Name = "flowlog-role-${name}"
                    }
                }
            }
        }
    ]
}


# Generate IAM Role Policy for CloudWatch Logs permissions
_generateFlowLogRolePolicy = lambda name: str -> [any] {
    """
    Generate IAM Role Policy granting CloudWatch Logs permissions

    Args:
        name: VPC name for resource naming

    Returns:
        List containing IAM Role Policy resource
    """
    policyJson = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Resource":"*"}]}'

    [
        iam.RolePolicy {
            metadata.name = "flowlog-policy-${name}"
            spec = {
                providerConfigRef = {
                    kind = "ProviderConfig"
                    name = "default"
                }
                managementPolicies = ["*"]
                forProvider = {
                    policy = policyJson
                    roleSelector = {
                        matchControllerRef = True
                    }
                }
            }
        }
    ]
}


# Generate FlowLog resource
_generateFlowLog = lambda name: str, region: str, trafficType: str, maxAggregationInterval: int, tags: {str:str} -> [any] {
    """
    Generate VPC FlowLog resource

    Args:
        name: VPC name for resource naming
        region: AWS region
        trafficType: Traffic type to capture (ACCEPT, REJECT, ALL)
        maxAggregationInterval: Aggregation interval in seconds (60 or 600)
        tags: Resource tags

    Returns:
        List containing FlowLog resource
    """
    [
        ec2.FlowLog {
            metadata.name = "flowlog-${name}"
            spec = {
                providerConfigRef = {
                    kind = "ProviderConfig"
                    name = "default"
                }
                managementPolicies = ["*"]
                forProvider = {
                    vpcIdSelector = {
                        matchControllerRef = True
                    }
                    region = region
                    trafficType = trafficType
                    maxAggregationInterval = maxAggregationInterval
                    logDestinationType = "cloud-watch-logs"
                    iamRoleArnSelector = {
                        matchControllerRef = True
                    }
                    logDestinationSelector = {
                        matchControllerRef = True
                    }
                    tags = tags | {
                        Name = "flowlog-${name}"
                    }
                }
            }
        }
    ]
}


# Main function to generate all Flow Logs resources
generateFlowLogs = lambda name: str, region: str, enableFlowLog: bool, createFlowLogCloudwatchLogGroup: bool, flowLogTrafficType: str, flowLogMaxAggregationInterval: int, tags: {str:str} -> [any] {
    """
    Generate all VPC Flow Logs resources

    Args:
        name: VPC name for resource naming
        region: AWS region
        enableFlowLog: Enable VPC Flow Logs
        createFlowLogCloudwatchLogGroup: Create CloudWatch Log Group
        flowLogTrafficType: Traffic type (ACCEPT, REJECT, ALL)
        flowLogMaxAggregationInterval: Aggregation interval (60 or 600)
        tags: Resource tags

    Returns:
        List of all Flow Logs resources (Log Group, IAM Role, Role Policy, FlowLog)
    """
    _generateFlowLogGroup(name, region, tags) + \
    _generateFlowLogRole(name, tags) + \
    _generateFlowLogRolePolicy(name) + \
    _generateFlowLog(name, region, flowLogTrafficType, flowLogMaxAggregationInterval, tags) \
    if enableFlowLog and createFlowLogCloudwatchLogGroup else []
}
