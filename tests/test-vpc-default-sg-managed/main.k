"""
Default Security Group Management Test

Tests default security group management when enabled:
- DefaultSecurityGroup resource is created
- References VPC via vpcIdSelector.matchControllerRef
- Ingress rules are EMPTY (security hardening - deny all inbound)
- Egress rules are EMPTY (security hardening - deny all outbound)
- Tags merged from common tags and defaultSecurityGroupTags

Spec: This validates Task 4.8 requirement - managing default security group
to lock down all traffic by removing default AWS rules.

Reference: terraform-aws-modules/terraform-aws-vpc manage_default_security_group
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
        metadata.name: "test-vpc-default-sg-managed"
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
                    name: "test-default-sg"
                    namespace: "default"
                }
                spec: {
                    # Core VPC config
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"

                    # Default Security Group Management
                    manageDefaultSecurityGroup: True

                    # Tags
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                    defaultSecurityGroupTags: {
                        Type: "default-security-group"
                        Hardened: "true"
                    }
                }
            }

            # Assert expected managed resources
            assertResources: [
                # VPC resource
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-default-sg"
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
                                Name: "test-default-sg"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },

                # Spec: Default Security Group should be managed
                ec2v1beta1.DefaultSecurityGroup{
                    metadata: {
                        name: "default-sg-test-default-sg"
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
                            # Spec: Default SG references VPC via controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }

                            # Spec: Resource should be in correct region
                            region: "us-west-2"

                            # Spec: Security hardening - NO ingress rules (deny all inbound)
                            ingress: []

                            # Spec: Security hardening - NO egress rules (deny all outbound)
                            egress: []

                            # Spec: Tags merged from common tags and defaultSecurityGroupTags
                            tags: {
                                Name: "test-default-sg-default-sg"
                                Environment: "test"
                                ManagedBy: "upbound"
                                Type: "default-security-group"
                                Hardened: "true"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
