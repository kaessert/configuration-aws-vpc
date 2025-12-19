"""
Database Subnets Composition Test

Tests database subnet creation from terraform-vpc-analysis.md spec:
- Database subnets distributed across availability zones
- mapPublicIpOnLaunch DISABLED on database subnets
- Correct CIDR blocks assigned
- Proper tags applied (including Type="database")
- VPC ID selector uses matchControllerRef

Spec: This validates the DATABASE SUBNET feature implementation
"""

import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-subnets-database"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with database subnets across 2 AZs
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "XVPC"
                metadata: {
                    name: "test-database-subnets"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    # Spec: Create 2 database subnets
                    databaseSubnets: ["10.0.30.0/24", "10.0.31.0/24"]
                    tags: {
                        Environment: "test"
                    }
                    databaseSubnetTags: {
                        Tier: "database"
                    }
                }
            }

            # Spec: Assert that database subnets are created correctly
            assertResources: [
                # Spec: VPC resource should exist
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "VPC"
                    metadata: {
                        name: "vpc-test-database-subnets"
                    }
                },
                # Spec: Database subnet 1 in us-west-2a
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    metadata: {
                        name: "subnet-database-test-database-subnets-us-west-2a"
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
                            # Spec: First database subnet CIDR
                            cidrBlock: "10.0.30.0/24"
                            # Spec: Database subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            # Spec: Tags should include base tags + databaseSubnetTags + Type="database"
                            tags: {
                                Environment: "test"
                                Tier: "database"
                                Name: "subnet-database-test-database-subnets-us-west-2a"
                                Type: "database"
                            }
                        }
                    }
                },
                # Spec: Database subnet 2 in us-west-2b
                {
                    apiVersion: "ec2.aws.upbound.io/v1beta1"
                    kind: "Subnet"
                    metadata: {
                        name: "subnet-database-test-database-subnets-us-west-2b"
                    }
                    spec: {
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet distributed to second AZ
                            availabilityZone: "us-west-2b"
                            # Spec: Second database subnet CIDR
                            cidrBlock: "10.0.31.0/24"
                            # Spec: Database subnets MUST have mapPublicIpOnLaunch DISABLED
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Tier: "database"
                                Name: "subnet-database-test-database-subnets-us-west-2b"
                                Type: "database"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
