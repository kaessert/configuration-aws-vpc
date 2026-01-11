"""
NAT Gateway Composition Tests

Tests NAT Gateway feature with various configurations:
1. **Disabled**: NAT Gateway disabled (enableNatGateway: false)
2. **Single**: Single NAT Gateway for all AZs (cost-optimized)
3. **Per AZ**: One NAT Gateway per AZ (high availability)
4. **Per Subnet**: One NAT Gateway per public subnet (maximum availability)
5. **Custom CIDR**: Custom destination CIDR for NAT routes
6. **Reuse EIPs**: Use external EIP allocation IDs

Spec: This validates NAT Gateway implementations (task 2.4 and 4.4) from terraform-vpc-analysis.md and TASKS.md

Reference: https://github.com/terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: NAT Gateway Disabled
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-disabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: Disable NAT Gateway (default is false)
                enableNatGateway: False
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-disabled"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-disabled" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-disabled"
                            Name: "test-vpc-nat-disabled"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-disabled" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-disabled"
                            Name: "igw-test-vpc-nat-disabled"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-disabled-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-disabled"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Private subnet should be created in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-private-test-vpc-nat-disabled-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.10.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Feature: "nat-disabled"
                            Type: "private"
                        }
                    }
                }
            }
            # Spec: NO NAT Gateway should be created (assertion via absence)
            # Spec: NO EIP should be allocated (assertion via absence)
        ]
    }
}

# Test 2: Single NAT Gateway (cost-optimized)
_test_single = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-single"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-single"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                # Spec: Enable NAT Gateway with single NAT strategy for cost optimization
                enableNatGateway: True
                singleNatGateway: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-single"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-single" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Name: "test-vpc-nat-single"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-single" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Name: "igw-test-vpc-nat-single"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in first AZ (where NAT will be placed)
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-single-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Private subnet should be created in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-private-test-vpc-nat-single-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.10.0/24"
                        mapPublicIpOnLaunch: False
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Type: "private"
                        }
                    }
                }
            },
            # Spec: Single EIP should be allocated for the NAT Gateway
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-single-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        # Spec: EIP should be vpc-scoped
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Name: "eip-nat-test-vpc-nat-single-us-west-2a"
                        }
                    }
                }
            },
            # Spec: Single NAT Gateway should be created in first public subnet
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-single-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: NAT Gateway should be placed in first public subnet
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2a"
                            }
                        }
                        # Spec: NAT Gateway should use the allocated EIP
                        allocationIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-single"
                            Name: "nat-test-vpc-nat-single-us-west-2a"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: NAT Gateway Per AZ (high availability)
_test_per_az = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-per-az"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-per-az"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                # Spec: Enable NAT Gateway with one NAT per AZ for high availability
                enableNatGateway: True
                oneNatGatewayPerAz: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-per-az"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-per-az" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            Name: "test-vpc-nat-per-az"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-per-az" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            Name: "igw-test-vpc-nat-per-az"
                        }
                    }
                }
            },
            # Spec: Public subnet in us-west-2a
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-az-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet in us-west-2b
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-az-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.2.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet in us-west-2c
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-az-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2c"
                        cidrBlock: "10.0.3.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: EIP for NAT Gateway in us-west-2a
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-az-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2a"
                            Name: "eip-nat-test-vpc-nat-per-az-us-west-2a"
                        }
                    }
                }
            },
            # Spec: EIP for NAT Gateway in us-west-2b
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-az-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2b"
                            Name: "eip-nat-test-vpc-nat-per-az-us-west-2b"
                        }
                    }
                }
            },
            # Spec: EIP for NAT Gateway in us-west-2c
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-az-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2c"
                            Name: "eip-nat-test-vpc-nat-per-az-us-west-2c"
                        }
                    }
                }
            },
            # Spec: NAT Gateway in us-west-2a
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-az-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2a"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "az": "us-west-2a" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2a"
                            Name: "nat-test-vpc-nat-per-az-us-west-2a"
                        }
                    }
                }
            },
            # Spec: NAT Gateway in us-west-2b
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-az-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2b"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "az": "us-west-2b" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2b"
                            Name: "nat-test-vpc-nat-per-az-us-west-2b"
                        }
                    }
                }
            },
            # Spec: NAT Gateway in us-west-2c
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-az-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2c"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "az": "us-west-2c" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-az"
                            AZ: "us-west-2c"
                            Name: "nat-test-vpc-nat-per-az-us-west-2c"
                        }
                    }
                }
            }
        ]
    }
}

# Test 4: NAT Gateway Per Subnet (maximum availability)
_test_per_subnet = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-per-subnet"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-per-subnet"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                # Spec: Enable NAT Gateway with one NAT per subnet strategy for maximum availability
                enableNatGateway: True
                oneNatGatewayPerSubnet: True
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-per-subnet"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-per-subnet" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "test-vpc-nat-per-subnet"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-per-subnet" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "igw-test-vpc-nat-per-subnet"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-subnet-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in second AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-subnet-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.2.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in third AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-per-subnet-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2c"
                        cidrBlock: "10.0.3.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: EIP should be allocated for first NAT Gateway
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-subnet-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "eip-nat-test-vpc-nat-per-subnet-0"
                        }
                    }
                }
            },
            # Spec: EIP should be allocated for second NAT Gateway
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-subnet-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "eip-nat-test-vpc-nat-per-subnet-1"
                        }
                    }
                }
            },
            # Spec: EIP should be allocated for third NAT Gateway
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-per-subnet-2" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "eip-nat-test-vpc-nat-per-subnet-2"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in first public subnet
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-subnet-0" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "subnet-index": "0"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "eip-index": "0" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "nat-test-vpc-nat-per-subnet-0"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in second public subnet
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-subnet-1" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "subnet-index": "1"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "eip-index": "1" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "nat-test-vpc-nat-per-subnet-1"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in third public subnet
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-per-subnet-2" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "subnet-index": "2"
                            }
                        }
                        allocationIdSelector: {
                            matchLabels: { "eip-index": "2" }
                        }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-per-subnet"
                            Name: "nat-test-vpc-nat-per-subnet-2"
                        }
                    }
                }
            }
        ]
    }
}

# Test 5: NAT Gateway with Custom Destination CIDR
_test_custom_cidr = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-custom-cidr"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-custom-cidr"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: Enable NAT Gateway with single NAT for simplicity
                enableNatGateway: True
                singleNatGateway: True
                # Spec: Custom destination CIDR for NAT routes (10.0.0.0/8 instead of default 0.0.0.0/0)
                natGatewayDestinationCidrBlock: "10.0.0.0/8"
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-custom-cidr"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-custom-cidr" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-custom-cidr"
                            Name: "test-vpc-nat-custom-cidr"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-custom-cidr" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-custom-cidr"
                            Name: "igw-test-vpc-nat-custom-cidr"
                        }
                    }
                }
            },
            # Spec: EIP should be allocated for NAT Gateway
            ec2v1beta1.EIP{
                metadata: { name: "eip-nat-test-vpc-nat-custom-cidr-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        region: "us-west-2"
                        domain: "vpc"
                        tags: {
                            Environment: "test"
                            Feature: "nat-custom-cidr"
                            Name: "eip-nat-test-vpc-nat-custom-cidr-us-west-2a"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-custom-cidr-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2a"
                            }
                        }
                        allocationIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-custom-cidr"
                            Name: "nat-test-vpc-nat-custom-cidr-us-west-2a"
                        }
                    }
                }
            },
            # Spec: Private route table should be created
            ec2v1beta1.RouteTable{
                metadata: { name: "rtb-private-test-vpc-nat-custom-cidr" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-custom-cidr"
                            Type: "private"
                        }
                    }
                }
            },
            # Spec: Private route should use custom destination CIDR (10.0.0.0/8) instead of 0.0.0.0/0
            ec2v1beta1.Route{
                metadata: { name: "route-private-nat-test-vpc-nat-custom-cidr" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        routeTableIdSelector: {
                            matchLabels: { "route-table-type": "private" }
                        }
                        natGatewayIdSelector: { matchControllerRef: True }
                        # Spec: CRITICAL - Destination should be 10.0.0.0/8 (NOT default 0.0.0.0/0)
                        destinationCidrBlock: "10.0.0.0/8"
                        region: "us-west-2"
                    }
                }
            }
        ]
    }
}

# Test 6: NAT Gateway with Reuse EIPs
_test_reuse_eips = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-nat-reuse-eips"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-nat-reuse-eips"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b", "us-west-2c"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
                # Spec: Enable NAT Gateway with NAT per AZ
                enableNatGateway: True
                oneNatGatewayPerAz: True
                # Spec: Reuse existing EIPs instead of creating new ones
                reuseNatIps: True
                externalNatIpIds: ["eipalloc-12345678", "eipalloc-87654321", "eipalloc-abcdef12"]
                createIgw: True
                tags: {
                    Environment: "test"
                    Feature: "nat-reuse-eips"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-nat-reuse-eips" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        cidrBlock: "10.0.0.0/16"
                        region: "us-west-2"
                        enableDnsHostnames: True
                        enableDnsSupport: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Name: "test-vpc-nat-reuse-eips"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-nat-reuse-eips" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Name: "igw-test-vpc-nat-reuse-eips"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in first AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in second AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2b"
                        cidrBlock: "10.0.2.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: Public subnet should be created in third AZ
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-nat-reuse-eips-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2c"
                        cidrBlock: "10.0.3.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Type: "public"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in first AZ with external EIP
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-reuse-eips-us-west-2a" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2a"
                            }
                        }
                        # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                        allocationId: "eipalloc-12345678"
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Name: "nat-test-vpc-nat-reuse-eips-us-west-2a"
                            AZ: "us-west-2a"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in second AZ with external EIP
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-reuse-eips-us-west-2b" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2b"
                            }
                        }
                        # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                        allocationId: "eipalloc-87654321"
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Name: "nat-test-vpc-nat-reuse-eips-us-west-2b"
                            AZ: "us-west-2b"
                        }
                    }
                }
            },
            # Spec: NAT Gateway should be created in third AZ with external EIP
            ec2v1beta1.NATGateway{
                metadata: { name: "nat-test-vpc-nat-reuse-eips-us-west-2c" }
                spec: {
                    providerConfigRef: { kind: "ProviderConfig", name: "default" }
                    managementPolicies: ["*"]
                    forProvider: {
                        subnetIdSelector: {
                            matchLabels: {
                                "subnet-type": "public"
                                "az": "us-west-2c"
                            }
                        }
                        # Spec: NAT Gateway should use external EIP allocation ID (NOT selector)
                        allocationId: "eipalloc-abcdef12"
                        region: "us-west-2"
                        tags: {
                            Environment: "test"
                            Feature: "nat-reuse-eips"
                            Name: "nat-test-vpc-nat-reuse-eips-us-west-2c"
                            AZ: "us-west-2c"
                        }
                    }
                }
            }
            # NOTE: NO EIP resources should be created when reuseNatIps: true
        ]
    }
}

items = [
    _test_disabled,
    _test_single,
    _test_per_az,
    _test_per_subnet,
    _test_custom_cidr,
    _test_reuse_eips
]
