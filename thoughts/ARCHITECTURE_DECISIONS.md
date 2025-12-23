# Architecture Decisions

This document records key architectural decisions made for the AWS VPC configuration project.

---

## Decision 1: Namespaced VPC Claims (Crossplane v2)

**Date**: 2024
**Status**: Active
**Context**: Crossplane v2 introduces namespaced resources to improve multi-tenancy and isolation.

### Decision

This project uses Crossplane v2 with **namespaced claims**.

### What This Means

- **XRD kind**: `VPC` (NO X prefix for claims)
- **All resources require**: `namespace: default`
- **ProviderConfigs must be namespaced**: Use `aws.m.upbound.io` API version

### Implementation Details

**Claim vs Composite**:
- **Claim**: `kind: VPC` (namespaced, user-facing)
- **Composite**: `kind: XVPC` (cluster-scoped, internal)
- **This project uses Claims for E2E tests and examples**

**API Versions**:
- Namespaced managed resources: `aws.m.upbound.io/v1beta1`
- Parent provider: `aws.upbound.io/v1beta1`

### Common Mistakes

❌ **DON'T**:
- Use `kind: XVPC` in user-facing examples or test claims
- Omit `namespace: default` from ProviderConfig for namespaced claims
- Use cluster-scoped patterns when working with namespaced resources

✅ **DO**:
- Use `kind: VPC` for all claims and E2E tests
- Always specify `namespace: default` in ProviderConfig
- Use `aws.m.upbound.io` for namespaced managed resources

### Consequences

**Positive**:
- Better multi-tenancy support
- Resource isolation between namespaces
- Aligns with Crossplane v2 best practices

**Negative**:
- Requires namespace specification in all resources
- Different from cluster-scoped Crossplane v1 patterns
- Documentation must be clear about namespaced vs cluster-scoped

### References

- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Implementation patterns
- [TESTING_REFERENCE.md](TESTING_REFERENCE.md) - ProviderConfig setup for E2E tests
- [GLOSSARY.md](GLOSSARY.md) - Terminology (Claim, Composite, XRD)

---

## Decision 2: Composition Pipeline with function-auto-ready

**Date**: 2024
**Status**: Active
**Context**: Crossplane v2 compositions require explicit Ready condition management.

### Decision

All compositions MUST include `function-auto-ready` as the last pipeline step.

### Rationale

Without this function:
- XRs never reach "Ready" status
- E2E tests timeout waiting for resources
- Resource readiness cannot be determined

### Implementation

```yaml
# apis/vpc/composition.yaml
spec:
  mode: Pipeline
  pipeline:
  - functionRef:
      name: solutions-configuration-aws-vpcvpc
    step: vpc-resources
  - functionRef:
      name: crossplane-contrib-function-auto-ready  # MANDATORY
    step: crossplane-contrib-function-auto-ready
```

### References

- [KCL_REFERENCE.md → Generating Functions](KCL_REFERENCE.md#generating-functions)
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Composition Pipeline Requirements

---

## Future Decisions

Document new architectural decisions here as they arise. Use the format:
- **Decision Number**: Sequential numbering
- **Date**: When decided
- **Status**: Active, Deprecated, or Superseded
- **Context**: Why the decision was needed
- **Decision**: What was decided
- **Consequences**: Positive and negative impacts
- **References**: Related documentation
