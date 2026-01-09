"""
E2E Test: Interface VPC Endpoints

Validates Interface VPC Endpoints with real AWS resources:
- VPC with private subnets in multiple AZs
- Interface endpoints for EC2 and SSM services
- Endpoints placed in private subnets
- Private DNS enabled for service discovery
- Resource lifecycle (create → ready → synced → delete)

This test validates Interface VPC Endpoints implementation (task 4.5).

NOTE: Due to provider limitations, endpoints use VPC default security group.
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2etest-vpc-interface-endpoints"
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

            # Test manifest: VPC with Interface VPC Endpoints
            manifests: [
                {
                    apiVersion: "aws.platform.upbound.io/v1alpha1"
                    kind: "VPC"
                    metadata: {
                        name: "e2e-interface-endpoints"
                        namespace: "default"
                    }
                    spec: {
                        # Network configuration
                        region: "us-west-2"
                        cidr: "10.0.0.0/16"
                        azs: ["us-west-2a", "us-west-2b"]

                        # Private subnets for Interface endpoints
                        privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]

                        # Enable Interface VPC Endpoints for EC2 and SSM
                        enableInterfaceEndpoints: True
                        interfaceEndpointServices: ["ec2", "ssm"]
                        enableInterfaceEndpointPrivateDns: True

                        # Tags for resource identification and cleanup
                        tags: {
                            Environment: "e2e-test"
                            TestName: "interface-endpoints"
                            Feature: "vpc-endpoints"
                            ManagedBy: "upbound-e2e"
                            Owner: "solutions-team"
                        }
                        vpcEndpointTags: {
                            Type: "interface"
                            TestPhase: "e2e-validation"
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
