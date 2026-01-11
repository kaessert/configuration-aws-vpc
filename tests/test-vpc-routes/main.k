"""
VPC Routing Composition Tests

Tests VPC routing configurations for different subnet types:
- **public**: Public subnets with Internet Gateway
- **private-single-nat**: Private subnets with single shared NAT Gateway
- **private-per-az**: Private subnets with NAT Gateway per AZ (high availability)
- **database-nat**: Database subnets with NAT Gateway access
- **isolated**: Isolated (intra) subnets with no external connectivity

Spec: This validates task 2.5.1 - VPC routing configurations

Reference: terraform-vpc-analysis.md, terraform-aws-modules/terraform-aws-vpc
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

# Test 1: Public Route Table
_test_public = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-routes-public"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-routes-public"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "routes-public"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-routes-public" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                    }
                }
            },
            # Spec: Internet Gateway
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-routes-public" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Public route table (shared across all public subnets)
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-public-test-vpc-routes-public" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to Internet Gateway (0.0.0.0/0 → IGW)
            ec2v1beta1.Route{
                metadata: { name: "route-public-igw-test-vpc-routes-public" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "public" }
                        }
                        gatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations for all 3 public subnets
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-public-test-vpc-routes-public-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "public" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "public", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-public-test-vpc-routes-public-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "public" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "public", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-public-test-vpc-routes-public-us-west-2c" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "public" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "public", "az": "us-west-2c" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 2: Private Route Table with Single NAT Gateway
_test_private_single_nat = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-routes-private-single-nat"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-routes-private-single-nat"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                # Spec: Single NAT Gateway for cost optimization
                enableNatGateway: True
                singleNatGateway: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "routes-private-single-nat"
                }
            }
        }
        assertResources: [
            # Spec: NAT Gateway in first AZ
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-routes-private-single-nat-us-west-2a" }
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
            # Spec: Single private route table (shared across all private subnets)
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-private-test-vpc-routes-private-single-nat" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to NAT Gateway (0.0.0.0/0 → NAT)
            ec2v1beta1.Route{
                metadata: { name: "route-private-nat-test-vpc-routes-private-single-nat" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                        }
                        natGatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations for all 3 private subnets
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "private" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "private", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "private" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "private", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-private-test-vpc-routes-private-single-nat-us-west-2c" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "private" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "private", "az": "us-west-2c" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 3: Private Route Tables with NAT per AZ (High Availability)
_test_private_per_az = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-routes-private-per-az"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-routes-private-per-az"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: NAT Gateway per AZ for high availability
                enableNatGateway: True
                oneNatGatewayPerAz: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "routes-private-per-az"
                }
            }
        }
        assertResources: [
            # Spec: NAT Gateways for both AZs
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-routes-private-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "public", "az": "us-west-2a" }
                        }
                        allocationIdSelector: { matchLabels: { "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-routes-private-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: { "subnet-type": "public", "az": "us-west-2b" }
                        }
                        allocationIdSelector: { matchLabels: { "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Separate route table per AZ
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-private-test-vpc-routes-private-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-private-test-vpc-routes-private-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Routes to NAT Gateways (one per AZ)
            ec2v1beta1.Route{
                metadata: { name: "route-private-nat-test-vpc-routes-private-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private", "az": "us-west-2a" }
                        }
                        natGatewayIdSelector: { matchLabels: { "az": "us-west-2a" } }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            ec2v1beta1.Route{
                metadata: { name: "route-private-nat-test-vpc-routes-private-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private", "az": "us-west-2b" }
                        }
                        natGatewayIdSelector: { matchLabels: { "az": "us-west-2b" } }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations (one per AZ)
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-private-test-vpc-routes-private-per-az-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "private", "az": "us-west-2a" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "private", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-private-test-vpc-routes-private-per-az-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "private", "az": "us-west-2b" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "private", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 4: Database Subnets with NAT Route Table
_test_database_nat = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-routes-database-nat"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-routes-database-nat"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                databaseSubnets: ["10.0.20.0/24", "10.0.21.0/24"]
                # Spec: Enable NAT Gateway for database subnet internet access
                enableNatGateway: True
                singleNatGateway: True
                createIgw: True
                # Spec: Create separate route table for database subnets
                createDatabaseSubnetRouteTable: True
                # Spec: Add route to NAT Gateway for database subnets
                createDatabaseNatGatewayRoute: True
                tags: {
                    Environment: "test"
                    Feature: "routes-database-nat"
                }
            }
        }
        assertResources: [
            # Spec: NAT Gateway for database routing
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-routes-database-nat-us-west-2a" }
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
            # Spec: Separate database route table
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-database-test-vpc-routes-database-nat" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route to NAT Gateway for database subnets
            ec2v1beta1.Route{
                metadata: { name: "route-database-nat-test-vpc-routes-database-nat" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "database" }
                        }
                        natGatewayIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        destinationCidrBlock: "0.0.0.0/0"
                    }
                }
            },
            # Spec: Route table associations for database subnets
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-database-test-vpc-routes-database-nat-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "database" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "database", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-database-test-vpc-routes-database-nat-us-west-2b" }
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

# Test 5: Isolated (Intra) Route Table
_test_isolated = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-routes-isolated"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-routes-isolated"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                # Spec: Only intra subnets (no public, no private with NAT)
                intraSubnets: ["10.0.50.0/24", "10.0.51.0/24"]
                # Spec: No IGW or NAT Gateway
                createIgw: False
                enableNatGateway: False
                tags: {
                    Environment: "test"
                    Feature: "routes-isolated"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-routes-isolated" }
                spec: {
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                    }
                }
            },
            # Spec: Intra subnet in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-intra-test-vpc-routes-isolated-us-west-2a" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.50.0/24"
                        mapPublicIpOnLaunch: False
                    }
                }
            },
            # Spec: Isolated route table (shared across all intra subnets, no external routes)
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-intra-test-vpc-routes-isolated" }
                spec: {
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                    }
                }
            },
            # Spec: Route table associations for intra subnets
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-intra-test-vpc-routes-isolated-us-west-2a" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "intra" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "intra", "az": "us-west-2a" } }
                        region: "us-west-2"
                    }
                }
            },
            ec2v1beta1.RouteTableAssociation{
                metadata: { name: "rtb-assoc-intra-test-vpc-routes-isolated-us-west-2b" }
                spec: {
                    forProvider: {
                        routeTableIdSelector: { matchLabels: { "route-table-type": "intra" } }
                        subnetIdSelector: { matchLabels: { "subnet-type": "intra", "az": "us-west-2b" } }
                        region: "us-west-2"
                    }
                }
            }
            # Spec: NO Route resources for intra subnets (only local VPC routing, automatic in AWS)
        ]
    }
}

items = [
    _test_public,
    _test_private_single_nat,
    _test_private_per_az,
    _test_database_nat,
    _test_isolated
]
