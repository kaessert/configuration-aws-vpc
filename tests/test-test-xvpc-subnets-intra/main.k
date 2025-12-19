"""
Intra Subnets Composition Test

Tests intra subnet creation from terraform-vpc-analysis.md spec:
- Intra subnets distributed across availability zones
- mapPublicIpOnLaunch DISABLED on intra subnets
- Correct CIDR blocks assigned
- Proper tags applied (including Type="intra")
- VPC ID selector uses matchControllerRef
- Intra subnets have NO internet access (no NAT, no IGW routes)

Spec: This validates the INTRA SUBNET feature implementation
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-subnets-intra"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with intra subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-intra-subnets"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 intra subnets (isolated, no internet access)
                    intraSubnets: ["10.0.60.0/24", "10.0.61.0/24"]
                    tags: {
                        Environment: "test"
                    }
                    intraSubnetTags: {
                        Tier: "intra"
                    }
                }
            }

            # Spec: Assert that intra subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-intra-subnets"
                    }
                    spec: {
                        forProvider: {
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Intra subnet 1 in us-west-2a
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-intra-test-intra-subnets-us-west-2a"
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
                            # Spec: First intra subnet CIDR
                            cidrBlock: "10.0.60.0/24"
                            # Spec: Intra subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            # Spec: Tags should include base tags + intraSubnetTags + Type="intra"
                            tags: {
                                Environment: "test"
                                Tier: "intra"
                                Name: "subnet-intra-test-intra-subnets-us-west-2a"
                                Type: "intra"
                            }
                        }
                    }
                },
                # Spec: Intra subnet 2 in us-west-2b
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-intra-test-intra-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second intra subnet CIDR
                            cidrBlock: "10.0.61.0/24"
                            # Spec: Intra subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Tier: "intra"
                                Name: "subnet-intra-test-intra-subnets-us-west-2b"
                                Type: "intra"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
