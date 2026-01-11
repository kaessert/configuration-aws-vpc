"""
VPC Default Resources Management Composition Tests

Tests VPC default resource management with various configurations:
- **nacl-managed**: Default Network ACL with custom ingress/egress rules
- **rt-managed**: Default Route Table with custom routes
- **sg-disabled**: Default Security Group disabled (default behavior)
- **sg-managed**: Default Security Group managed with empty rules (security hardening)

Spec: This validates Task 4.8 - Default resource management for enhanced security

Reference: thoughts/TASKS.md Task 4.8, terraform-aws-modules/terraform-aws-vpc
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

# Test 1: Default Network ACL Management
_test_nacl_managed = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-default-nacl-managed"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-default-nacl"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                # Spec: Enable default Network ACL management
                manageDefaultNetworkAcl: True
                # Spec: Custom ingress rules (HTTPS and HTTP from VPC CIDR)
                defaultNetworkAclIngressRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 443
                        toPort: 443
                    },
                    {
                        ruleNumber: 110
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "10.0.0.0/16"
                        fromPort: 80
                        toPort: 80
                    }
                ]
                # Spec: Custom egress rules (HTTPS and HTTP to internet)
                defaultNetworkAclEgressRules: [
                    {
                        ruleNumber: 100
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 443
                        toPort: 443
                    },
                    {
                        ruleNumber: 110
                        protocol: "tcp"
                        ruleAction: "allow"
                        cidrBlock: "0.0.0.0/0"
                        fromPort: 80
                        toPort: 80
                    }
                ]
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
                defaultNetworkAclTags: {
                    Type: "default-network-acl"
                    Managed: "true"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-default-nacl" }
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
                            Name: "test-default-nacl"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Default Network ACL should be managed with custom rules
            ec2v1beta1.DefaultNetworkACL{
                metadata: { name: "default-nacl-test-default-nacl" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: References VPC's default NACL
                        defaultNetworkAclIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: Custom ingress rules (protocol 6 = TCP)
                        ingress: [
                            {
                                ruleNo: 100
                                protocol: "6"
                                action: "allow"
                                cidrBlock: "10.0.0.0/16"
                                fromPort: 443
                                toPort: 443
                            },
                            {
                                ruleNo: 110
                                protocol: "6"
                                action: "allow"
                                cidrBlock: "10.0.0.0/16"
                                fromPort: 80
                                toPort: 80
                            }
                        ]
                        # Spec: Custom egress rules
                        egress: [
                            {
                                ruleNo: 100
                                protocol: "6"
                                action: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 443
                                toPort: 443
                            },
                            {
                                ruleNo: 110
                                protocol: "6"
                                action: "allow"
                                cidrBlock: "0.0.0.0/0"
                                fromPort: 80
                                toPort: 80
                            }
                        ]
                        # Spec: Tags merged from common and specific tags
                        tags: {
                            Name: "test-default-nacl-default-nacl"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "default-network-acl"
                            Managed: "true"
                        }
                    }
                }
            }
        ]
    }
}

# Test 2: Default Route Table Management
_test_rt_managed = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-default-rt-managed"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-default-rt"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                # Spec: Create IGW for routing
                createIgw: True
                # Spec: Enable default Route Table management
                manageDefaultRouteTable: True
                # Spec: Custom routes (default route to IGW)
                defaultRouteTableRoutes: [
                    {
                        destinationCidrBlock: "0.0.0.0/0"
                        gatewayType: "igw"
                    }
                ]
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
                defaultRouteTableTags: {
                    Type: "default-route-table"
                    Managed: "true"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-default-rt" }
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
                            Name: "test-default-rt"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Internet Gateway should be created
            ec2v1beta1.InternetGateway{
                metadata: { name: "igw-test-default-rt" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        tags: {
                            Name: "igw-test-default-rt"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Default Route Table should be managed with custom routes
            ec2v1beta1.DefaultRouteTable{
                metadata: { name: "default-rt-test-default-rt" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: References VPC's default route table
                        defaultRouteTableIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: Route to IGW for internet access
                        route: [
                            {
                                cidrBlock: "0.0.0.0/0"
                                gatewayIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: { "resource-type": "igw" }
                                }
                            }
                        ]
                        # Spec: Tags merged from common and specific tags
                        tags: {
                            Name: "test-default-rt-default-rt"
                            Environment: "test"
                            ManagedBy: "upbound"
                            Type: "default-route-table"
                            Managed: "true"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: Default Security Group Disabled (default behavior)
_test_sg_disabled = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-default-sg-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-default-sg-off"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                # Spec: Default SG management disabled (default behavior)
                manageDefaultSecurityGroup: False
                tags: {
                    Environment: "test"
                    ManagedBy: "upbound"
                }
            }
        }
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-default-sg-off" }
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
                            Name: "test-default-sg-off"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            }
            # Spec: NO DefaultSecurityGroup resource should be created
        ]
    }
}

# Test 4: Default Security Group Managed (security hardening)
_test_sg_managed = metav1alpha1.CompositionTest {
    metadata.name: "test-vpc-default-sg-managed"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-default-sg"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                # Spec: Enable default SG management
                manageDefaultSecurityGroup: True
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
        assertResources: [
            # Spec: VPC should be created
            ec2v1beta1.VPC{
                metadata: { name: "vpc-test-default-sg" }
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
                            Name: "test-default-sg"
                            Environment: "test"
                            ManagedBy: "upbound"
                        }
                    }
                }
            },
            # Spec: Default Security Group should be managed with empty rules
            ec2v1beta1.DefaultSecurityGroup{
                metadata: { name: "default-sg-test-default-sg" }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: References VPC
                        vpcIdSelector: { matchControllerRef: True }
                        region: "us-west-2"
                        # Spec: Security hardening - empty rules deny all traffic
                        ingress: []
                        egress: []
                        # Spec: Tags merged from common and specific tags
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

items = [
    _test_nacl_managed,
    _test_rt_managed,
    _test_sg_disabled,
    _test_sg_managed
]
