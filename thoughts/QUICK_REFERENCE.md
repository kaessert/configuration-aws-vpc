# Quick Reference: VPC vs XVPC

**Last Updated**: 2025-12-20

---

## What This Project Uses

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: VPC              # ✅ CORRECT - NO X PREFIX
metadata:
  name: my-vpc
  namespace: default   # ✅ CRITICAL - ALWAYS REQUIRED
spec:
  region: us-west-2
  cidr: 10.0.0.0/16
```

---

## What NOT to Use

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

---

## Key Rules

1. **Kind**: ALWAYS use `VPC` (NO X prefix)
2. **Namespace**: ALWAYS include `namespace: default`
3. **ProviderConfig**: MUST be namespaced (`namespace: default`)
4. **API Group**: Use `aws.platform.upbound.io/v1alpha1`

---

## Why VPC and Not XVPC?

**XRD Definition** (`apis/vpc/definition.yaml`):
```yaml
spec:
  scope: Namespaced  # ← Namespaced, not Cluster
  names:
    kind: VPC        # ← VPC, not XVPC
```

The XRD (source of truth) defines:
- `scope: Namespaced` - All resources must be namespaced
- `kind: VPC` - The kind is VPC without the X prefix

---

## ProviderConfig for Namespaced Claims

```yaml
apiVersion: aws.m.upbound.io/v1beta1  # Note: .m. for namespaced
kind: ProviderConfig
metadata:
  name: default
  namespace: default  # REQUIRED for namespaced claims
spec:
  credentials:
    source: Upbound
  assumeRoleChain:
    - roleARN: arn:aws:iam::123456789012:role/my-role
```

**Critical Points**:
- API version: `aws.m.upbound.io/v1beta1` (note the `.m.` suffix)
- Namespace: `default` (MUST match claim namespace)
- Source: `Upbound` (for Upbound Spaces managed credentials)

---

## E2E Test Structure

```kcl
manifests: [
    {
        apiVersion: "aws.platform.upbound.io/v1alpha1"
        kind: "VPC"  # ✅ CORRECT - NO X PREFIX
        metadata: {
            name: "e2e-test-vpc"
            namespace: "default"  # ✅ REQUIRED
        }
        spec: {
            # your config
        }
    }
]

extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"  # Note: .m. suffix
        kind: "ProviderConfig"
        metadata: {
            name: "default"
            namespace: "default"  # ✅ REQUIRED
        }
        spec: {
            credentials: { source: "Upbound" }
            assumeRoleChain: [
                { roleARN: "arn:aws:iam::123456789012:role/my-role" }
            ]
        }
    }
]
```

---

## Common Mistakes

### Mistake 1: Using XVPC

```yaml
kind: XVPC  # ❌ WRONG
```

**Error**: XRD doesn't define XVPC, only VPC. Kubernetes will reject this.

**Fix**: Use `kind: VPC`

### Mistake 2: Missing Namespace

```yaml
kind: VPC
metadata:
  name: my-vpc
  # ❌ WRONG - Missing namespace
```

**Error**: Namespaced resources require a namespace. Resource creation will fail.

**Fix**: Add `namespace: default`

### Mistake 3: Cluster-scoped ProviderConfig

```yaml
kind: ProviderConfig
metadata:
  name: default
  # ❌ WRONG - Missing namespace
```

**Error**: Namespaced claims require namespaced ProviderConfigs. Test will hang.

**Fix**: Add `namespace: default`

### Mistake 4: Wrong ProviderConfig API Version

```yaml
apiVersion: aws.upbound.io/v1beta1  # ❌ WRONG - missing .m.
```

**Error**: Managed resources look for ProviderConfig in `aws.m.upbound.io` API group.

**Fix**: Use `aws.m.upbound.io/v1beta1` (note the `.m.` suffix)

---

## Validation Checklist

Before committing, verify:

- [ ] All examples use `kind: VPC` (not XVPC)
- [ ] All examples include `namespace: default`
- [ ] All ProviderConfigs use `aws.m.upbound.io/v1beta1`
- [ ] All ProviderConfigs include `namespace: default`
- [ ] No references to `kind: XVPC` in user-facing docs

---

## File References

**Source of Truth**:
- XRD: `apis/vpc/definition.yaml` (defines kind: VPC, scope: Namespaced)

**Correct Examples**:
- `examples/simple-vpc.yaml` - Shows correct usage
- `tests/e2etest-e2etest-xvpc-basic/main.k` - E2E test structure

**Documentation**:
- `thoughts/ARCHITECTURE_DECISIONS.md` - Full rationale
- `CLAUDE.md` - Project instructions

---

## Help

**If you see XVPC in documentation**:
- It's a documentation error
- Report it immediately
- Refer to this guide for correct usage

**If you're unsure**:
- Check the XRD: `apis/vpc/definition.yaml`
- Check working examples: `examples/simple-vpc.yaml`
- Check this guide: `thoughts/QUICK_REFERENCE.md`

---

**Remember**: VPC, not XVPC. Always namespaced. Always `namespace: default`.
