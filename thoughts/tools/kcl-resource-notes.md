# KCL Resource Creation Notes

## Key Learning: How to Create Managed Resources in KCL

### Correct Pattern

KCL composition functions return **plain objects/dictionaries** representing Crossplane managed resources. Do NOT wrap them in `kubernetesv1alpha2.Object`.

```kcl
items = [
    {
        apiVersion = "ec2.aws.upbound.io/v1beta1"
        kind = "VPC"
        metadata = _metadata("vpc") | {
            name = "vpc-name"
            labels = { key = "value" }
        }
        spec = {
            forProvider = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                enableDnsHostnames = true
                enableDnsSupport = true
                tags = { Name = "my-vpc" }
            }
        }
    }
]
```

### Structure Breakdown

1. **apiVersion**: The API group and version from the provider
   - Format: `<resource-group>.<provider>.upbound.io/<version>`
   - Example: `ec2.aws.upbound.io/v1beta1`

2. **kind**: The resource type (capitalized)
   - Examples: `VPC`, `Subnet`, `InternetGateway`

3. **metadata**: Resource metadata
   - **MUST** include `_metadata("resource-name")` annotation for composition tracking
   - Merge with `|` operator to add name and labels
   - The annotation `"krm.kcl.dev/composition-resource-name"` is critical for resource identity

4. **spec.forProvider**: The actual resource configuration
   - Matches the provider's CRD spec
   - See provider documentation for available fields

### Finding Provider API Information

Use the [Upbound Marketplace](https://marketplace.upbound.io/) to find:
- Provider package names
- API groups
- Available resources
- Resource schemas

Example for AWS EC2 resources:
- Provider: `xpkg.upbound.io/upbound/provider-aws-ec2`
- API Group: `ec2.aws.upbound.io`
- Version: `v1beta1`

### Provider Models in KCL

After adding a provider dependency with `up dependency add`, the models are NOT always generated in `.up/kcl/models/`.

Instead, you reference resources directly using their API group structure in plain objects. The KCL function runtime handles the conversion to proper Crossplane managed resources.

### Metadata Annotation Pattern

Always use the `_metadata()` helper function:

```kcl
_metadata = lambda name: str -> any {
    { annotations = { "krm.kcl.dev/composition-resource-name" = name }}
}
```

This annotation:
- Uniquely identifies resources within the composition
- Enables resource tracking and updates
- Required for composition function to work correctly

Usage:
```kcl
metadata = _metadata("unique-resource-name") | {
    name = "actual-k8s-name"
    labels = {...}
}
```

### Common Mistakes

1. ❌ Wrapping in `kubernetesv1alpha2.Object`
   ```kcl
   # WRONG
   kubernetesv1alpha2.Object{
       spec.forProvider.manifest = {...}
   }
   ```

2. ❌ Forgetting the `_metadata()` annotation
   ```kcl
   # WRONG
   metadata = {
       name = "my-resource"
   }
   ```

3. ❌ Wrong API group format
   ```kcl
   # WRONG
   apiVersion = "v1beta1"  # Missing group
   ```

4. ✅ Correct pattern
   ```kcl
   {
       apiVersion = "ec2.aws.upbound.io/v1beta1"
       kind = "VPC"
       metadata = _metadata("vpc") | { name = "my-vpc" }
       spec.forProvider = {...}
   }
   ```

### Resource Dependencies and References

To reference one resource from another, use selectors:

```kcl
spec.forProvider = {
    # Reference by name
    vpcIdRef = {
        name = "vpc-name"
    }

    # Or by selector (preferred)
    vpcIdSelector = {
        matchControllerRef = True  # Matches parent composite
    }
}
```

### Testing

After implementing resources:

1. Build: `up project build`
2. Run locally: `up project run`
3. Apply example: `kubectl apply -f examples/simple-vpc.yaml`
4. Check resources: `kubectl get composite,managed`
5. Inspect: `kubectl describe xvpc test-vpc`
6. Stop: `up project stop`

## Next Steps

With VPC creation working, next resources to implement:
1. Subnets (public, private, database, elasticache, redshift, intra)
2. Internet Gateway
3. NAT Gateway with Elastic IPs
4. Route Tables and Routes
5. Route Table Associations
