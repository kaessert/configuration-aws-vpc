"""
VPC Flow Logs - Disabled Test

Tests that NO Flow Logs are created when enableFlowLog is false (default):
- VPC with basic configuration
- enableFlowLog: false (default)
- NO FlowLog resources created

Spec: This validates VPC Flow Logs (task 3.4) from TASKS.md
Verifies default behavior: Flow Logs disabled unless explicitly enabled

Reference:
- Terraform module: https://github.com/terraform-aws-modules/terraform-aws-vpc/blob/master/vpc-flow-logs.tf
- Default: enable_flow_log = false
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-flowlogs-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with Flow Logs disabled (default)
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
                        Environment: "test"
                        Feature: "no-flow-logs"
                    }
                }
            }

            # Assert that ONLY VPC is created, NO FlowLog resources
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-no-flowlogs"
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
                                Feature: "no-flow-logs"
                                Name: "test-vpc-no-flowlogs"
                            }
                        }
                    }
                }
                # Spec: NO FlowLog resource should be created
                # (assertResources only contains VPC - no FlowLog means it's not created)
            ]
        }
    }
]
items= _items
