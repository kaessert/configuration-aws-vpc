"""
VPC Interface Endpoints Composition Tests

Tests Interface VPC Endpoints with various configurations:
- **disabled**: Interface endpoints disabled (default behavior)
- **single**: Single Interface endpoint (EC2)
- **multiple**: Multiple Interface endpoints (EC2, SSM, RDS)
- **no-private-dns**: Interface endpoint with privateDnsEnabled: False
- **minimal**: Minimal configuration with single endpoint

Spec: This validates Task 4.5 - Interface VPC Endpoints implementation

Reference: thoughts/TASKS.md Task 4.5, terraform-aws-modules/terraform-aws-vpc
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

# Test 1: Interface Endpoints Disabled (default behavior)
_test_disabled = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-interface-endpoints-disabled"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-interface-disabled"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                publicSubnets: ["10.0.1.0/24"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: Interface endpoints explicitly disabled (or omitted - default is false)
                enableInterfaceEndpoints: False
                # Spec: Services list provided but feature disabled - should be ignored
                interfaceEndpointServices: ["ec2", "ssm"]
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Environment: "test"
                    Feature: "interface-endpoints-disabled"
                }
            }
        }
        # Assert that ONLY VPC is created (NO Interface endpoints)
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-interface-disabled"
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
                            Feature: "interface-endpoints-disabled"
                            Name: "test-vpc-interface-disabled"
                        }
                    }
                }
            }
            # Spec: NOTE - NO Interface VPC Endpoint resources
            # This validates feature is properly disabled when enableInterfaceEndpoints: false
        ]
    }
}

# Test 2: Single Interface Endpoint (EC2)
_test_single = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-interface-endpoint-single"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-interface-single"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: Enable Interface Endpoints with single service
                enableInterfaceEndpoints: True
                interfaceEndpointServices: ["ec2"]
                # Spec: Private DNS enabled by default
                enableInterfaceEndpointPrivateDns: True
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Environment: "test"
                    Feature: "interface-endpoints"
                }
                vpcEndpointTags: {
                    Type: "interface"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-interface-single"
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
                            Feature: "interface-endpoints"
                            Name: "test-vpc-interface-single"
                        }
                    }
                }
            },
            # Spec: EC2 Interface Endpoint should be created when enableInterfaceEndpoints: true
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-ec2-test-vpc-interface-single"
                }
                spec: {
                    providerConfigRef: {
                        kind: "ProviderConfig"
                        name: "default"
                    }
                    managementPolicies: ["*"]
                    forProvider: {
                        # Spec: Endpoint attached to VPC
                        vpcIdSelector: {
                            matchControllerRef: True
                        }
                        region: "us-west-2"
                        # Spec: EC2 service name
                        serviceName: "com.amazonaws.us-west-2.ec2"
                        # Spec: Interface type endpoint
                        vpcEndpointType: "Interface"
                        # Spec: Private DNS enabled
                        privateDnsEnabled: True
                        # Spec: Placed in private subnets via subnetConfiguration
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        # Spec: Correct tags applied
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoints"
                            Type: "interface"
                            Service: "ec2"
                            Name: "vpce-ec2-test-vpc-interface-single"
                        }
                    }
                }
            }
        ]
    }
}

# Test 3: Multiple Interface Endpoints (EC2, SSM, RDS)
_test_multiple = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-interface-endpoints-multiple"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-interface-multiple"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a", "us-west-2b"]
                publicSubnets: ["10.0.1.0/24", "10.0.2.0/24"]
                privateSubnets: ["10.0.10.0/24", "10.0.11.0/24"]
                # Spec: Enable Interface Endpoints with multiple services
                enableInterfaceEndpoints: True
                interfaceEndpointServices: ["ec2", "ssm", "rds"]
                enableInterfaceEndpointPrivateDns: True
                createIgw: True
                enableNatGateway: True
                singleNatGateway: True
                tags: {
                    Environment: "test"
                    Feature: "interface-endpoints-multiple"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-interface-multiple"
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
                            Feature: "interface-endpoints-multiple"
                            Name: "test-vpc-interface-multiple"
                        }
                    }
                }
            },
            # Spec: EC2 Interface Endpoint
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-ec2-test-vpc-interface-multiple"
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
                        serviceName: "com.amazonaws.us-west-2.ec2"
                        vpcEndpointType: "Interface"
                        privateDnsEnabled: True
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoints-multiple"
                            Service: "ec2"
                            Name: "vpce-ec2-test-vpc-interface-multiple"
                        }
                    }
                }
            },
            # Spec: SSM Interface Endpoint
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-ssm-test-vpc-interface-multiple"
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
                        # Spec: SSM service name
                        serviceName: "com.amazonaws.us-west-2.ssm"
                        vpcEndpointType: "Interface"
                        privateDnsEnabled: True
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoints-multiple"
                            Service: "ssm"
                            Name: "vpce-ssm-test-vpc-interface-multiple"
                        }
                    }
                }
            },
            # Spec: RDS Interface Endpoint
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-rds-test-vpc-interface-multiple"
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
                        # Spec: RDS service name
                        serviceName: "com.amazonaws.us-west-2.rds"
                        vpcEndpointType: "Interface"
                        privateDnsEnabled: True
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoints-multiple"
                            Service: "rds"
                            Name: "vpce-rds-test-vpc-interface-multiple"
                        }
                    }
                }
            }
        ]
    }
}

# Test 4: Interface Endpoint with Private DNS Disabled
_test_no_private_dns = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-interface-endpoint-no-private-dns"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-interface-no-dns"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: Enable Interface Endpoints
                enableInterfaceEndpoints: True
                interfaceEndpointServices: ["ec2"]
                # Spec: Explicitly disable private DNS
                enableInterfaceEndpointPrivateDns: False
                tags: {
                    Environment: "test"
                    Feature: "interface-endpoint-no-dns"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-interface-no-dns"
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
                            Feature: "interface-endpoint-no-dns"
                            Name: "test-vpc-interface-no-dns"
                        }
                    }
                }
            },
            # Spec: EC2 Interface Endpoint with privateDnsEnabled: False
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-ec2-test-vpc-interface-no-dns"
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
                        serviceName: "com.amazonaws.us-west-2.ec2"
                        vpcEndpointType: "Interface"
                        # Spec: Private DNS explicitly disabled
                        privateDnsEnabled: False
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoint-no-dns"
                            Service: "ec2"
                            Name: "vpce-ec2-test-vpc-interface-no-dns"
                        }
                    }
                }
            }
        ]
    }
}

# Test 5: Minimal Configuration with Interface Endpoint
_test_minimal = metav1alpha1.CompositionTest{
    metadata.name: "test-vpc-interface-endpoint-minimal"
    spec: {
        **_baseSpec
        xr: {
            apiVersion: "aws.platform.upbound.io/v1alpha1"
            kind: "VPC"
            metadata: {
                name: "test-vpc-interface-minimal"
                namespace: "default"
            }
            spec: {
                region: "us-west-2"
                cidr: "10.0.0.0/16"
                azs: ["us-west-2a"]
                privateSubnets: ["10.0.10.0/24"]
                # Spec: Enable Interface Endpoints with minimal configuration
                enableInterfaceEndpoints: True
                interfaceEndpointServices: ["ec2"]
                enableInterfaceEndpointPrivateDns: True
                tags: {
                    Environment: "test"
                    Feature: "interface-endpoint-minimal"
                }
            }
        }
        assertResources: [
            # Spec: VPC resource should be created
            ec2v1beta1.VPC{
                metadata: {
                    name: "vpc-test-vpc-interface-minimal"
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
                            Feature: "interface-endpoint-minimal"
                            Name: "test-vpc-interface-minimal"
                        }
                    }
                }
            },
            # Spec: EC2 Interface Endpoint with minimal configuration
            ec2v1beta1.VPCEndpoint{
                metadata: {
                    name: "vpce-ec2-test-vpc-interface-minimal"
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
                        serviceName: "com.amazonaws.us-west-2.ec2"
                        vpcEndpointType: "Interface"
                        privateDnsEnabled: True
                        subnetConfiguration: [
                            {
                                subnetIdSelector: {
                                    matchControllerRef: True
                                    matchLabels: {
                                        "subnet-type": "private"
                                    }
                                }
                            }
                        ]
                        tags: {
                            Environment: "test"
                            Feature: "interface-endpoint-minimal"
                            Service: "ec2"
                            Name: "vpce-ec2-test-vpc-interface-minimal"
                        }
                    }
                }
            }
        ]
    }
}

items = [
    _test_disabled,
    _test_single,
    _test_multiple,
    _test_no_private_dns,
    _test_minimal
]
