"""
Database Subnet Network ACL Composition Test

Tests dedicated Network ACL creation for database subnets:
- Dedicated Network ACL for database subnets (databaseDedicatedNetworkAcl)
- Custom inbound ACL rules (databaseInboundAclRules)
- Custom outbound ACL rules (databaseOutboundAclRules)
- Additional tags for database ACLs (databaseAclTags)

Spec: This validates that when databaseDedicatedNetworkAcl is enabled,
the composition generates a NetworkACL resource with correct selectors
and NetworkACLRule resources for all configured inbound/outbound rules.

Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-nacl-database"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-nacl-db"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]

                    # Database subnets
                    databaseSubnets: [
                        "10.0.101.0/24",  # us-west-2a
                        "10.0.102.0/24"   # us-west-2b
                    ]

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

                    # Tags
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                }
            }

            # Assert expected managed resources
            assertResources: [
                # VPC
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-nacl-db"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
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
                # Database Subnet 1 (us-west-2a)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-database-test-nacl-db-us-west-2a"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            availabilityZone: "us-west-2a"
                            cidrBlock: "10.0.101.0/24"
                            tags: {
                                Name: "subnet-database-test-nacl-db-us-west-2a"
                                Type: "database"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Database Subnet 2 (us-west-2b)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-database-test-nacl-db-us-west-2b"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            availabilityZone: "us-west-2b"
                            cidrBlock: "10.0.102.0/24"
                            tags: {
                                Name: "subnet-database-test-nacl-db-us-west-2b"
                                Type: "database"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Spec: Database Network ACL should be created when databaseDedicatedNetworkAcl is true
                ec2v1beta1.NetworkACL{
                    metadata: {
                        name: "nacl-database-test-nacl-db"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: NetworkACL should reference VPC by controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            # Spec: NetworkACL should associate with database subnets via labels
                            subnetIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "database"
                                }
                            }
                            # Spec: NetworkACL should have correct tags (base + database ACL tags)
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
                # Spec: Inbound ACL rule 100 (MySQL port)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-database-in-100-test-nacl-db"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: Rule should reference database NetworkACL by labels
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "database"
                                }
                            }
                            # Spec: Inbound rule configuration
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 3306
                            toPort: 3306
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Inbound ACL rule 110 (PostgreSQL port)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-database-in-110-test-nacl-db"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "database"
                                }
                            }
                            ruleNumber: 110
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 5432
                            toPort: 5432
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Outbound ACL rule 100 (ephemeral ports)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-database-out-100-test-nacl-db"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "database"
                                }
                            }
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "0.0.0.0/0"
                            fromPort: 1024
                            toPort: 65535
                            egress: True  # Outbound
                        }
                    }
                }
            ]
        }
    }
]
items= _items
