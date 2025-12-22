
import models.io.upbound.awsm.redshift.v1beta1 as redshiftv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# Test: Redshift Subnet Group creation
# Spec Coverage: Task 3.5 - Redshift Subnet Group resource
# Verifies:
# - SubnetGroup is created when createRedshiftSubnetGroup: true
# - SubnetGroup uses subnetIdSelector to match redshift subnets
# - SubnetGroup has correct tags

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-subnetgroup-redshift"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: False
            timeoutSeconds: 60

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-subnetgroup-redshift"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: [
                        "us-west-2a"
                        "us-west-2b"
                    ]
                    redshiftSubnets: [
                        "10.0.41.0/24"
                        "10.0.42.0/24"
                    ]
                    createRedshiftSubnetGroup: True
                    tags: {
                        Name: "test-vpc-subnetgroup-redshift"
                        Type: "redshift"
                    }
                }
            }

            assertResources: [
                # Test Spec: Verify Redshift Subnet Group is created
                redshiftv1beta1.SubnetGroup{
                    metadata: {
                        name: "test-vpc-subnetgroup-redshift-redshift"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            # Test Spec: Verify subnet selector matches redshift subnets
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "redshift"
                                }
                                matchControllerRef: True
                            }
                            # Test Spec: Verify tags are applied
                            tags: {
                                Name: "test-vpc-subnetgroup-redshift-redshift"
                                Type: "redshift"
                            }
                        }
                    }
                }
            ]
        }
    }
]

items= _items
