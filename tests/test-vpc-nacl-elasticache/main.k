"""
ElastiCache Subnet Network ACL Composition Test

Tests dedicated Network ACL creation for ElastiCache subnets:
- Dedicated Network ACL for ElastiCache subnets (elasticacheDedicatedNetworkAcl)
- Custom inbound ACL rules (elasticacheInboundAclRules)
- Custom outbound ACL rules (elasticacheOutboundAclRules)
- Additional tags for ElastiCache ACLs (elasticacheAclTags)

Spec: This validates that when elasticacheDedicatedNetworkAcl is enabled,
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
        metadata.name: "test-vpc-nacl-elasticache"
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
                    name: "test-nacl-ec"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]

                    # ElastiCache subnets
                    elasticacheSubnets: [
                        "10.0.201.0/24",  # us-west-2a
                        "10.0.202.0/24"   # us-west-2b
                    ]

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
                        name: "vpc-test-nacl-ec"
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
                                Name: "test-nacl-ec"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # ElastiCache Subnet 1 (us-west-2a)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-elasticache-test-nacl-ec-us-west-2a"
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
                            cidrBlock: "10.0.201.0/24"
                            tags: {
                                Name: "subnet-elasticache-test-nacl-ec-us-west-2a"
                                Type: "elasticache"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # ElastiCache Subnet 2 (us-west-2b)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-elasticache-test-nacl-ec-us-west-2b"
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
                            cidrBlock: "10.0.202.0/24"
                            tags: {
                                Name: "subnet-elasticache-test-nacl-ec-us-west-2b"
                                Type: "elasticache"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Spec: ElastiCache Network ACL should be created when elasticacheDedicatedNetworkAcl is true
                ec2v1beta1.NetworkACL{
                    metadata: {
                        name: "nacl-elasticache-test-nacl-ec"
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
                            # Spec: NetworkACL should associate with elasticache subnets via labels
                            subnetIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "elasticache"
                                }
                            }
                            # Spec: NetworkACL should have correct tags (base + elasticache ACL tags)
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
                # Spec: Inbound ACL rule 100 (Redis port)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-elasticache-in-100-test-nacl-ec"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: Rule should reference elasticache NetworkACL by labels
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "elasticache"
                                }
                            }
                            # Spec: Inbound rule configuration
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 6379
                            toPort: 6379
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Inbound ACL rule 110 (Memcached port)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-elasticache-in-110-test-nacl-ec"
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
                                    "subnet-type": "elasticache"
                                }
                            }
                            ruleNumber: 110
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 11211
                            toPort: 11211
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Outbound ACL rule 100 (ephemeral ports)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-elasticache-out-100-test-nacl-ec"
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
                                    "subnet-type": "elasticache"
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
