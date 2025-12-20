# Function Setup Notes

## Key Learnings from Tasks 1.2 and 1.3

### Using `up function generate` (IMPORTANT!)

**DO NOT** manually create function directories and files. Instead, use:

```bash
up function generate <function-name> <composition-path> --language kcl
```

Example:
```bash
up function generate vpc apis/vpc/composition.yaml --language kcl
```

This command automatically:
- Creates the `functions/<function-name>/` directory
- Generates `main.k` with proper imports and structure
- Creates `kcl.mod` with local model dependencies
- Sets up model symlink to `../../.up/kcl/models`
- Updates the composition.yaml to reference the function
- Configures the function in the pipeline

### Using `apiDependencies` in upbound.yaml

**DO NOT** add the KCL function runtime as a dependency manually. The `up function generate` command handles this automatically.

**DO** add provider dependencies using:

```bash
up dependency add <package-url>
```

Example:
```bash
up dependency add xpkg.upbound.io/upbound/provider-aws-ec2:v1.16.0
```

This updates the `upbound.yaml` file with the proper `dependsOn` section:

```yaml
spec:
  dependsOn:
  - apiVersion: pkg.crossplane.io/v1
    kind: Provider
    package: xpkg.upbound.io/upbound/provider-aws-ec2
    version: v1.16.0
```

### KCL Module Dependencies

When using `up function generate`, the generated `kcl.mod` uses **local path dependencies**:

```toml
[package]
name = "vpc"
version = "0.0.1"

[dependencies]
models = { path = "./model" }
```

The `model` directory is actually a symlink to `../../.up/kcl/models`, which contains all the generated type models from:
- The XRD definitions in `apis/`
- The provider APIs from `dependsOn` in `upbound.yaml`

**DO NOT** use OCI registry dependencies in `kcl.mod` like:
```toml
models = { oci = "oci://ghcr.io/upbound/platform-ref-upbound/functions-models", tag = "latest" }
```

This approach requires authentication and is not needed when using `up function generate`.

### Generated Model Imports

After running `up function generate`, the models are available as imports in your KCL code:

```kcl
# AWS Provider models
import models.io.upbound.aws.v1beta1 as awsv1beta1

# Your XRD models (automatically generated from apis/ definitions)
import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1

# Crossplane/Kubernetes models
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1
```

The XRD namespace `io.upbound.platform.aws.v1alpha1` comes from the XRD definition:
- Group: `aws.platform.upbound.io` (reversed becomes `io.upbound.platform.aws`)
- Version: `v1alpha1`
- Kind: `XVPC`

### Composition Pipeline Configuration

The generated composition.yaml includes the function in the pipeline:

```yaml
spec:
  mode: Pipeline
  pipeline:
  - functionRef:
      name: solutions-configuration-aws-vpcvpc  # Auto-generated function package name
    step: vpc
  - functionRef:
      name: function-kcl  # KCL runtime function
    input:
      apiVersion: krm.kcl.dev/v1alpha1
      kind: KCLInput
      spec:
        source: oci://ghcr.io/upbound/configuration-aws-vpc/functions-vpc:latest
    step: vpc-resources
```

### Project Build Process

To build the project:

```bash
up project build
```

This:
1. Collects resources from `apis/` and `functions/`
2. Generates language schemas for KCL from XRDs and provider APIs
3. Checks dependencies
4. Builds KCL functions
5. Packages everything into `.uppkg` files in `_output/`

**Requires Docker to be running** for building function images.

### Authentication

Before building, you may need to authenticate:

```bash
up login
```

This is required for:
- Pulling base images
- Accessing provider schemas
- Publishing packages

## Summary Workflow

1. **Initialize project** (if not done):
   ```bash
   up project init .
   ```

2. **Create XRD** in `apis/<resource>/definition.yaml`

3. **Create composition** in `apis/<resource>/composition.yaml` (basic structure)

4. **Add provider dependencies**:
   ```bash
   up dependency add xpkg.upbound.io/upbound/provider-aws-ec2:v1.16.0
   ```

5. **Generate function**:
   ```bash
   up function generate <name> apis/<resource>/composition.yaml --language kcl
   ```

6. **Build and test**:
   ```bash
   up project build
   up project run
   ```

7. **Implement function logic** in `functions/<name>/main.k`

8. **Iterate**: Build, test, refine

## Common Mistakes to Avoid

1. ❌ Manually creating function directories
   ✅ Use `up function generate`

2. ❌ Adding function-kcl to dependencies
   ✅ Let `up function generate` handle it

3. ❌ Using OCI dependencies in kcl.mod
   ✅ Use local path dependencies (auto-configured)

4. ❌ Forgetting to add provider dependencies
   ✅ Use `up dependency add` before generating functions

5. ❌ Building without Docker running
   ✅ Start Docker first

## Files Modified by `up function generate`

- `apis/<resource>/composition.yaml` - Adds pipeline steps
- `functions/<name>/` - Creates entire directory structure
- `.up/kcl/models/` - Generated type models (created during build)

## Next Steps After Scaffold

With the scaffold complete (Tasks 1.1-1.3), the next phase is implementing VPC resources:

1. **Task 2.1**: Implement basic VPC creation
2. **Task 2.2**: Implement subnet creation
3. **Task 2.3**: Implement Internet Gateway
4. **Task 2.4**: Implement NAT Gateway
5. **Task 2.5**: Implement route tables and routes
