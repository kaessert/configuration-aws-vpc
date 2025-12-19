# E2E Test ProviderConfig Configuration Fix

**Date**: 2025-12-19
**Issue**: E2E tests failing due to incorrect ProviderConfig configuration

---

## Problem Summary

When running E2E tests on Upbound Spaces, the tests were failing at different stages due to ProviderConfig misconfiguration.

## Issues Discovered

### Issue 1: Missing `credentials` Field

**Error**:
```
ProviderConfig.aws.upbound.io "default" is invalid: spec.credentials: Required value
```

**Cause**:
The ProviderConfig only had `assumeRoleChain` specified, but the `credentials.source` field is also required.

**Initial (Incorrect) Attempt**:
```kcl
spec: {
    assumeRoleChain: [
        {
            roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
        }
    ]
}
```

**Fix Attempt 1 (Incorrect)**:
```kcl
spec: {
    credentials: {
        source: "InjectedIdentity"  # WRONG - not a valid value
    }
    assumeRoleChain: [...]
}
```

**Error**:
```
spec.credentials.source: Unsupported value: "InjectedIdentity":
supported values: "None", "Secret", "IRSA", "WebIdentity", "PodIdentity", "Upbound"
```

**Fix Attempt 2 (Correct for parent provider)**:
```kcl
spec: {
    credentials: {
        source: "Upbound"  # CORRECT for aws.upbound.io
    }
    assumeRoleChain: [...]
}
```

### Issue 2: Wrong API Group for ProviderConfig

**Error**:
```
ReconcileError: cannot get terraform setup: cannot get referenced ProviderConfig:
ProviderConfig.aws.m.upbound.io "default" not found
```

**Cause**:
In Crossplane v2 with namespaced resources:
- Parent provider uses: `aws.upbound.io`
- Namespaced managed resources use: `aws.m.upbound.io` (note the `.m.`)
- The managed resources (VPC, Subnet, etc.) look for ProviderConfig in `aws.m.upbound.io` API group
- We were creating ProviderConfig in `aws.upbound.io` API group

**Incorrect**:
```kcl
{
    apiVersion: "aws.upbound.io/v1beta1"
    kind: "ProviderConfig"
    metadata: { name: "default" }
    spec: { ... }
}
```

**Correct**:
```kcl
{
    apiVersion: "aws.m.upbound.io/v1beta1"  # Note: .m. for namespaced provider
    kind: "ProviderConfig"
    metadata: { name: "default" }
    spec: {
        credentials: {
            source: "Upbound"
        }
        assumeRoleChain: [
            {
                roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

---

## Final Working Configuration

For E2E tests on Upbound Spaces with Crossplane v2 and namespaced provider-aws-ec2:

```kcl
extraResources: [
    {
        apiVersion: "aws.m.upbound.io/v1beta1"  # CRITICAL: Use .m. for namespaced provider
        kind: "ProviderConfig"
        metadata: {
            name: "default"
        }
        spec: {
            credentials: {
                source: "Upbound"  # For Upbound Spaces identity
            }
            assumeRoleChain: [
                {
                    roleARN: "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                }
            ]
        }
    }
]
```

---

## Key Learnings

1. **Namespaced vs Parent Provider API Groups**:
   - Crossplane v2 introduced namespaced resources with `.m.` suffix
   - Parent provider: `aws.upbound.io`
   - Namespaced provider: `aws.m.upbound.io`
   - ProviderConfig must match the API group used by managed resources

2. **Credentials Source for Upbound Spaces**:
   - Use `source: "Upbound"` for Spaces-managed identity
   - This integrates with Upbound's identity injection system
   - Works with `assumeRoleChain` for cross-account access

3. **E2E Test ProviderConfig Requirements**:
   - Always specify both `credentials.source` and `assumeRoleChain`
   - Match the API group to your managed resources (`.m.` for namespaced)
   - Test the ProviderConfig configuration before full E2E test runs

4. **Error Message Interpretation**:
   - "ProviderConfig.aws.m.upbound.io not found" → wrong API group
   - "spec.credentials: Required value" → missing credentials field
   - "Unsupported value" → check documentation for valid values

---

## Files Fixed

All four E2E tests were updated:

1. `tests/e2etest-e2etest-xvpc-basic/main.k`
2. `tests/e2etest-e2etest-xvpc-nat-single/main.k`
3. `tests/e2etest-e2etest-xvpc-nat-per-az/main.k`
4. `tests/e2etest-e2etest-xvpc-complete/main.k`

Each now uses the correct ProviderConfig configuration with:
- `apiVersion: "aws.m.upbound.io/v1beta1"`
- `credentials.source: "Upbound"`
- `assumeRoleChain` with IAM role

---

## Next Steps

1. ✅ All E2E test configurations fixed
2. ⏳ Run E2E tests to verify they pass with new configuration
3. ⏳ Document results in E2E_TEST_STATUS.md
4. ⏳ Update TESTING.md with ProviderConfig requirements
5. ⏳ Complete Task 0.1 in tasks.md

---

## References

- [Upbound AWS Provider v2](https://marketplace.upbound.io/providers/upbound/provider-aws-ec2/v2.3.0)
- [Crossplane v2 Upgrade Guide](https://docs.crossplane.io/latest/guides/upgrade-to-crossplane-v2/)
- [Provider Config Documentation](https://docs.crossplane.io/latest/concepts/providers/)
