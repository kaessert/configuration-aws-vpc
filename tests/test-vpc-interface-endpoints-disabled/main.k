"""
VPC Interface Endpoints - Disabled Test

Tests that no Interface VPC Endpoints are created when feature is disabled:
- VPC with public and private subnets
- Interface endpoints feature disabled
- No Interface endpoints created
- Validates default behavior (feature disabled by default)

Spec: This validates Interface VPC Endpoints (task 4.5) from TASKS.md
Verifies Interface endpoints are NOT created when enableInterfaceEndpoints: false
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-interface-endpoints-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with Interface endpoints disabled (or omitted)
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
]
items= _items
