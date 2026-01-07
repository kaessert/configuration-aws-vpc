
import models.io.upbound.awsm.rds.v1beta1 as rdsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# Test: DB Subnet Group creation
# Spec Coverage: Task 3.5 - DB Subnet Group resource
# Verifies:
# - SubnetGroup is created when createDatabaseSubnetGroup: true
# - SubnetGroup uses subnetIdSelector to match database subnets
# - SubnetGroup has correct tags

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-subnetgroup-db"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: False
            timeoutSeconds: 60

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-subnetgroup-db"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: [
                        "us-west-2a"
                        "us-west-2b"
                    ]
                    databaseSubnets: [
                        "10.0.21.0/24"
                        "10.0.22.0/24"
                    ]
                    createDatabaseSubnetGroup: True
                    tags: {
                        Name: "test-vpc-subnetgroup-db"
                        Type: "database"
                    }
                }
            }

            assertResources: [
                # Test Spec: Verify DB Subnet Group is created
                rdsv1beta1.SubnetGroup{
                    metadata: {
                        name: "test-vpc-subnetgroup-db-db"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            # Test Spec: Verify subnet selector matches database subnets
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "database"
                                }
                                matchControllerRef: True
                            }
                            # Test Spec: Verify tags are applied
                            tags: {
                                Name: "test-vpc-subnetgroup-db-db"
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
