"""
Simple VPC Composition Test

Tests the terraform-aws-modules/vpc "simple" example scenario:
- VPC with basic configuration
- Public subnets across multiple AZs
- DNS hostnames and support enabled
- Tags applied correctly
- mapPublicIpOnLaunch enabled for public subnets

Spec: This validates the MINIMAL VPC test case from terraform-vpc-analysis.md
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-simple"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline instead of using separate file
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: ["us-west-2a", "us-west-2b"]
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    mapPublicIpOnLaunch: True
                    tags: {
                        Environment: "test"
                        ManagedBy: "upbound"
                    }
                    publicSubnetTags: {
                        Tier: "public"
                    }
                }
            }

            # Assert that VPC is created with correct specs
            # Spec: Basic VPC creation with CIDR block and DNS settings
            assertResources: [
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc"
                    }
                    spec: {
                        # v2: providerConfigRef requires kind field
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # v2: managementPolicies replaces deletionPolicy
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: VPC should have correct CIDR block
                            cidrBlock: "10.0.0.0/16"
                            # Spec: VPC should be in correct region
                            region: "us-west-2"
                            # Spec: DNS hostnames enabled by default
                            enableDnsHostnames: True
                            # Spec: DNS support enabled by default
                            enableDnsSupport: True
                            # Spec: VPC should have correct tags
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                Name: "test-vpc"
                            }
                        }
                    }
                },
                # Spec: Public subnet 1 (us-west-2a)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-us-west-2a"
                    }
                    spec: {
                        # v2: providerConfigRef requires kind field
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # v2: managementPolicies replaces deletionPolicy
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Subnets should reference VPC via controller ref
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            # Spec: Subnets should be in correct region
                            region: "us-west-2"
                            # Spec: Subnet in AZ us-west-2a
                            availabilityZone: "us-west-2a"
                            # Spec: First public subnet CIDR
                            cidrBlock: "10.0.1.0/24"
                            # Spec: Public subnets should have mapPublicIpOnLaunch enabled
                            mapPublicIpOnLaunch: True
                            # Spec: Public subnets should have all tags
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                Tier: "public"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Public subnet 2 (us-west-2b)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-us-west-2b"
                    }
                    spec: {
                        # v2: providerConfigRef requires kind field
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # v2: managementPolicies replaces deletionPolicy
                        managementPolicies: ["*"]
                        forProvider: {
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                            region: "us-west-2"
                            # Spec: Subnet in AZ us-west-2b
                            availabilityZone: "us-west-2b"
                            # Spec: Second public subnet CIDR
                            cidrBlock: "10.0.2.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                ManagedBy: "upbound"
                                Tier: "public"
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