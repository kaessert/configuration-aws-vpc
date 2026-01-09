"""
Default Security Group Disabled Test

Tests default security group management when DISABLED (default behavior):
- NO DefaultSecurityGroup resource is created
- VPC uses AWS default security group unchanged
- This is the default behavior when manageDefaultSecurityGroup: false

Spec: This validates Task 4.8 requirement - default behavior should NOT manage
the default security group unless explicitly enabled.

Reference: terraform-aws-modules/terraform-aws-vpc manage_default_security_group=false
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
        metadata.name: "test-vpc-default-sg-disabled"
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
                    name: "test-default-sg-off"
                    namespace: "default"
                }
                spec: {
                    # Core VPC config
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"

                    # Default Security Group Management DISABLED (default)
                    manageDefaultSecurityGroup: False

                    # Tags
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                }
            }

            # Assert expected managed resources
            assertResources: [
                # VPC resource (only VPC, NO DefaultSecurityGroup)
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-default-sg-off"
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
                                Name: "test-default-sg-off"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                }
                # Spec: NO DefaultSecurityGroup resource should be created
                # (implicit validation - absence from assertResources)
            ]
        }
    }
]
items= _items
