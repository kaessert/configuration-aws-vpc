"""
Default Route Table Management Test

Tests default route table management when enabled:
- DefaultRouteTable resource is created
- References VPC via vpcIdSelector.matchControllerRef
- Custom routes from defaultRouteTableRoutes
- Tags merged from common tags and defaultRouteTableTags

Spec: This validates Task 4.8 requirement - managing default route table
with custom routes for centralized routing configuration.

Reference: terraform-aws-modules/terraform-aws-vpc manage_default_route_table
"""

import models.io.upbound.awsm.cloudwatchlogs.v1beta1 as cloudwatchlogsv1beta1
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.awsm.iam.v1beta1 as iamv1beta1
import models.io.upbound.awsm.rds.v1beta1 as rdsv1beta1
import models.io.upbound.awsm.redshift.v1beta1 as redshiftv1beta1
import models.io.upbound.awsm.s3.v1beta1 as s3v1beta1
import models.io.upbound.awsm.v1beta1 as awsmv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.dev.meta.v2alpha1 as metav2alpha1
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-vpc-default-rt-managed"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            timeoutSeconds: 60
            validate: True

            # Define XR inline
            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-default-rt"
                    namespace: "default"
                }
                spec: {
                    # Core VPC config
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"

                    # Enable IGW for routing
                    createIgw: True

                    # Default Route Table Management
                    manageDefaultRouteTable: True

                    # Custom routes for default route table
                    defaultRouteTableRoutes: [
                        {
                            destinationCidrBlock: "0.0.0.0/0"
                            gatewayType: "igw"
                        }
                    ]

                    # Tags
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

            # Assert expected managed resources
            assertResources: [
                # VPC resource
                ec2v1beta1.VPC{
                    metadata: {
                        name: "vpc-test-default-rt"
                    }
                    spec: {
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        managementPolicies: ["*"]
                        forProvider: {
                            region: "us-west-2"
                            cidrBlock: "10.0.0.0/16"
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

                # Internet Gateway (needed for routes)
                ec2v1beta1.InternetGateway{
                    metadata: {
                        name: "igw-test-default-rt"
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
                            tags: {
                                Name: "igw-test-default-rt"
                                Environment: "test"
                                ManagedBy: "upbound"
                            }
                        }
                    }
                },

                # Spec: Default Route Table should be managed
                ec2v1beta1.DefaultRouteTable{
                    metadata: {
                        name: "default-rt-test-default-rt"
                    }
                    spec: {
                        # Spec: Crossplane v2 requires kind in providerConfigRef
                        providerConfigRef: {
                            kind: "ProviderConfig"
                            name: "default"
                        }
                        # Spec: Crossplane v2 uses managementPolicies
                        managementPolicies: ["*"]
                        forProvider: {
                            # Spec: Default RT references VPC via controller ref
                            defaultRouteTableIdSelector: {
                                matchControllerRef: True
                            }

                            # Spec: Resource should be in correct region
                            region: "us-west-2"

                            # Spec: Custom routes (route to IGW)
                            route: [
                                {
                                    cidrBlock: "0.0.0.0/0"
                                    gatewayIdSelector: {
                                        matchControllerRef: True
                                        matchLabels: {
                                            "resource-type": "igw"
                                        }
                                    }
                                }
                            ]

                            # Spec: Tags merged from common tags and defaultRouteTableTags
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
]
items= _items
