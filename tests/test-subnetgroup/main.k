"""
Subnet Group Composition Tests

Tests Subnet Group creation for various database services:
- **db**: RDS DB Subnet Group
- **elasticache**: ElastiCache Subnet Group
- **redshift**: Redshift Subnet Group

Spec: This validates Task 3.5 - Subnet Group resources implementation

Reference: thoughts/TASKS.md Task 3.5, terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.rds.v1beta1 as rdsv1beta1
import models.io.upbound.awsm.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.awsm.redshift.v1beta1 as redshiftv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: False
}

# Test 1: DB Subnet Group
_test_db = metav1alpha1.CompositionTest {
    metadata.name: "test-subnetgroup-db"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-subnetgroup-db"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                databaseSubnets: ["10.0.21.0/24", "10.0.22.0/24"]
                # Spec: Enable DB Subnet Group creation
                createDatabaseSubnetGroup: True
                tags: {
                    Name: "test-vpc-subnetgroup-db"
                    Type: "database"
                }
            }
        }
        assertResources: [
            # Spec: Verify DB Subnet Group is created
            rdsv1beta1.SubnetGroup{
                metadata: { name: "test-vpc-subnetgroup-db-db" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        # Spec: Verify subnet selector matches database subnets
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "database" }
                            matchControllerRef: True
                        }
                        # Spec: Verify tags are applied
                        tags: {
                            Name: "test-vpc-subnetgroup-db-db"
                            Type: "database"
                        }
                    }
                }
            }
        ]
    }
}

# Test 2: ElastiCache Subnet Group
_test_elasticache = metav1alpha1.CompositionTest {
    metadata.name: "test-subnetgroup-elasticache"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-subnetgroup-elasticache"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                elasticacheSubnets: ["10.0.31.0/24", "10.0.32.0/24"]
                # Spec: Enable ElastiCache Subnet Group creation
                createElasticacheSubnetGroup: True
                tags: {
                    Name: "test-vpc-subnetgroup-elasticache"
                    Type: "elasticache"
                }
            }
        }
        assertResources: [
            # Spec: Verify ElastiCache Subnet Group is created
            elasticachev1beta1.SubnetGroup{
                metadata: { name: "test-vpc-subnetgroup-elasticache-elasticache" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        # Spec: Verify subnet selector matches elasticache subnets
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "elasticache" }
                            matchControllerRef: True
                        }
                        # Spec: Verify tags are applied
                        tags: {
                            Name: "test-vpc-subnetgroup-elasticache-elasticache"
                            Type: "elasticache"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: Redshift Subnet Group
_test_redshift = metav1alpha1.CompositionTest {
    metadata.name: "test-subnetgroup-redshift"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-subnetgroup-redshift"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                redshiftSubnets: ["10.0.41.0/24", "10.0.42.0/24"]
                # Spec: Enable Redshift Subnet Group creation
                createRedshiftSubnetGroup: True
                tags: {
                    Name: "test-vpc-subnetgroup-redshift"
                    Type: "redshift"
                }
            }
        }
        assertResources: [
            # Spec: Verify Redshift Subnet Group is created
            redshiftv1beta1.SubnetGroup{
                metadata: { name: "test-vpc-subnetgroup-redshift-redshift" }
                spec: {
                    forProvider: {
                        region: "us-west-2"
                        # Spec: Verify subnet selector matches redshift subnets
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "redshift" }
                            matchControllerRef: True
                        }
                        # Spec: Verify tags are applied
                        tags: {
                            Name: "test-vpc-subnetgroup-redshift-redshift"
                            Type: "redshift"
                        }
                    }
                }
            }
        ]
    }
}

items = [
    _test_db,
    _test_elasticache,
    _test_redshift
]
