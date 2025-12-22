"""
VPC Subnet Groups Module

Generates AWS subnet group resources for managed database and caching services:
- RDS DB Subnet Groups
- ElastiCache Subnet Groups
- Redshift Subnet Groups

These subnet groups are required for deploying RDS, ElastiCache, and Redshift resources.
"""

import models.io.upbound.awsm.rds.v1beta1 as rdsv1beta1
import models.io.upbound.awsm.elasticache.v1beta1 as elasticachev1beta1
import models.io.upbound.awsm.redshift.v1beta1 as redshiftv1beta1

# Generate DB Subnet Group for RDS instances
_generateDBSubnetGroup = lambda oxr: any, dxr: any, ocds: any, dcds: any, region: str, common_tags: {str:} {
    _database_subnets = oxr?.spec?.databaseSubnets or []
    _create_flag = oxr?.spec?.createDatabaseSubnetGroup
    _name = oxr?.metadata?.name or "vpc"
    _custom_name = oxr?.spec?.databaseSubnetGroupName or ""
    _subnet_group_name = _custom_name if _custom_name else "${_name}-db"
    _tags = oxr?.spec?.databaseSubnetGroupTags or {}

    # Create subnet group if flag is explicitly True OR if database subnets exist and flag is not explicitly False
    _should_create = _create_flag == True if _create_flag != None else len(_database_subnets) > 0

    _items = [
        rdsv1beta1.SubnetGroup{
            metadata.name = "${_name}-db"
            metadata.annotations = {
                "krm.kcl.dev/composition-resource-name" = "${_name}-db-subnet-group"
            }
            spec = {
                forProvider = {
                    region = region
                    # Use label selector to match database subnets
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type" = "database"
                        }
                        matchControllerRef = True
                    }
                    tags = common_tags | _tags | {
                        Name = _subnet_group_name
                        Type = "database"
                    }
                }
            }
        }
    ] if _should_create and len(_database_subnets) > 0 else []

    _items
}

# Generate ElastiCache Subnet Group
_generateElastiCacheSubnetGroup = lambda oxr: any, dxr: any, ocds: any, dcds: any, region: str, common_tags: {str:} {
    _elasticache_subnets = oxr?.spec?.elasticacheSubnets or []
    _create_flag = oxr?.spec?.createElasticacheSubnetGroup
    _name = oxr?.metadata?.name or "vpc"
    _custom_name = oxr?.spec?.elasticacheSubnetGroupName or ""
    _subnet_group_name = _custom_name if _custom_name else "${_name}-elasticache"
    _tags = oxr?.spec?.elasticacheSubnetGroupTags or {}

    # Create subnet group if flag is explicitly True OR if elasticache subnets exist and flag is not explicitly False
    _should_create = _create_flag == True if _create_flag != None else len(_elasticache_subnets) > 0

    _items = [
        elasticachev1beta1.SubnetGroup{
            metadata.name = "${_name}-elasticache"
            metadata.annotations = {
                "krm.kcl.dev/composition-resource-name" = "${_name}-elasticache-subnet-group"
            }
            spec = {
                forProvider = {
                    region = region
                    # Use label selector to match elasticache subnets
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type" = "elasticache"
                        }
                        matchControllerRef = True
                    }
                    tags = common_tags | _tags | {
                        Name = _subnet_group_name
                        Type = "elasticache"
                    }
                }
            }
        }
    ] if _should_create and len(_elasticache_subnets) > 0 else []

    _items
}

# Generate Redshift Subnet Group
_generateRedshiftSubnetGroup = lambda oxr: any, dxr: any, ocds: any, dcds: any, region: str, common_tags: {str:} {
    _redshift_subnets = oxr?.spec?.redshiftSubnets or []
    _create_flag = oxr?.spec?.createRedshiftSubnetGroup
    _name = oxr?.metadata?.name or "vpc"
    _custom_name = oxr?.spec?.redshiftSubnetGroupName or ""
    _subnet_group_name = _custom_name if _custom_name else "${_name}-redshift"
    _tags = oxr?.spec?.redshiftSubnetGroupTags or {}

    # Create subnet group if flag is explicitly True OR if redshift subnets exist and flag is not explicitly False
    _should_create = _create_flag == True if _create_flag != None else len(_redshift_subnets) > 0

    _items = [
        redshiftv1beta1.SubnetGroup{
            metadata.name = "${_name}-redshift"
            metadata.annotations = {
                "krm.kcl.dev/composition-resource-name" = "${_name}-redshift-subnet-group"
            }
            spec = {
                forProvider = {
                    region = region
                    # Use label selector to match redshift subnets
                    subnetIdSelector = {
                        matchLabels = {
                            "subnet-type" = "redshift"
                        }
                        matchControllerRef = True
                    }
                    tags = common_tags | _tags | {
                        Name = _subnet_group_name
                        Type = "redshift"
                    }
                }
            }
        }
    ] if _should_create and len(_redshift_subnets) > 0 else []

    _items
}

# Main function to generate all subnet groups
generateSubnetGroups = lambda oxr: any, dxr: any, ocds: any, dcds: any, region: str, common_tags: {str:} {
    _db_subnet_groups = _generateDBSubnetGroup(oxr, dxr, ocds, dcds, region, common_tags)
    _elasticache_subnet_groups = _generateElastiCacheSubnetGroup(oxr, dxr, ocds, dcds, region, common_tags)
    _redshift_subnet_groups = _generateRedshiftSubnetGroup(oxr, dxr, ocds, dcds, region, common_tags)

    _db_subnet_groups + _elasticache_subnet_groups + _redshift_subnet_groups
}
