"""
Public Subnets Composition Test

Tests public subnet creation from terraform-vpc-analysis.md spec:
- Public subnets distributed across availability zones
- mapPublicIpOnLaunch enabled on public subnets
- Correct CIDR blocks assigned
- Proper tags applied (including subnet type)
- VPC ID selector uses matchControllerRef

Spec: This validates the PUBLIC SUBNET feature implementation
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-subnets-public"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with public subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-public-subnets"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 public subnets
                    publicSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                    mapPublicIpOnLaunch: True
                    tags: {
                        Environment: "test"
                    }
                    publicSubnetTags: {
                        Tier: "public"
                    }
                }
            }

            # Spec: Assert that public subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-public-subnets"
                    }
                    spec: {
                        forProvider: {
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Public subnet 1 in us-west-2a
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-public-subnets-us-west-2a"
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
                            # Spec: First public subnet CIDR
                            cidrBlock: "10.0.10.0/24"
                            # Spec: Public subnets MUST have mapPublicIpOnLaunch enabled
                            mapPublicIpOnLaunch: True
                            # Spec: Tags should include base tags + publicSubnetTags + Type
                            tags: {
                                Environment: "test"
                                Tier: "public"
                                Name: "subnet-public-test-public-subnets-us-west-2a"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet 2 in us-west-2b
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-public-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second public subnet CIDR
                            cidrBlock: "10.0.11.0/24"
                            # Spec: Public subnets MUST have mapPublicIpOnLaunch enabled
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Tier: "public"
                                Name: "subnet-public-test-public-subnets-us-west-2b"
                                Type: "public"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
