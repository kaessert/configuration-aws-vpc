"""
Shared Base Specifications for Tests

Common base specifications used across composition tests to reduce duplication
using the DRY (Don't Repeat Yourself) principle.

Usage Pattern:
-------------
These base specs define common configuration that can be spread into test definitions
using the ** spread operator.

Example:
    import base_specs

    _test = metav1alpha1.CompositionTest {
        metadata.name: "test-my-feature"
        spec: {
            **base_specs.vpcBaseSpec
            xr: { ... }
            assertResources: [ ... ]
        }
    }

Alternative (Recommended):
-------------------------
Define base specs locally within each test file for better self-containment and
to avoid cross-directory import issues:

    # Within tests/test-my-feature/main.k
    _baseSpec = {
        compositionPath: "../../apis/vpc/composition.yaml"
        xrdPath: "../../apis/vpc/definition.yaml"
        timeoutSeconds: 60
        validate: True
    }

NOTE: Cross-directory imports in KCL have limitations. Local definitions within
test files are recommended for better self-containment.

Reference: Upbound composition test structure
"""


# Base specification for VPC composition tests
vpcBaseSpec = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: True
}

# Base specification for VPC composition tests (sequential, no validation)
vpcBaseSpecSequential = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 60
    validate: False  # Sequential tests mock status, validation would fail
}

# Base specification for composition tests with longer timeout
vpcBaseSpecLongTimeout = {
    compositionPath: "../../apis/vpc/composition.yaml"
    xrdPath: "../../apis/vpc/definition.yaml"
    timeoutSeconds: 120
    validate: True
}

# Common XR metadata for test resources
commonXRMetadata = {
    namespace: "default"
}

# Common tags for test resources
commonTestTags = {
    Environment: "test"
    ManagedBy: "upbound"
}

# Common provider config reference (Crossplane v2)
commonProviderConfigRef = {
    kind: "ProviderConfig"
    name: "default"
}

# Common management policies (Crossplane v2)
commonManagementPolicies = ["*"]
