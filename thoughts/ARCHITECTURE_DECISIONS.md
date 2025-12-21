# Architecture Decisions

This document records key architectural decisions for the AWS VPC Configuration project.

---

## Decision 1: Crossplane v2 with Namespaced Claims

**Status**: ACTIVE (Since: 2024-12-20)

**Decision**: This project uses Crossplane v2 with **namespaced claims**.

### Key Points

**What We Use**:
- ✅ XRD kind: `VPC` (NO X prefix)
- ✅ XRD scope: `Namespaced`
- ✅ All resources require `namespace: default`
- ✅ ProviderConfigs must be namespaced (`namespace: default`)
- ✅ API version: `aws.platform.upbound.io/v1alpha1`

**What We Do NOT Use**:
- ❌ Cluster-scoped composites (XVPC)
- ❌ Crossplane v1 XR/Claim pattern with claimNames
- ❌ Cluster-scoped ProviderConfigs (without namespace)
- ❌ Kind name with X prefix (XVPC)

### Example: Correct Usage

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: VPC              # ✅ CORRECT - NO X PREFIX
metadata:
  name: my-vpc
  namespace: default   # ✅ CRITICAL - ALWAYS REQUIRED
spec:
  region: us-west-2
  cidr: 10.0.0.0/16
  azs:
    - us-west-2a
    - us-west-2b
```

### Example: WRONG - Do NOT Use

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: XVPC             # ❌ WRONG - This project doesn't use XVPC
metadata:
  name: my-vpc
  # ❌ WRONG - Missing namespace field
spec:
  region: us-west-2
  cidr: 10.0.0.0/16
```

### XRD Definition (Source of Truth)

See `apis/vpc/definition.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: vpcs.aws.platform.upbound.io
spec:
  scope: Namespaced  # ← CRITICAL: Namespaced, not Cluster
  group: aws.platform.upbound.io
  names:
    kind: VPC        # ← CRITICAL: VPC, not XVPC
    plural: vpcs
```

### Rationale

1. **Crossplane v2 Compatibility**: Crossplane v2 recommends namespaced resources for multi-tenancy
2. **Resource Isolation**: Namespaced claims provide better isolation between different users/teams
3. **Upbound Platform Alignment**: Aligns with Upbound Spaces best practices
4. **Simplified Security**: Namespace-based RBAC is more straightforward than cluster-wide permissions

### Implications

1. **All Examples Must Use VPC**:
   - Examples in `examples/` directory use `kind: VPC` with `namespace: default`
   - Documentation (README, CLAUDE.md) must show `kind: VPC`

2. **ProviderConfigs Must Be Namespaced**:
   ```yaml
   apiVersion: aws.m.upbound.io/v1beta1  # Note: .m. for namespaced provider
   kind: ProviderConfig
   metadata:
     name: default
     namespace: default  # REQUIRED for namespaced claims
   ```

3. **E2E Tests Must Use Namespaced Resources**:
   - Test manifests use `kind: VPC` with `namespace: default`
   - ProviderConfig in `extraResources` must have `namespace: default`

4. **KCL Function Code**:
   - Import: `import models.io.upbound.platform.aws.v1alpha1 as awsv1alpha1`
   - Schema: `awsv1alpha1.VPC.spec{**oxr.spec}` (NOT XVPC)

### Common Mistakes

**Mistake 1**: Using `kind: XVPC`
```yaml
kind: XVPC  # ❌ WRONG - This will not work
```
**Why Wrong**: The XRD defines `kind: VPC`, not `XVPC`. Kubernetes will reject this.

**Mistake 2**: Omitting namespace field
```yaml
kind: VPC
metadata:
  name: my-vpc
  # ❌ WRONG - Missing namespace
```
**Why Wrong**: Namespaced resources require a namespace. Without it, the resource cannot be created.

**Mistake 3**: Cluster-scoped ProviderConfig
```yaml
kind: ProviderConfig
metadata:
  name: default
  # ❌ WRONG - Missing namespace for namespaced claim
```
**Why Wrong**: Namespaced claims require namespaced ProviderConfigs in the same namespace.

### Historical Context

This project migrated to Crossplane v2 on 2024-12-09. Key changes:
- Changed from `apiextensions.crossplane.io/v1` to `v2`
- Added `scope: Namespaced` to XRD
- Removed `claimNames` section (v2 doesn't support XR/Claim pattern)
- Changed kind from `XVPC` to `VPC` (removed X prefix)
- Updated all examples to include `namespace: default`

See `thoughts/planning/tasks.md` for migration details.

### References

- XRD Definition: `apis/vpc/definition.yaml`
- Working Example: `examples/simple-vpc.yaml`
- E2E Test Example: `tests/e2etest-e2etest-xvpc-basic/main.k`
- Migration Task: `thoughts/planning/tasks.md` (Task 1.5)

### Validation

To verify this architecture is correctly implemented:

1. Check XRD: `grep -A 10 "kind: CompositeResourceDefinition" apis/vpc/definition.yaml`
   - Should show `scope: Namespaced`
   - Should show `kind: VPC` (not XVPC)

2. Check Examples: `grep -r "kind: VPC" examples/`
   - All should show `kind: VPC` with `namespace: default`

3. Check Tests: `grep -r "kind:" tests/e2etest-*/main.k`
   - All should show `kind: "VPC"` with `namespace: "default"`

If you find `kind: XVPC` anywhere in examples or user-facing documentation, it's a documentation error that needs to be fixed.

---

## Decision 2: Test-Driven Development with MANDATORY E2E Tests

**Status**: ACTIVE (Since: 2024-12-20)

**Decision**: All features require BOTH composition tests AND E2E tests before completion.

### Key Points

1. **Composition tests** validate KCL logic (fast, isolated)
2. **E2E tests** validate real AWS behavior (slow, required)
3. **E2E tests are MANDATORY** - no feature is complete without them

### Rationale

- Composition tests validate KCL syntax and logic
- E2E tests validate actual AWS API behavior
- Without E2E validation, we risk shipping features that don't work in real AWS
- Discovery: Features can pass composition tests but fail in real AWS

See `CLAUDE.md` and `thoughts/TDD_STRATEGY.md` for full details.

---

## Decision 3: Provider-AWS-EC2 with Namespaced Resources

**Status**: ACTIVE

**Decision**: Use `provider-aws-ec2` (Upbound family provider) with namespaced resources.

### Key Points

- Provider API Group: `ec2.aws.m.upbound.io` (note the `.m.` suffix for namespaced)
- Managed Resources: All use `.m.` API group (VPC, Subnet, InternetGateway, etc.)
- ProviderConfig: Uses `aws.m.upbound.io/v1beta1` (namespaced variant)

### Example

```kcl
import models.io.crossplane.upbound.aws.ec2.v1beta1 as awsec2

vpc = awsec2.VPC{
    metadata.name = "my-vpc"
    spec = {
        forProvider = {
            cidrBlock = "10.0.0.0/16"
            region = "us-west-2"
        }
        providerConfigRef = {
            name = "default"
            kind = "ProviderConfig"  # v2 requires explicit kind
        }
        managementPolicies = ["*"]  # v2 replaces deletionPolicy
    }
}
```

### ProviderConfig for Namespaced Resources

```yaml
apiVersion: aws.m.upbound.io/v1beta1  # CRITICAL: Use .m. suffix
kind: ProviderConfig
metadata:
  name: default
  namespace: default  # REQUIRED for namespaced claims
spec:
  credentials:
    source: Upbound  # For Upbound Spaces managed credentials
  assumeRoleChain:
    - roleARN: arn:aws:iam::123456789012:role/my-role
```

---

## Future Decisions

Document future architecture decisions here as they are made.
