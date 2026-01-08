"""
Redshift Subnet Network ACL Composition Test

Tests dedicated Network ACL creation for Redshift subnets:
- Dedicated Network ACL for Redshift subnets (redshiftDedicatedNetworkAcl)
- Custom inbound ACL rules (redshiftInboundAclRules)
- Custom outbound ACL rules (redshiftOutboundAclRules)
- Additional tags for Redshift ACLs (redshiftAclTags)

Spec: This validates that when redshiftDedicatedNetworkAcl is enabled,
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
        metadata.name: "test-vpc-nacl-redshift"
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
                    name: "test-nacl-rs"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]

                    # Redshift subnets
                    redshiftSubnets: [
                        "10.0.151.0/24",  # us-west-2a
                        "10.0.152.0/24"   # us-west-2b
                    ]

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
                        name: "vpc-test-nacl-rs"
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
                                Name: "test-nacl-rs"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Redshift Subnet 1 (us-west-2a)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-redshift-test-nacl-rs-us-west-2a"
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
                            cidrBlock: "10.0.151.0/24"
                            tags: {
                                Name: "subnet-redshift-test-nacl-rs-us-west-2a"
                                Type: "redshift"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Redshift Subnet 2 (us-west-2b)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-redshift-test-nacl-rs-us-west-2b"
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
                            cidrBlock: "10.0.152.0/24"
                            tags: {
                                Name: "subnet-redshift-test-nacl-rs-us-west-2b"
                                Type: "redshift"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Spec: Redshift Network ACL should be created when redshiftDedicatedNetworkAcl is true
                ec2v1beta1.NetworkACL{
                    metadata: {
                        name: "nacl-redshift-test-nacl-rs"
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
                            # Spec: NetworkACL should associate with redshift subnets via labels
                            subnetIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "redshift"
                                }
                            }
                            # Spec: NetworkACL should have correct tags (base + redshift ACL tags)
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
                # Spec: Inbound ACL rule 100 (Redshift port)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-redshift-in-100-test-nacl-rs"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: Rule should reference redshift NetworkACL by labels
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "redshift"
                                }
                            }
                            # Spec: Inbound rule configuration
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 5439
                            toPort: 5439
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Outbound ACL rule 100 (ephemeral ports)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-redshift-out-100-test-nacl-rs"
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
                                    "subnet-type": "redshift"
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
