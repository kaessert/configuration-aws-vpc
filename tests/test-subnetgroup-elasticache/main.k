
import models.io.upbound.awsm.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# Test: ElastiCache Subnet Group creation
# Spec Coverage: Task 3.5 - ElastiCache Subnet Group resource
# Verifies:
# - SubnetGroup is created when createElasticacheSubnetGroup: true
# - SubnetGroup uses subnetIdSelector to match elasticache subnets
# - SubnetGroup has correct tags

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-subnetgroup-elasticache"
        spec= {
            compositionPath: "../../apis/vpc/composition.yaml"
            xrdPath: "../../apis/vpc/definition.yaml"
            validate: False
            timeoutSeconds: 60

            xr: {
                apiVersion: "aws.platform.upbound.io/v1alpha1"
                kind: "VPC"
                metadata: {
                    name: "test-vpc-subnetgroup-elasticache"
                    namespace: "default"
                }
                spec: {
                    region: "us-west-2"
                    cidr: "10.0.0.0/16"
                    azs: [
                        "us-west-2a"
                        "us-west-2b"
                    ]
                    elasticacheSubnets: [
                        "10.0.31.0/24"
                        "10.0.32.0/24"
                    ]
                    createElasticacheSubnetGroup: True
                    tags: {
                        Name: "test-vpc-subnetgroup-elasticache"
                        Type: "elasticache"
                    }
                }
            }

            assertResources: [
                # Test Spec: Verify ElastiCache Subnet Group is created
                elasticachev1beta1.SubnetGroup{
                    metadata: {
                        name: "test-vpc-subnetgroup-elasticache-elasticache"
                    }
                    spec: {
                        forProvider: {
                            region: "us-west-2"
                            # Test Spec: Verify subnet selector matches elasticache subnets
                            subnetIdSelector: {
                                matchLabels: {
                                    "subnet-type": "elasticache"
                                }
                                matchControllerRef: True
                            }
                            # Test Spec: Verify tags are applied
                            tags: {
                                Name: "test-vpc-subnetgroup-elasticache-elasticache"
                                Type: "elasticache"
                            }
                        }
                    }
                }
            ]
        }
    }
]

items= _items
