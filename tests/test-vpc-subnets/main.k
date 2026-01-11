"""
VPC Subnets Composition Tests (Parameterized)

Tests subnet creation for all subnet types using shared base specification:
- **database**: Database subnets (mapPublicIpOnLaunch: False)
- **elasticache**: ElastiCache subnets (mapPublicIpOnLaunch: False)
- **intra**: Intra subnets - isolated, no internet access (mapPublicIpOnLaunch: False)
- **private**: Private subnets (mapPublicIpOnLaunch: False)
- **public**: Public subnets (mapPublicIpOnLaunch: True)
- **redshift**: Redshift subnets (mapPublicIpOnLaunch: False)

All tests validate:
- Subnets distributed across availability zones
- Correct CIDR blocks assigned
- Proper mapPublicIpOnLaunch setting
- VPC ID selector uses matchControllerRef
- Correct tags applied (base + type-specific + Type tag)

Spec: This validates subnet type implementations from terraform-vpc-analysis.md

Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: Database subnets
_test_database = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-database"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-database-subnets"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                databaseSubnets: ["10.0.30.0/24", "10.0.31.0/24"]
                tags: { Environment: "test" }
                databaseSubnetTags: { Tier: "database" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-database-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-database-test-database-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.30.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Tier: "database"
                            Name: "subnet-database-test-database-subnets-us-west-2a"
                            Type: "database"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-database-test-database-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.31.0/24"
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

# Test 2: ElastiCache subnets
_test_elasticache = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-elasticache"
    spec: {
        **_baseSpec
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
                elasticacheSubnets: ["10.0.40.0/24", "10.0.41.0/24"]
                tags: { Environment: "test" }
                elasticacheSubnetTags: { Tier: "elasticache" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-elasticache-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-elasticache-test-elasticache-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.40.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Tier: "elasticache"
                            Name: "subnet-elasticache-test-elasticache-subnets-us-west-2a"
                            Type: "elasticache"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-elasticache-test-elasticache-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.41.0/24"
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

# Test 3: Intra subnets
_test_intra = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-intra"
    spec: {
        **_baseSpec
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
                intraSubnets: ["10.0.60.0/24", "10.0.61.0/24"]
                tags: { Environment: "test" }
                intraSubnetTags: { Tier: "intra" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-intra-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-intra-test-intra-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.60.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Tier: "intra"
                            Name: "subnet-intra-test-intra-subnets-us-west-2a"
                            Type: "intra"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-intra-test-intra-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.61.0/24"
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

# Test 4: Private subnets
_test_private = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-private"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-private-subnets"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                privateSubnets: ["10.0.20.0/24", "10.0.21.0/24"]
                tags: { Environment: "test" }
                privateSubnetTags: { Tier: "private" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-private-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-private-test-private-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.20.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Tier: "private"
                            Name: "subnet-private-test-private-subnets-us-west-2a"
                            Type: "private"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-private-test-private-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.21.0/24"
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

# Test 5: Public subnets
_test_public = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-public"
    spec: {
        **_baseSpec
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
                publicSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                mapPublicIpOnLaunch: True
                tags: { Environment: "test" }
                publicSubnetTags: { Tier: "public" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-public-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-public-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.10.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Tier: "public"
                            Name: "subnet-public-test-public-subnets-us-west-2a"
                            Type: "public"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-public-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.11.0/24"
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

# Test 6: Redshift subnets
_test_redshift = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-subnets-redshift"
    spec: {
        **_baseSpec
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
                redshiftSubnets: ["10.0.50.0/24", "10.0.51.0/24"]
                tags: { Environment: "test" }
                redshiftSubnetTags: { Tier: "redshift" }
            }
        }
        assertResources: [
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-redshift-subnets" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-redshift-test-redshift-subnets-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.50.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Tier: "redshift"
                            Name: "subnet-redshift-test-redshift-subnets-us-west-2a"
                            Type: "redshift"
                        }
                    }
                }
            },
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-redshift-test-redshift-subnets-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.51.0/24"
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

items = [
    _test_database,
    _test_elasticache,
    _test_intra,
    _test_private,
    _test_public,
    _test_redshift
]
