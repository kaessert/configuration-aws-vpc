"""
Subnet-Specific Routing Composition Tests

Tests routing configurations for specific subnet types with custom routing needs:
- **database-igw**: Database subnets with Internet Gateway route (public access)
- **elasticache-nat**: ElastiCache subnets with NAT Gateway route
- **redshift-nat**: Redshift subnets with NAT Gateway route
- **redshift-public**: Redshift subnets with public (IGW) route
- **intra-per-az**: Intra subnets with per-AZ route tables
- **public-per-az**: Public subnets with per-AZ route tables

Spec: This validates subnet-specific routing configurations

Reference: terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: Database Subnets with Internet Gateway Route
_test_database_igw = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-database-igw"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-database-igw"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                databaseSubnets: ["10.0.20.0/24", "10.0.21.0/24"]
                # Spec: Database subnets with public access via IGW
                createIgw: True
                createDatabaseSubnetRouteTable: True
                createDatabaseInternetGatewayRoute: True
                tags: {
                    Environment: "test"
                    Feature: "routes-database-igw"
                }
            }
        }
        assertResources: [
            # Spec: Internet Gateway
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-routes-database-igw" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate database route table
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-database-test-routes-database-igw" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to IGW for database subnets (WARNING: enables public access)
            ec2v1beta1.Route{
                metadata: { name: "route-database-igw-test-routes-database-igw" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "database" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-database-test-routes-database-igw-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "database" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "database", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-database-test-routes-database-igw-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "database" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "database", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 2: ElastiCache Subnets with NAT Gateway Route
_test_elasticache_nat = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-elasticache-nat"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-elasticache-nat"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                elasticacheSubnets: ["10.0.30.0/24", "10.0.31.0/24"]
                # Spec: ElastiCache subnets with NAT access
                enableNatGateway: True
                singleNatGateway: True
                createIgw: True
                createElasticacheSubnetRouteTable: True
                createElasticacheNatGatewayRoute: True
                tags: {
                    Environment: "test"
                    Feature: "routes-elasticache-nat"
                }
            }
        }
        assertResources: [
            # Spec: NAT Gateway
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-routes-elasticache-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "public", "az": "us-west-2a" }
                        }
                        allocationIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate elasticache route table
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-elasticache-test-routes-elasticache-nat" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to NAT for elasticache subnets
            ec2v1beta1.Route{
                metadata: { name: "route-elasticache-nat-test-routes-elasticache-nat" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "elasticache" }
                        }
                        natGatewayIdSelector: {
                            matchLabels: { "az": "us-west-2a" }
                        }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-elasticache-test-routes-elasticache-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "elasticache" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "elasticache", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-elasticache-test-routes-elasticache-nat-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "elasticache" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "elasticache", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 3: Redshift Subnets with NAT Gateway Route
_test_redshift_nat = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-redshift-nat"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-redshift-nat"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                redshiftSubnets: ["10.0.40.0/24", "10.0.41.0/24"]
                # Spec: Redshift subnets with NAT access
                enableNatGateway: True
                singleNatGateway: True
                createIgw: True
                createRedshiftSubnetRouteTable: True
                createRedshiftNatGatewayRoute: True
                tags: {
                    Environment: "test"
                    Feature: "routes-redshift-nat"
                }
            }
        }
        assertResources: [
            # Spec: NAT Gateway
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-routes-redshift-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "public", "az": "us-west-2a" }
                        }
                        allocationIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate redshift route table
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-redshift-test-routes-redshift-nat" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to NAT for redshift subnets
            ec2v1beta1.Route{
                metadata: { name: "route-redshift-nat-test-routes-redshift-nat" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "redshift" }
                        }
                        natGatewayIdSelector: {
                            matchLabels: { "az": "us-west-2a" }
                        }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-redshift-test-routes-redshift-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "redshift" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "redshift", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-redshift-test-routes-redshift-nat-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "redshift" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "redshift", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 4: Redshift Subnets with Public (IGW) Route
_test_redshift_public = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-redshift-public"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-redshift-public"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                redshiftSubnets: ["10.0.40.0/24", "10.0.41.0/24"]
                # Spec: Redshift subnets with public access via IGW
                createIgw: True
                createRedshiftPublicSubnetRouteTable: True
                enablePublicRedshift: True
                tags: {
                    Environment: "test"
                    Feature: "routes-redshift-public"
                }
            }
        }
        assertResources: [
            # Spec: Internet Gateway
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-routes-redshift-public" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate redshift public route table
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-redshift-public-test-routes-redshift-public" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to IGW for redshift subnets (public access)
            ec2v1beta1.Route{
                metadata: { name: "route-redshift-public-igw-test-routes-redshift-public" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "redshift-public" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-redshift-public-test-routes-redshift-public-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "redshift-public" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "redshift", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-redshift-public-test-routes-redshift-public-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "redshift-public" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "redshift", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 5: Intra Subnets with Per-AZ Route Tables
_test_intra_per_az = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-intra-per-az"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-intra-per-az"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                intraSubnets: ["10.0.50.0/24", "10.0.51.0/24"]
                # Spec: One intra route table per AZ for enhanced isolation
                oneIntraRouteTablePerAz: True
                createIgw: False
                enableNatGateway: False
                tags: {
                    Environment: "test"
                    Feature: "routes-intra-per-az"
                }
            }
        }
        assertResources: [
            # Spec: Separate intra route table per AZ
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-intra-test-routes-intra-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-intra-test-routes-intra-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route table associations (per AZ)
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-intra-test-routes-intra-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "intra", "az": "us-west-2a" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "intra", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-intra-test-routes-intra-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "intra", "az": "us-west-2b" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "intra", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
            # Spec: NO external routes (isolated subnets)
        ]
    }
}

# Test 6: Public Subnets with Per-AZ Route Tables
_test_public_per_az = metav1alpha1.CompositionTest {
    metadata.name: "test-routes-public-per-az"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-routes-public-per-az"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                # Spec: One public route table per AZ
                onePublicRouteTablePerAz: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "routes-public-per-az"
                }
            }
        }
        assertResources: [
            # Spec: Internet Gateway
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-routes-public-per-az" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate public route table per AZ
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-public-test-routes-public-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-public-test-routes-public-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Routes to IGW (one per AZ)
            ec2v1beta1.Route{
                metadata: { name: "route-public-igw-test-routes-public-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public", "az": "us-west-2a" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            ec2v1beta1.Route{
                metadata: { name: "route-public-igw-test-routes-public-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public", "az": "us-west-2b" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations (per AZ)
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-public-test-routes-public-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "public", "az": "us-west-2a" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "public", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-public-test-routes-public-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "public", "az": "us-west-2b" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "public", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

items = [
    _test_database_igw,
    _test_elasticache_nat,
    _test_redshift_nat,
    _test_redshift_public,
    _test_intra_per_az,
    _test_public_per_az
]
