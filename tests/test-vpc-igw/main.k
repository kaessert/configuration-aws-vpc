"""
VPC Internet Gateway (IGW) Composition Tests

Tests VPC Internet Gateway functionality with various configurations:
- **disabled**: Internet Gateway disabled (no IGW created)
- **enabled**: Internet Gateway enabled (IGW created and attached to VPC)

Spec: This validates Internet Gateway support from terraform-aws-vpc module

Reference: terraform-aws-modules/terraform-aws-vpc
"""

import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


# Shared base specification (DRY)
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Test 1: IGW Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-igw-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-no-igw"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: IGW disabled (default)
                createIgw: False
                tags: {
                    Name: "test-vpc-no-igw"
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-no-igw" }
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
                            Name: "test-vpc-no-igw"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Subnet should be created
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-no-igw-us-west-2a-0" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Name: "subnet-public-test-vpc-no-igw-us-west-2a-0"
                            Type: "public"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            }
            # Spec: NO InternetGateway resource should be created
            # Spec: NO InternetGatewayAttachment resource should be created
        ]
    }
}

# Test 2: IGW Enabled
_test_enabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-igw-enabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-with-igw"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                # Spec: Enable Internet Gateway
                createIgw: True
                tags: {
                    Name: "test-vpc-with-igw"
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-vpc-with-igw" }
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
                            Name: "test-vpc-with-igw"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Subnet should be created
            ec2v1beta1.Subnet{
                metadata: { name: "subnet-public-test-vpc-with-igw-us-west-2a-0" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        availabilityZone: "us-west-2a"
                        cidrBlock: "10.0.1.0/24"
                        mapPublicIpOnLaunch: True
                        tags: {
                            Name: "subnet-public-test-vpc-with-igw-us-west-2a-0"
                            Type: "public"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created when createIgw: true
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-vpc-with-igw" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: IGW attached to VPC via controller reference
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Name: "igw-test-vpc-with-igw"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_enabled
]
