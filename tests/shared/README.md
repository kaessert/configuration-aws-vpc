# Shared Test Utilities

This directory contains reusable utilities for composition tests to reduce code duplication and ensure consistency.

## Contents

### `conditions.k`
Standard ready conditions for sequential composition tests using `observedResources`.

**Use cases:**
- Simulating resource readiness in sequential tests
- Testing resource dependencies
- Validating conditional resource creation

**Exports:**
- `readyConditions` - Standard ready/synced conditions
- `pendingConditions` - Resource creation in progress
- `failedConditions` - Resource creation failed

### `base_specs.k`
Common base specifications for composition tests.

**Use cases:**
- Reducing boilerplate in test definitions
- Ensuring consistent test configuration
- DRY principle for test structure

**Exports:**
- `vpcBaseSpec` - Standard VPC composition test config
- `vpcBaseSpecSequential` - For tests with `validate: False`
- `vpcBaseSpecLongTimeout` - For tests needing >60s timeout
- `commonProviderConfigRef` - Standard Crossplane v2 provider config
- `commonManagementPolicies` - Standard management policies

### `builders.k`
Resource builder functions for creating test assertions.

**Use cases:**
- Generating consistent resource definitions
- Reducing boilerplate in assertions
- Helper functions for naming and tagging

**Exports:**
- `buildVPC` - Build VPC resource definition
- `buildSubnet` - Build Subnet resource definition
- `buildInternetGateway` - Build IGW resource definition
- `buildNATGateway` - Build NAT Gateway resource definition
- `buildRouteTable` - Build Route Table resource definition
- `buildSecurityGroup` - Build Security Group resource definition
- `buildNetworkACL` - Build Network ACL resource definition
- `mergeTags` - Helper to merge tag dictionaries
- `buildSubnetName` - Helper for subnet naming convention
- `buildResourceName` - Helper for generic resource naming

---

## Usage

### Cross-Directory Import Limitations

**IMPORTANT:** KCL has limitations with cross-directory imports in the test environment:
- Each test directory is containerized and run in isolation
- Cross-directory imports may not resolve correctly
- Shared modules work best as **reference templates**

### Recommended Approach: Copy Patterns Locally

Instead of importing from `tests/shared/`, **copy the patterns into your test directory**:

#### Example: Using Conditions

```kcl
# tests/test-my-feature/conditions.k (copied from shared/conditions.k)
import datetime

readyConditions = [
    { reason: "Available", status: "True", type: "Ready", lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ") },
    { reason: "Success", status: "True", type: "LastAsyncOperation", lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ") },
    { reason: "ReconcileSuccess", status: "True", type: "Synced", lastTransitionTime: datetime.now("%Y-%m-%dT%H:%M:%SZ") }
]
```

```kcl
# tests/test-my-feature/main.k
import conditions

observedResources: [
    ec2v1beta1.VPC {
        **_vpcResource
        status: {
            atProvider: { id: "vpc-12345" }
            conditions: conditions.readyConditions  # Local import works
        }
    }
]
```

#### Example: Using Base Specs

```kcl
# tests/test-my-feature/main.k
# Define locally instead of importing
_baseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

_test = metav1alpha1.CompositionTest {
    metadata.name: "test-my-feature"
    spec: {
        **_baseSpec  # Use spread operator
        xr: { ... }
        assertResources: [ ... ]
    }
}
```

#### Example: Using Builders

```kcl
# tests/test-my-feature/main.k
# Define builder locally
buildSubnet = lambda config: {
    ec2v1beta1.Subnet {
        metadata: { name: config.name }
        spec: {
            providerConfigRef: { kind: "ProviderConfig", name: "default" }
            managementPolicies: ["*"]
            forProvider: {
                region: config.region
                cidrBlock: config.cidrBlock
                availabilityZone: config.az
                vpcIdSelector: { matchControllerRef: True }
                tags: config.tags
            }
        }
    }
}

# Use builder
_subnet = buildSubnet({
    name: "subnet-test",
    region: "us-west-2",
    cidrBlock: "10.0.1.0/24",
    az: "us-west-2a",
    tags: { Type: "public" }
})
```

---

## Alternative: Testing Cross-Directory Imports

If you want to test whether cross-directory imports work in your environment:

```kcl
# tests/test-import-check/main.k
import sys
sys.path.append("../shared")  # Add shared to path (may not work)
import conditions

# Or try relative import
import ../shared/conditions as conditions

# Use imported conditions
_conditions = conditions.readyConditions
```

**Expected result:** This will likely fail during test execution because the test container doesn't include the `tests/shared/` directory.

---

## Test Organization Patterns

### Pattern 1: Simple Tests (No Sequential Dependencies)
- Define `_baseSpec` locally in `main.k`
- Use spread operator for DRY
- No need for separate files

### Pattern 2: Resource-Focused Bundles (3-5 Variants)
- Define `_baseSpec` locally in `main.k`
- Use spread operator for multiple test variants
- Keep all tests in single `main.k` file

### Pattern 3: Parameterized Tests (5+ Variants)
- Define `_baseSpec` locally
- Define `_variants` array with data
- Use lambda builder function to generate tests

### Pattern 4: Sequential Tests (Resource Dependencies)
- Create local `conditions.k` in test directory (copy from shared)
- Create local `resources.k` for base resource definitions
- Use `observedResources` with cumulative building
- Import locally: `import conditions`, `import resources`

---

## Benefits of Shared Utilities

Even though cross-directory imports may not work, this shared directory provides:

1. **Reference Templates** - Copy-paste source for common patterns
2. **Consistency** - Standard patterns documented in one place
3. **Documentation** - Clear examples of builder and condition patterns
4. **Maintenance** - Update patterns here, then propagate to tests
5. **Onboarding** - New developers see standard patterns immediately

---

## Adding New Utilities

When adding new shared utilities:

1. **Add to appropriate file** (`conditions.k`, `base_specs.k`, or `builders.k`)
2. **Document with comments** - Explain purpose and usage
3. **Provide usage examples** - Show how to use the utility
4. **Update this README** - Add to exports list and examples
5. **Test locally first** - Define in a test file to validate pattern
6. **Consider limitations** - Remember cross-directory imports may not work

---

## Migration Guide

To migrate existing tests to use these patterns:

### Step 1: Identify Duplication
Find tests with repeated boilerplate:
```bash
grep -r "_baseSpec" tests/test-*/main.k
```

### Step 2: Extract Common Patterns
Create local definitions based on shared utilities:
- Copy `_baseSpec` pattern from `base_specs.k`
- Copy builder functions from `builders.k` if needed
- Copy conditions from `conditions.k` for sequential tests

### Step 3: Apply DRY Principle
Use spread operator and builders to eliminate duplication within test file.

### Step 4: Consolidate Related Tests
Group related test variants in single directory using Resource-Focused Bundle pattern.

---

## References

- **Test Refactoring Plan**: `thoughts/tasks/REFACTOR_TESTS.md`
- **KCL Documentation**: https://kcl-lang.io/
- **Upbound Test Framework**: Composition test structure
- **Crossplane v2**: Provider config and management policies
