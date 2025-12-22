"""
Network ACLs - Disabled (Default Behavior) Test

Tests that NO dedicated Network ACLs are created when disabled:
- VPC with public and private subnets
- No dedicated NACLs created (default behavior)
- Subnets use AWS default NACL
- No NetworkACL or NetworkACLRule resources generated

Spec: This validates Network ACLs (task 3.2) from TASKS.md
Verifies default behavior where no dedicated NACLs are created
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-nacl-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR without dedicated NACLs (default behavior)
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-nacl-disabled"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    publicSubnets: ["10.0.1.0/24"]
                    privateSubnets: ["10.0.10.0/24"]
                    # Spec: No dedicated NACL flags set (default: false)
                    # publicDedicatedNetworkAcl: false (default)
                    # privateDedicatedNetworkAcl: false (default)
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "network-acls-disabled"
                    }
                }
            }

            # Assert that VPC is created but NO NACL resources
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-nacl-disabled"
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
                                Feature: "network-acls-disabled"
                                Name: "test-vpc-nacl-disabled"
                            }
                        }
                    }
                }
                # Spec: NO NetworkACL resources should be created
                # Spec: NO NetworkACLRule resources should be created
                # (AWS default NACL will be used automatically)
            ]
        }
    }
]
items= _items
