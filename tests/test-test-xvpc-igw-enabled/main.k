"""
Internet Gateway Enabled Test

Tests the Internet Gateway creation when createIgw is enabled (default):
- VPC with basic configuration
- Internet Gateway created
- IGW attached to VPC via vpcIdSelector
- Correct tags applied to IGW

Spec: This validates IGW creation (task 2.3) from terraform-vpc-analysis.md
Verifies that IGW is created by default when createIgw: true (default)
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-igw-enabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with createIgw enabled (default behavior)
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-igw"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a"]
                    publicSubnets: ["10.0.1.0/24"]
                    # Spec: createIgw defaults to true, explicitly setting for clarity
                    createIgw: True
                    tags: {
                        Environment: "test"
                        Feature: "igw"
                    }
                }
            }

            # Assert that VPC and IGW are created
            assertResources: [
                # Spec: VPC resource should be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-igw"
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
                                Feature: "igw"
                                Name: "test-vpc-igw"
                            }
                        }
                    }
                },
                # Spec: Internet Gateway should be created when createIgw: true
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-vpc-igw"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: IGW should be attached to VPC via vpcIdSelector
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: IGW should have correct tags
                            tags: {
                                Environment: "test"
                                Feature: "igw"
                                Name: "igw-test-vpc-igw"
                            }
                        }
                    }
                },
                # Spec: Public subnet should also be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-igw-us-west-2a"
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
                            cidrBlock: "10.0.1.0/24"
                            # Spec: mapPublicIpOnLaunch defaults to True for public subnets
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Feature: "igw"
                                Type: "public"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
