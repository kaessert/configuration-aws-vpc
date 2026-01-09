"""
VPC Instance Tenancy (Dedicated) Composition Test

Tests VPC creation with dedicated instance tenancy:
- VPC resource created with instanceTenancy: "dedicated"
- Instances launched in this VPC will run on dedicated hardware
- Used for compliance/isolation requirements

Spec: This validates Task 4.10 - VPC Configuration Enhancements (instance tenancy support)

Reference: terraform-aws-modules/terraform-aws-vpc instance_tenancy variable
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-instance-tenancy-dedicated"
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
                    name: "test-tenancy-dedicated"
                    namespace: "default"
                }
                spec: {
                    # Basic VPC configuration
                    cidr: "10.0.0.0/16"
                    region: "us-west-2"

                    # Instance tenancy: dedicated (compliance/isolation)
                    instanceTenancy: "dedicated"

                    # Tags
                    tags: {
                        Environment: "test"
                        TestType: "instance-tenancy"
                        Tenancy: "dedicated"
                    }
                }
            }

            # Assert expected VPC resource with dedicated tenancy
            assertResources: [
                # VPC with dedicated instance tenancy
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-tenancy-dedicated"
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

                            # Spec: VPC should have dedicated instance tenancy
                            instanceTenancy: "dedicated"

                            # Spec: DNS settings should be enabled by default
                            enableDnsHostnames: True
                            enableDnsSupport: True

                            # Spec: VPC should have correct tags
                            tags: {
                                Name: "test-tenancy-dedicated"
                                Environment: "test"
                                TestType: "instance-tenancy"
                                Tenancy: "dedicated"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items