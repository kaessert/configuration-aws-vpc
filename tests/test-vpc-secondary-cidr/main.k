"""
Secondary CIDR Blocks Composition Test

Tests VPC with secondary CIDR blocks:
- Primary VPC with main CIDR block
- Two secondary CIDR blocks associated with the VPC
- VPCIpv4CidrBlockAssociation resources created
- Subnets can use CIDRs from secondary blocks
- All CIDR blocks properly tagged

Spec: This validates Task 3.6 (Secondary CIDR Blocks) from TASKS.md
- Allow multiple CIDR blocks on a single VPC
- Support IP space expansion for large VPCs
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-secondary-cidr"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR with primary and secondary CIDR blocks
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-secondary-cidr"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    # Primary CIDR block
                    cidr: "10.0.0.0/16"
                    # Secondary CIDR blocks for IP space expansion
                    secondaryCidrBlocks: [
                        "10.1.0.0/16",
                        "10.2.0.0/16"
                    ]
                    azs: ["us-west-2a", "us-west-2b"]
                    # Subnets using primary CIDR
                    publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                    # Subnets using secondary CIDR blocks
                    privateSubnets: ["10.1.1.0/24", "10.1.2.0/24"]
                    databaseSubnets: ["10.2.1.0/24", "10.2.2.0/24"]
                    tags: {
                        Environment: "test"
                        Feature: "secondary-cidr"
                    }
                }
            }

            # Assert that VPC and secondary CIDR associations are created
            assertResources: [
                # Spec: Primary VPC with main CIDR block
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-secondary-cidr"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: VPC should have primary CIDR block
                            cidrBlock: "10.0.0.0/16"
                            region: "us-west-2"
                            enableDnsHostnames: True
                            enableDnsSupport: True
                            tags: {
                                Environment: "test"
                                Feature: "secondary-cidr"
                                Name: "test-secondary-cidr"
                            }
                        }
                    }
                },
                # Spec: First secondary CIDR block association (10.1.0.0/16)
                ec2v1beta1.VPCIPv4CidrBlockAssociation{
                    metadata: {
                        name: "secondary-cidr-test-secondary-cidr-0"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Secondary CIDR block value
                            cidrBlock: "10.1.0.0/16"
                            region: "us-west-2"
                            # Spec: Should reference the VPC via selector
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },
                # Spec: Second secondary CIDR block association (10.2.0.0/16)
                ec2v1beta1.VPCIPv4CidrBlockAssociation{
                    metadata: {
                        name: "secondary-cidr-test-secondary-cidr-1"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Secondary CIDR block value
                            cidrBlock: "10.2.0.0/16"
                            region: "us-west-2"
                            # Spec: Should reference the VPC via selector
                            vpcIdSelector: {
                                matchControllerRef: True
                            }
                        }
                    }
                },
                # Spec: Public subnet using primary CIDR (10.0.x.x)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-secondary-cidr-us-west-2a"
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
                            # Spec: Subnet from primary CIDR block
                            cidrBlock: "10.0.1.0/24"
                            mapPublicIpOnLaunch: True
                            tags: {
                                Environment: "test"
                                Feature: "secondary-cidr"
                                Type: "public"
                            }
                        }
                    }
                },
                # Spec: Private subnet using first secondary CIDR (10.1.x.x)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-private-test-secondary-cidr-us-west-2a"
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
                            # Spec: Subnet from first secondary CIDR block
                            cidrBlock: "10.1.1.0/24"
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Feature: "secondary-cidr"
                                Type: "private"
                            }
                        }
                    }
                },
                # Spec: Database subnet using second secondary CIDR (10.2.x.x)
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-database-test-secondary-cidr-us-west-2a"
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
                            # Spec: Subnet from second secondary CIDR block
                            cidrBlock: "10.2.1.0/24"
                            mapPublicIpOnLaunch: False
                            tags: {
                                Environment: "test"
                                Feature: "secondary-cidr"
                                Type: "database"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items= _items
