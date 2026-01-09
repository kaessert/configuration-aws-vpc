"""
VPC Instance Tenancy (Default) Composition Test

Tests VPC creation with default instance tenancy:
- VPC resource created with instanceTenancy: "default"
- Instances launched in this VPC will run on shared hardware (most common)
- Cost-effective option for most workloads

Spec: This validates Task 4.10 - VPC Configuration Enhancements (instance tenancy support)
Spec: Validates default behavior when instanceTenancy is explicitly set to "default"

Reference: terraform-aws-modules/terraform-aws-vpc instance_tenancy variable
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-instance-tenancy-default"
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
                    name: "test-tenancy-default"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    cidr: "10.0.0.0/16"
                    region: "us-west-2"

                    # Instance tenancy: default (shared hardware, most common)
                    instanceTenancy: "default"

                    # Tags
                    tags: {
                        Environment: "test"
                        TestType: "instance-tenancy"
                        Tenancy: "default"
                    }
                }
            }

            # Assert expected VPC resource with default tenancy
            assertResources: [
                # VPC with default instance tenancy
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-tenancy-default"
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
                            # Spec: VPC should be in correct region
                            region: "us-west-2"

                            # Spec: VPC should have specified CIDR block
                            cidrBlock: "10.0.0.0/16"

                            # Spec: VPC should have default instance tenancy
                            instanceTenancy: "default"

                            # Spec: DNS settings should be enabled by default
                            enableDnsHostnames: True
                            enableDnsSupport: True

                            # Spec: VPC should have correct tags
                            tags: {
                                Name: "test-tenancy-default"
                                Environment: "test"
                                TestType: "instance-tenancy"
                                Tenancy: "default"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items