"""
Default Network ACL Management Test

Tests default Network ACL management when enabled:
- DefaultNetworkACL resource is created
- References VPC via vpcIdSelector.matchControllerRef
- Custom ingress rules from defaultNetworkAclIngressRules
- Custom egress rules from defaultNetworkAclEgressRules
- Tags merged from common tags and defaultNetworkAclTags

Spec: This validates Task 4.8 requirement - managing default Network ACL
with explicit rules for enhanced network security.

Reference: terraform-aws-modules/terraform-aws-vpc manage_default_network_acl
"""

import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as cloudwatchlogsv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1
import models.io.upbound.awsm.rds.v1beta1 as rdsv1beta1
import models.io.upbound.awsm.redshift.v1beta1 as redshiftv1beta1
import models.io.upbound.awsm.s3.v1beta1 as s3v1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-default-nacl-managed"
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
                    name: "test-default-nacl"
                    namespace: "default"
                }
                spec: {
                    # Core VPC config
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"

                    # Default Network ACL Management
                    manageDefaultNetworkAcl: True

                    # Custom NACL rules
                    defaultNetworkAclIngressRules: [
                        {
                            ruleNumber: 100
                            protocol: "tcp"
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 443
                            toPort: 443
                        },
                        {
                            ruleNumber: 110
                            protocol: "tcp"
                            ruleAction: "allow"
                            cidrBlock: "10.0.0.0/16"
                            fromPort: 80
                            toPort: 80
                        }
                    ]
                    defaultNetworkAclEgressRules: [
                        {
                            ruleNumber: 100
                            protocol: "tcp"
                            ruleAction: "allow"
                            cidrBlock: "0.0.0.0/0"
                            fromPort: 443
                            toPort: 443
                        },
                        {
                            ruleNumber: 110
                            protocol: "tcp"
                            ruleAction: "allow"
                            cidrBlock: "0.0.0.0/0"
                            fromPort: 80
                            toPort: 80
                        }
                    ]

                    # Tags
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                    defaultNetworkAclTags: {
                        Type: "default-network-acl"
                        Managed: "true"
                    }
                }
            }

            # Assert expected managed resources
            assertResources: [
                # VPC resource
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-default-nacl"
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
                                Name: "test-default-nacl"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },

                # Spec: Default Network ACL should be managed
                ec2v1beta1.DefaultNetworkACL{
                    metadata: {
                        name: "default-nacl-test-default-nacl"
                    }
                    spec: {
                        # Spec: Crossplane v2 requires kind in providerConfigRef
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # Spec: Crossplane v2 uses managementPolicies
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Default NACL references VPC via controller ref
                            defaultNetworkAclIdSelector: {
                                matchControllerRef: True
                            }

                            # Spec: Resource should be in correct region
                            region: "us-west-2"

                            # Spec: Custom ingress rules
                            ingress: [
                                {
                                    ruleNo: 100
                                    protocol: "6"  # TCP
                                    action: "allow"
                                    cidrBlock: "10.0.0.0/16"
                                    fromPort: 443
                                    toPort: 443
                                },
                                {
                                    ruleNo: 110
                                    protocol: "6"  # TCP
                                    action: "allow"
                                    cidrBlock: "10.0.0.0/16"
                                    fromPort: 80
                                    toPort: 80
                                }
                            ]

                            # Spec: Custom egress rules
                            egress: [
                                {
                                    ruleNo: 100
                                    protocol: "6"  # TCP
                                    action: "allow"
                                    cidrBlock: "0.0.0.0/0"
                                    fromPort: 443
                                    toPort: 443
                                },
                                {
                                    ruleNo: 110
                                    protocol: "6"  # TCP
                                    action: "allow"
                                    cidrBlock: "0.0.0.0/0"
                                    fromPort: 80
                                    toPort: 80
                                }
                            ]

                            # Spec: Tags merged from common tags and defaultNetworkAclTags
                            tags: {
                                Name: "test-default-nacl-default-nacl"
                                Environment: "test"
                                ManagedBy: "upbound"
                                Type: "default-network-acl"
                                Managed: "true"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
