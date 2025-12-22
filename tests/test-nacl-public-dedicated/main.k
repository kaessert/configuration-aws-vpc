"""
Network ACLs - Public Subnet Dedicated NACL Test

Tests dedicated Network ACL creation for public subnets with custom rules:
- VPC with public and private subnets
- Dedicated NACL created for public subnets
- Custom inbound rules applied
- Custom outbound rules applied
- NACL associated with public subnets only
- Correct tags applied

Spec: This validates Network ACLs (task 3.2) from TASKS.md
Verifies dedicated NACL creation based on terraform-aws-vpc module behavior
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-nacl-public-dedicated"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with dedicated NACL for public subnets
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

            # Assert that VPC, subnets, and dedicated public NACL are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nacl-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
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
                        labels: {
                            "subnet-type": "public"
                        }
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: NACL attached to VPC
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: NACL associated with public subnets via labels
                            subnetIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "public"
                                }
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
                    metadata: {
                        name: "nacl-rule-public-in-100-test-vpc-nacl-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "public"
                                }
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
                    metadata: {
                        name: "nacl-rule-public-in-110-test-vpc-nacl-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "public"
                                }
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
                    metadata: {
                        name: "nacl-rule-public-in-120-test-vpc-nacl-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "public"
                                }
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
                    metadata: {
                        name: "nacl-rule-public-out-100-test-vpc-nacl-public"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            networkAclIdSelector: {
                                matchControllerRef: True
                                matchLabels: {
                                    "subnet-type": "public"
                                }
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
]
items= _items
