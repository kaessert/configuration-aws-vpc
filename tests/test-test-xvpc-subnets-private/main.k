"""
Private Subnets Composition Test

Tests private subnet creation from terraform-vpc-analysis.md spec:
- Private subnets distributed across availability zones
- mapPublicIpOnLaunch DISABLED on private subnets
- Correct CIDR blocks assigned
- Proper tags applied (including subnet type)
- VPC ID selector uses matchControllerRef

Spec: This validates the PRIVATE SUBNET feature implementation
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-subnets-private"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with private subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "XVPC"
                metadata: {
                    name: "test-private-subnets"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 private subnets
                    privateSubnets: ["10.0.20.0/24", "10.0.21.0/24"]
                    tags: {
                        Environment: "test"
                    }
                    privateSubnetTags: {
                        Tier: "private"
                    }
                }
            }

            # Spec: Assert that private subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "VPC"
                    metadata: {
                        name: "vpc-test-private-subnets"
                    }
                },
                # Spec: Private subnet 1 in us-west-2a
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    metadata: {
                        name: "subnet-private-test-private-subnets-us-west-2a"
                    }
                    spec: {
                        forProvider: {
                            # Spec: Subnet should reference VPC via controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to first AZ
                            availabilityZone: "us-west-2a"
                            # Spec: First private subnet CIDR
                            cidrBlock: "10.0.20.0/24"
                            # Spec: Private subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            # Spec: Tags should include base tags + privateSubnetTags + Type
                            tags: {
                                Environment: "test"
                                Tier: "private"
                                Name: "subnet-private-test-private-subnets-us-west-2a"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Private subnet 2 in us-west-2b
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    metadata: {
                        name: "subnet-private-test-private-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second private subnet CIDR
                            cidrBlock: "10.0.21.0/24"
                            # Spec: Private subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Tier: "private"
                                Name: "subnet-private-test-private-subnets-us-west-2b"
                                Type: "private"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
