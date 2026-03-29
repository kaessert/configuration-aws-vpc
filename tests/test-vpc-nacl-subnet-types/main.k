"""
Network ACL Composition Tests

Tests Network ACL functionality with various configurations:
- **disabled**: No dedicated NACLs created (default behavior)
- **public**: Public subnet NACLs with HTTP/HTTPS/SSH ports
- **database**: Database subnet NACLs with MySQL/PostgreSQL ports
- **elasticache**: ElastiCache subnet NACLs with Redis/Memcached ports
- **intra**: Intra subnet NACLs with VPC-only HTTPS
- **redshift**: Redshift subnet NACLs with Redshift port

Each test validates:
- Dedicated Network ACL resource creation (or absence)
- NetworkACL association with correct subnet type via labels
- Custom inbound/outbound ACL rules
- Additional tags for NACLs

Spec: This validates Task 3.2 - Network ACL support for all subnet types

Reference: terraform-aws-modules/terraform-aws-vpc, thoughts/TASKS.md Task 3.2
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

# Test 1: Database Subnet NACLs
_test_database = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-nacl-database"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-nacl-db"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                # Database subnets
                databaseSubnets: ["10.0.101.0/24", "10.0.102.0/24"]
                # Enable dedicated Network ACL for database subnets
                databaseDedicatedNetworkAcl: True
                # Inbound ACL rules for database subnets
                databaseInboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 3306
                        toPort: 3306
                    },
                    {
                        ruleNumber: 110
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 5432
                        toPort: 5432
                    }
                ]
                # Outbound ACL rules for database subnets
                databaseOutboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                    }
                ]
                # Additional tags for database ACLs
                databaseAclTags: {
                    Type: "database"
                    Tier: "data"
                }
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # VPC
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-nacl-db" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-nacl-db"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Database Subnet 1
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-database-test-nacl-db-us-west-2a-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.101.0/24"
                        tags: {
                            Name: "subnet-database-test-nacl-db-us-west-2a-0"
                            Type: "database"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Database Subnet 2
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-database-test-nacl-db-us-west-2b-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.102.0/24"
                        tags: {
                            Name: "subnet-database-test-nacl-db-us-west-2b-1"
                            Type: "database"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Database Network ACL
            ec2v1beta1.NetworkACL{
                metadata: { name: "nacl-database-test-nacl-db" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        subnetIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "database" }
                        }
                        tags: {
                            Name: "nacl-database-test-nacl-db"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "database"
                            Tier: "data"
                        }
                    }
                }
            },
            # Inbound ACL rule 100 (MySQL)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-database-in-100-test-nacl-db" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "database" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 3306
                        toPort: 3306
                        egress: False
                    }
                }
            },
            # Inbound ACL rule 110 (PostgreSQL)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-database-in-110-test-nacl-db" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "database" }
                        }
                        ruleNumber: 110
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 5432
                        toPort: 5432
                        egress: False
                    }
                }
            },
            # Outbound ACL rule 100
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-database-out-100-test-nacl-db" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "database" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                        egress: True
                    }
                }
            }
        ]
    }
}

# Test 2: ElastiCache Subnet NACLs
_test_elasticache = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-nacl-elasticache"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-nacl-ec"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                # ElastiCache subnets
                elasticacheSubnets: ["10.0.201.0/24", "10.0.202.0/24"]
                # Enable dedicated Network ACL for ElastiCache subnets
                elasticacheDedicatedNetworkAcl: True
                # Inbound ACL rules for ElastiCache subnets
                elasticacheInboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 6379
                        toPort: 6379
                    },
                    {
                        ruleNumber: 110
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 11211
                        toPort: 11211
                    }
                ]
                # Outbound ACL rules for ElastiCache subnets
                elasticacheOutboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                    }
                ]
                # Additional tags for ElastiCache ACLs
                elasticacheAclTags: {
                    Type: "elasticache"
                    Tier: "cache"
                }
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # VPC
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-nacl-ec" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-nacl-ec"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # ElastiCache Subnet 1
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-elasticache-test-nacl-ec-us-west-2a-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.201.0/24"
                        tags: {
                            Name: "subnet-elasticache-test-nacl-ec-us-west-2a-0"
                            Type: "elasticache"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # ElastiCache Subnet 2
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-elasticache-test-nacl-ec-us-west-2b-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.202.0/24"
                        tags: {
                            Name: "subnet-elasticache-test-nacl-ec-us-west-2b-1"
                            Type: "elasticache"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # ElastiCache Network ACL
            ec2v1beta1.NetworkACL{
                metadata: { name: "nacl-elasticache-test-nacl-ec" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        subnetIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "elasticache" }
                        }
                        tags: {
                            Name: "nacl-elasticache-test-nacl-ec"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "elasticache"
                            Tier: "cache"
                        }
                    }
                }
            },
            # Inbound ACL rule 100 (Redis)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-elasticache-in-100-test-nacl-ec" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "elasticache" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 6379
                        toPort: 6379
                        egress: False
                    }
                }
            },
            # Inbound ACL rule 110 (Memcached)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-elasticache-in-110-test-nacl-ec" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "elasticache" }
                        }
                        ruleNumber: 110
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 11211
                        toPort: 11211
                        egress: False
                    }
                }
            },
            # Outbound ACL rule 100
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-elasticache-out-100-test-nacl-ec" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "elasticache" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                        egress: True
                    }
                }
            }
        ]
    }
}

# Test 3: Intra Subnet NACLs
_test_intra = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-nacl-intra"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-nacl-intra"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                # Intra subnets (isolated)
                intraSubnets: ["10.0.51.0/24", "10.0.52.0/24"]
                # Enable dedicated Network ACL for intra subnets
                intraDedicatedNetworkAcl: True
                # Inbound ACL rules for intra subnets
                intraInboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 443
                        toPort: 443
                    }
                ]
                # Outbound ACL rules for intra subnets
                intraOutboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 443
                        toPort: 443
                    }
                ]
                # Additional tags for intra ACLs
                intraAclTags: {
                    Type: "intra"
                    Tier: "isolated"
                }
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # VPC
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-nacl-intra" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-nacl-intra"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Intra Subnet 1
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-intra-test-nacl-intra-us-west-2a-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.51.0/24"
                        tags: {
                            Name: "subnet-intra-test-nacl-intra-us-west-2a-0"
                            Type: "intra"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Intra Subnet 2
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-intra-test-nacl-intra-us-west-2b-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.52.0/24"
                        tags: {
                            Name: "subnet-intra-test-nacl-intra-us-west-2b-1"
                            Type: "intra"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Intra Network ACL
            ec2v1beta1.NetworkACL{
                metadata: { name: "nacl-intra-test-nacl-intra" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        subnetIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "intra" }
                        }
                        tags: {
                            Name: "nacl-intra-test-nacl-intra"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "intra"
                            Tier: "isolated"
                        }
                    }
                }
            },
            # Inbound ACL rule 100 (HTTPS)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-intra-in-100-test-nacl-intra" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "intra" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 443
                        toPort: 443
                        egress: False
                    }
                }
            },
            # Outbound ACL rule 100 (HTTPS)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-intra-out-100-test-nacl-intra" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "intra" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 443
                        toPort: 443
                        egress: True
                    }
                }
            }
        ]
    }
}

# Test 4: Redshift Subnet NACLs
_test_redshift = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-nacl-redshift"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-nacl-rs"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                # Redshift subnets
                redshiftSubnets: ["10.0.151.0/24", "10.0.152.0/24"]
                # Enable dedicated Network ACL for Redshift subnets
                redshiftDedicatedNetworkAcl: True
                # Inbound ACL rules for Redshift subnets
                redshiftInboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 5439
                        toPort: 5439
                    }
                ]
                # Outbound ACL rules for Redshift subnets
                redshiftOutboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                    }
                ]
                # Additional tags for Redshift ACLs
                redshiftAclTags: {
                    Type: "redshift"
                    Tier: "analytics"
                }
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # VPC
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-nacl-rs" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        cidrBlock: "10.0.0.0/16"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Name: "test-nacl-rs"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Redshift Subnet 1
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-redshift-test-nacl-rs-us-west-2a-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.151.0/24"
                        tags: {
                            Name: "subnet-redshift-test-nacl-rs-us-west-2a-0"
                            Type: "redshift"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Redshift Subnet 2
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-redshift-test-nacl-rs-us-west-2b-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.152.0/24"
                        tags: {
                            Name: "subnet-redshift-test-nacl-rs-us-west-2b-1"
                            Type: "redshift"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Redshift Network ACL
            ec2v1beta1.NetworkACL{
                metadata: { name: "nacl-redshift-test-nacl-rs" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        vpcIdSelector: { matchControllerRef: True }
                        subnetIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "redshift" }
                        }
                        tags: {
                            Name: "nacl-redshift-test-nacl-rs"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "redshift"
                            Tier: "analytics"
                        }
                    }
                }
            },
            # Inbound ACL rule 100 (Redshift)
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-redshift-in-100-test-nacl-rs" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "redshift" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 5439
                        toPort: 5439
                        egress: False
                    }
                }
            },
            # Outbound ACL rule 100
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-redshift-out-100-test-nacl-rs" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "redshift" }
                        }
                        ruleNumber: 100
                        protocol: "6"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 1024
                        toPort: 65535
                        egress: True
                    }
                }
            }
        ]
    }
}

# Test 5: NACLs Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest{
    metadata.name: "test-nacl-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nacl-disabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: No dedicated NACL flags set (default: false)
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "network-acls-disabled"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nacl-disabled" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "network-acls-disabled"
                            Name: "test-vpc-nacl-disabled"
                        }
                    }
                }
            }
            # Spec: NO NetworkACL resources should be created
            # Spec: NO NetworkACLRule resources should be created
            # (AWS default NACL will be used automatically)
        ]
    }
}

# Test 6: Public Subnet Dedicated NACL
_test_public = metav1alpha1.CompositionTest{
    metadata.name: "test-nacl-public-dedicated"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nacl-public"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: Enable dedicated NACL for public subnets
                publicDedicatedNetworkAcl: True
                # Spec: Custom inbound rules for public subnets
                publicInboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 80
                        toPort: 80
                    },
                    {
                        ruleNumber: 110
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 443
                        toPort: 443
                    },
                    {
                        ruleNumber: 120
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 22
                        toPort: 22
                    }
                ]
                # Spec: Custom outbound rules for public subnets
                publicOutboundAclRules: [
                    {
                        ruleNumber: 100
                        protocol: "-1"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 0
                        toPort: 0
                    }
                ]
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "network-acls"
                }
                publicAclTags: {
                    Type: "public-nacl"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nacl-public" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "network-acls"
                            Name: "test-vpc-nacl-public"
                        }
                    }
                }
            },
            # Spec: Dedicated NACL should be created for public subnets
            ec2v1beta1.NetworkACL{
                metadata: {
                    name: "nacl-public-test-vpc-nacl-public"
                    labels: { "subnet-type": "public" }
                }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: NACL attached to VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: NACL associated with public subnets via labels
                        subnetIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "public" }
                        }
                        # Spec: Correct tags applied
                        tags: {
                            Environment: "test"
                            Feature: "network-acls"
                            Type: "public-nacl"
                            Name: "nacl-public-test-vpc-nacl-public"
                        }
                    }
                }
            },
            # Spec: Inbound rule 100 - Allow HTTP
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-public-in-100-test-vpc-nacl-public" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "public" }
                        }
                        region: "us-west-2"
                        ruleNumber: 100
                        protocol: "6"  # TCP
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 80
                        toPort: 80
                        egress: False
                    }
                }
            },
            # Spec: Inbound rule 110 - Allow HTTPS
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-public-in-110-test-vpc-nacl-public" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "public" }
                        }
                        region: "us-west-2"
                        ruleNumber: 110
                        protocol: "6"  # TCP
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 443
                        toPort: 443
                        egress: False
                    }
                }
            },
            # Spec: Inbound rule 120 - Allow SSH
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-public-in-120-test-vpc-nacl-public" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "public" }
                        }
                        region: "us-west-2"
                        ruleNumber: 120
                        protocol: "6"  # TCP
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 22
                        toPort: 22
                        egress: False
                    }
                }
            },
            # Spec: Outbound rule 100 - Allow all
            ec2v1beta1.NetworkACLRule{
                metadata: { name: "nacl-rule-public-out-100-test-vpc-nacl-public" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        networkAclIdSelector: {
                            matchControllerRef: True
                            matchLabels: { "subnet-type": "public" }
                        }
                        region: "us-west-2"
                        ruleNumber: 100
                        protocol: "-1"  # All protocols
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        egress: True
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_public,
    _test_database,
    _test_elasticache,
    _test_intra,
    _test_redshift
]
