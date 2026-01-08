"""
Intra Subnet Network ACL Composition Test

Tests dedicated Network ACL creation for intra subnets:
- Dedicated Network ACL for intra subnets (intraDedicatedNetworkAcl)
- Custom inbound ACL rules (intraInboundAclRules)
- Custom outbound ACL rules (intraOutboundAclRules)
- Additional tags for intra ACLs (intraAclTags)

Spec: This validates that when intraDedicatedNetworkAcl is enabled,
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
        metadata.name: "test-vpc-nacl-intra"
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
                    name: "test-nacl-intra"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]

                    # Intra subnets (isolated - no internet access)
                    intraSubnets: [
                        "10.0.51.0/24",  # us-west-2a
                        "10.0.52.0/24"   # us-west-2b
                    ]

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
                        name: "vpc-test-nacl-intra"
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
                                Name: "test-nacl-intra"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Intra Subnet 1 (us-west-2a)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-intra-test-nacl-intra-us-west-2a"
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
                            cidrBlock: "10.0.51.0/24"
                            tags: {
                                Name: "subnet-intra-test-nacl-intra-us-west-2a"
                                Type: "intra"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Intra Subnet 2 (us-west-2b)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-intra-test-nacl-intra-us-west-2b"
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
                            cidrBlock: "10.0.52.0/24"
                            tags: {
                                Name: "subnet-intra-test-nacl-intra-us-west-2b"
                                Type: "intra"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },
                # Spec: Intra Network ACL should be created when intraDedicatedNetworkAcl is true
                ec2v1beta1.NetworkACL{
                    metadata: {
                        name: "nacl-intra-test-nacl-intra"
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
                            # Spec: NetworkACL should associate with intra subnets via labels
                            subnetIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "intra"
                                }
                            }
                            # Spec: NetworkACL should have correct tags (base + intra ACL tags)
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
                # Spec: Inbound ACL rule 100 (HTTPS within VPC)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-intra-in-100-test-nacl-intra"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            # Spec: Rule should reference intra NetworkACL by labels
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "intra"
                                }
                            }
                            # Spec: Inbound rule configuration
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 443
                            toPort: 443
                            egress: False  # Inbound
                        }
                    }
                },
                # Spec: Outbound ACL rule 100 (HTTPS within VPC)
                ec2v1beta1.NetworkACLRule{
                    metadata: {
                        name: "nacl-rule-intra-out-100-test-nacl-intra"
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
                                    "subnet-type": "intra"
                                }
                            }
                            ruleNumber: 100
                            protocol: "6"  # TCP
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 443
                            toPort: 443
                            egress: True  # Outbound
                        }
                    }
                }
            ]
        }
    }
]
items= _items
