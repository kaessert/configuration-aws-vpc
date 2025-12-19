"""
Internet Gateway Disabled Test

Tests that NO Internet Gateway is created when createIgw is disabled:
- VPC with basic configuration
- NO Internet Gateway created
- Only VPC and subnet resources exist
- Validates conditional IGW creation logic

Spec: This validates IGW conditional creation (task 2.3) from terraform-vpc-analysis.md
Verifies that IGW is NOT created when createIgw: false
"""

import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xvpc-igw-disabled"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline with createIgw disabled
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
                    # Spec: Explicitly disable IGW creation
                    createIgw: False
                    tags: {
                        Environment: "test"
                        Feature: "no-igw"
                    }
                }
            }

            # Assert that only VPC and subnet are created, NO IGW
            assertResources: [
                # Spec: VPC resource should still be created
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-vpc-no-igw"
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
                                Feature: "no-igw"
                                Name: "test-vpc-no-igw"
                            }
                        }
                    }
                },
                # Spec: Public subnet should still be created
                ec2v1beta1.Subnet{
                    metadata: {
                        name: "subnet-public-test-vpc-no-igw-us-west-2a"
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
                                Feature: "no-igw"
                                Type: "public"
                            }
                        }
                    }
                }
                # Spec: NOTE - NO InternetGateway resource should be created
                # The test verifies this by only asserting VPC and Subnet resources
                # If an IGW were created, the test would fail due to unexpected resources
            ]
        }
    }
]
items= _items
