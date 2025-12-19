"""
ElastiCache Subnets Composition Test

Tests elasticache subnet creation from terraform-vpc-analysis.md spec:
- ElastiCache subnets distributed across availability zones
- mapPublicIpOnLaunch DISABLED on elasticache subnets
- Correct CIDR blocks assigned
- Proper tags applied (including Type="elasticache")
- VPC ID selector uses matchControllerRef

Spec: This validates the ELASTICACHE SUBNET feature implementation
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-subnets-elasticache"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with elasticache subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-elasticache-subnets"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 elasticache subnets
                    elasticacheSubnets: ["10.0.40.0/24", "10.0.41.0/24"]
                    tags: {
                        Environment: "test"
                    }
                    elasticacheSubnetTags: {
                        Tier: "elasticache"
                    }
                }
            }

            # Spec: Assert that elasticache subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-elasticache-subnets"
                    }
                    spec: {
                        forProvider: {
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: ElastiCache subnet 1 in us-west-2a
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-elasticache-test-elasticache-subnets-us-west-2a"
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
                            # Spec: First elasticache subnet CIDR
                            cidrBlock: "10.0.40.0/24"
                            # Spec: ElastiCache subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            # Spec: Tags should include base tags + elasticacheSubnetTags + Type="elasticache"
                            tags: {
                                Environment: "test"
                                Tier: "elasticache"
                                Name: "subnet-elasticache-test-elasticache-subnets-us-west-2a"
                                Type: "elasticache"
                            }
                        }
                    }
                },
                # Spec: ElastiCache subnet 2 in us-west-2b
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-elasticache-test-elasticache-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second elasticache subnet CIDR
                            cidrBlock: "10.0.41.0/24"
                            # Spec: ElastiCache subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Tier: "elasticache"
                                Name: "subnet-elasticache-test-elasticache-subnets-us-west-2b"
                                Type: "elasticache"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
