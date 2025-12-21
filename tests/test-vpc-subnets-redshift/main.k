"""
Redshift Subnets Composition Test

Tests redshift subnet creation from terraform-vpc-analysis.md spec:
- Redshift subnets distributed across availability zones
- mapPublicIpOnLaunch DISABLED on redshift subnets
- Correct CIDR blocks assigned
- Proper tags applied (including Type="redshift")
- VPC ID selector uses matchControllerRef

Spec: This validates the REDSHIFT SUBNET feature implementation
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-subnets-redshift"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with redshift subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-redshift-subnets"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 redshift subnets
                    redshiftSubnets: ["10.0.50.0/24", "10.0.51.0/24"]
                    tags: {
                        Environment: "test"
                    }
                    redshiftSubnetTags: {
                        Tier: "redshift"
                    }
                }
            }

            # Spec: Assert that redshift subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-redshift-subnets"
                    }
                    spec: {
                        forProvider: {
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                        }
                    }
                },
                # Spec: Redshift subnet 1 in us-west-2a
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-redshift-test-redshift-subnets-us-west-2a"
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
                            # Spec: First redshift subnet CIDR
                            cidrBlock: "10.0.50.0/24"
                            # Spec: Redshift subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            # Spec: Tags should include base tags + redshiftSubnetTags + Type="redshift"
                            tags: {
                                Environment: "test"
                                Tier: "redshift"
                                Name: "subnet-redshift-test-redshift-subnets-us-west-2a"
                                Type: "redshift"
                            }
                        }
                    }
                },
                # Spec: Redshift subnet 2 in us-west-2b
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-redshift-test-redshift-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second redshift subnet CIDR
                            cidrBlock: "10.0.51.0/24"
                            # Spec: Redshift subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Tier: "redshift"
                                Name: "subnet-redshift-test-redshift-subnets-us-west-2b"
                                Type: "redshift"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
