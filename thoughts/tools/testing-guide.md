# Upbound Testing Guide

## Overview

This guide covers testing strategies for Upbound projects, including composition tests and end-to-end (E2E) tests. Based on Upbound's unified testing approach introduced in Up CLI v0.38+.

## Testing Types

### 1. Composition Tests (Unit Tests)

**Purpose**: Validate composition logic without requiring a live Kubernetes environment by simulating the composition controller's behavior.

**When to use**:
- Testing resource creation logic
- Validating conditional resource generation
- Testing resource dependencies and ordering
- Verifying resource specifications match inputs
- Fast feedback during development

**Key characteristics**:
- Models a single composition controller loop
- Uses mock data instead of live resources
- Fast execution (no cluster required)
- Can test with various XR inputs
- Validates resource structure and relationships

### 2. End-to-End (E2E) Tests

**Purpose**: Validate compositions in real cloud environments, ensuring resources are actually created, configured, and can be deleted properly.

**When to use**:
- Verifying actual AWS resource creation
- Testing provider authentication
- Validating resource readiness conditions
- Testing complete lifecycle (create, update, delete)
- Final validation before release

**Key characteristics**:
- Requires real control plane (auto-provisioned)
- Creates actual cloud resources
- Slower execution (minutes vs seconds)
- Tests complete system integration
- Requires cloud credentials and Upbound account

### 3. Composition Rendering (Preview)

**Purpose**: Preview composed resources locally before deployment.

**When to use**:
- Quick validation during development
- Understanding what resources will be created
- Debugging composition logic
- Documentation and examples

---

## Testing Workflow

### Development Workflow

```
1. Write/modify composition function
2. Preview with: up composition render
3. Write composition test
4. Run test: up test run tests/my-test
5. Fix issues, repeat 2-4
6. Write E2E test (for critical paths)
7. Run E2E: up test run tests/my-test --e2e
8. Commit with passing tests
```

### CI/CD Workflow

```
1. Push to branch
2. GitHub Actions: Run composition tests (fast)
3. Create PR
4. Add "run-e2e-tests" label
5. GitHub Actions: Run E2E tests (slow, requires secrets)
6. Review and merge
```

---

## Composition Tests

### Test Structure

**Languages supported**: KCL, Python, YAML

**Test directory structure**:
```
tests/
├── xvpc-simple/
│   ├── main.k (or main.py or test.yaml)
│   └── README.md (optional)
├── xvpc-multi-az/
│   └── main.k
└── xvpc-private-subnets/
    └── main.k
```

### Generating Composition Tests

```bash
# Generate KCL test
up test generate xvpc-simple --language=kcl

# Generate Python test
up test generate xvpc-complex --language=python

# Generate YAML test (default)
up test generate xvpc-basic
```

### KCL Composition Test Example

```kcl
schema CompositionTest:
    """Composition test validates composition logic without live environment"""
    compositionPath: str
    xrPath: str
    xrdPath: str
    timeoutSeconds?: int = 60
    assertResources?: [AssertResource] = []
    validate?: bool = True

schema AssertResource:
    """Assertion for validating composed resources"""
    apiVersion: str
    kind: str
    name: str
    # Add assertions about spec fields, metadata, etc.

# Example test
test = CompositionTest {
    compositionPath = "../../apis/vpc/composition.yaml"
    xrPath = "../../examples/simple-vpc.yaml"
    xrdPath = "../../apis/vpc/definition.yaml"
    timeoutSeconds = 120
    validate = True
    assertResources = [
        AssertResource {
            apiVersion = "ec2.aws.upbound.io/v1beta1"
            kind = "VPC"
            name = "test-vpc"
            # Additional assertions...
        }
    ]
}
```

### Running Composition Tests

```bash
# Run all tests
up test run tests/*

# Run specific test
up test run tests/xvpc-simple/main.k

# Run tests matching pattern
up test run tests/xvpc-**/main.k

# Verbose output
up test run tests/* --verbose
```

### Test Scenarios to Cover

For each major feature, create tests for:

1. **Basic scenario**: Minimal required inputs
2. **Complex scenario**: All options enabled
3. **Conditional logic**: Features enabled/disabled
4. **Edge cases**: Boundary conditions, unusual inputs
5. **Multiple resources**: Multiple subnets, AZs, etc.
6. **Dependencies**: Resources that depend on others
7. **Error cases**: Invalid inputs (if validation allows testing)

---

## E2E Tests

### Test Structure

**Languages supported**: KCL, Python, YAML

### Generating E2E Tests

```bash
# Generate KCL E2E test
up test generate xvpc-e2e-simple --e2e --language=kcl

# Generate Python E2E test
up test generate xvpc-e2e-complex --e2e --language=python
```

### KCL E2E Test Example

```kcl
schema E2ETest:
    """E2E test validates composition in real environment"""
    manifests: [any]  # Resources to create
    extraResources?: [any] = []  # Additional resources (ProviderConfig, etc.)
    defaultConditions?: [str] = ["Ready"]  # Expected conditions
    skipDelete?: bool = False
    timeoutSeconds?: int = 600  # E2E tests need more time
    crossplane?: CrossplaneConfig

schema CrossplaneConfig:
    version?: str
    autoUpgrade?: bool = False

# Example E2E test
test = E2ETest {
    timeoutSeconds = 1800  # 30 minutes for AWS resources
    skipDelete = False
    defaultConditions = ["Ready", "Synced"]
    extraResources = [
        # ProviderConfig for AWS using IAM role
        # IMPORTANT: NEVER use static credentials, always use IAM role
        {
            apiVersion = "aws.upbound.io/v1beta1"
            kind = "ProviderConfig"
            metadata.name = "default"
            spec = {
                assumeRoleChain = [
                    {
                        roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                    }
                ]
            }
        }
    ]
    manifests = [
        # Your XR claim
        {
            apiVersion = "solutions.upbound.io/v1alpha1"
            kind = "VPC"
            metadata.name = "test-vpc-e2e"
            spec = {
                cidrBlock = "10.0.0.0/16"
                region = "us-west-2"
                availabilityZones = ["us-west-2a", "us-west-2b"]
                publicSubnetCidrs = ["10.0.1.0/24", "10.0.2.0/24"]
            }
        }
    ]
    crossplane = CrossplaneConfig {
        version = "1.18.0"
        autoUpgrade = False
    }
}
```

### Running E2E Tests

```bash
# Run E2E tests (requires Upbound login)
up test run tests/* --e2e

# Run specific E2E test
up test run tests/xvpc-e2e-simple/main.k --e2e

# Skip deletion (for debugging)
# Add skipDelete: true in test definition
```

### E2E Test Execution Flow

1. Detects test language and converts to unified format
2. Builds and pushes the project to Upbound registry
3. Creates a development control plane with specified Crossplane version
4. Sets kubectl context to new control plane
5. Applies extra resources (ProviderConfig, etc.) in order
6. Waits for extra resources to reach expected conditions
7. Applies test manifests (your XRs)
8. Waits for resources to reach expected conditions (Ready, Synced)
9. Validates assertions
10. Exports resources for debugging if failures occur
11. Deletes resources (unless skipDelete=true)
12. Cleans up control plane

### E2E Test Best Practices

1. **Use realistic timeouts**: AWS resources can take 5-30 minutes
2. **Run on Upbound Cloud**: Always run E2E tests in the "solutions" org on Upbound Cloud
3. **Use dedicated control plane group**: Tests run in `configuration-aws-vpc-e2e` group
4. **Clean up resources**: Ensure skipDelete=false in CI
5. **Use IAM role for credentials**: Use `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws` (NEVER static credentials)
6. **Test critical paths**: E2E validates real cloud integration
7. **Run in CI with labels**: Use "run-e2e-tests" label to trigger
8. **Don't worry about costs**: E2E tests are important for validation

---

## Composition Rendering

### Quick Preview Command

```bash
# Preview what resources will be created
up composition render \
  apis/vpc/composition.yaml \
  examples/simple-vpc.yaml

# Preview with custom XR input
up composition render \
  apis/vpc/composition.yaml \
  examples/complex-vpc.yaml

# Save output for inspection
up composition render \
  apis/vpc/composition.yaml \
  examples/simple-vpc.yaml \
  > /tmp/rendered-resources.yaml
```

### Use Cases

1. **Quick validation**: See resources without running tests
2. **Debugging**: Understand why composition isn't working
3. **Documentation**: Show examples of composed resources
4. **Learning**: Understand composition behavior

---

## Testing Strategy for This Project

### Phase-by-Phase Testing

**Phase 1 (Foundation)**:
- Basic composition test for empty project
- Validate XRD schema

**Phase 2 (Core VPC)**:
- Composition tests for each feature:
  - VPC creation
  - Subnet creation (all types)
  - Internet Gateway
  - NAT Gateway (all strategies)
  - Route tables and routes
- E2E test for basic VPC with public subnets
- E2E test for VPC with NAT Gateway

**Phase 3 (Enhanced Networking)**:
- Composition tests for:
  - VPC Endpoints
  - Network ACLs
  - DHCP Options
  - Flow Logs
  - Secondary CIDRs
- E2E test for complete VPC with all features

**Phase 4 (Advanced Features)**:
- Composition tests for VPN Gateway, IPv6
- E2E test for advanced scenarios

### Test Coverage Goals

**Composition Tests**:
- ✅ Every feature should have at least one composition test
- ✅ Test with feature enabled and disabled
- ✅ Test edge cases (single AZ, many AZs, etc.)
- ✅ Fast execution (< 10 seconds per test)
- ✅ Run on every commit in CI

**E2E Tests**:
- ✅ Core scenarios covered (basic VPC, full VPC)
- ✅ Critical paths validated (create, delete, update)
- ✅ Run on labeled PRs or before release
- ✅ Budget for cloud costs (estimate $5-20 per test run)

---

## Test Organization

### Naming Convention

```
tests/
├── composition/
│   ├── xvpc-basic/          # Basic VPC only
│   ├── xvpc-subnets-public/
│   ├── xvpc-subnets-private/
│   ├── xvpc-nat-single/     # Single NAT Gateway strategy
│   ├── xvpc-nat-per-az/     # NAT per AZ strategy
│   ├── xvpc-routes/
│   ├── xvpc-endpoints/
│   ├── xvpc-flow-logs/
│   ├── xvpc-complete/       # All features enabled
│   └── README.md
└── e2e/
    ├── xvpc-e2e-basic/      # Simple E2E test
    ├── xvpc-e2e-nat/        # NAT Gateway E2E
    ├── xvpc-e2e-complete/   # Full feature E2E
    └── README.md
```

### Test Documentation

Each test directory should have:
- `main.k` (or `main.py`): The test definition
- `README.md` (optional): What the test validates, expected outcomes

---

## CI/CD Integration

### GitHub Actions Workflows

**Composition Tests** (`.github/workflows/composition-test.yaml`):
```yaml
name: Composition Tests
on:
  push:
    branches: [main]
  pull_request: {}

jobs:
  composition-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          skip-login: true
      - run: up project build
      - run: up test run tests/composition/*
```

**E2E Tests** (`.github/workflows/e2e.yaml`):
```yaml
name: E2E Tests
on:
  pull_request_target:
    types: [synchronize, labeled]

jobs:
  e2e:
    if: contains(github.event.pull_request.labels.*.name, 'run-e2e-tests')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: upbound/action-up@v1
        with:
          api-token: ${{ secrets.UP_API_TOKEN }}
          organization: ${{ secrets.UP_ORG }}
      - run: up project build
      - run: up ctx ${{ secrets.UP_ORG }}/upbound-gcp-us-central-1/default
      - run: up test run tests/e2e/* --e2e
```

### Running Tests Locally

```bash
# Quick validation during development
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Run composition tests (no credentials needed)
up test run tests/composition/*

# Build before testing
up project build && up test run tests/composition/*

# Run E2E tests (requires up login)
up login
up test run tests/e2e/* --e2e
```

---

## Debugging Test Failures

### Composition Test Failures

1. **Check rendered output**:
   ```bash
   up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml
   ```

2. **Review error message**: Usually indicates missing fields or wrong types

3. **Validate test inputs**: Ensure XR matches XRD schema

4. **Check assertions**: Verify expected resources and fields

### E2E Test Failures

1. **Check exported resources**: Failed E2E tests export resources to debug
   ```bash
   kubectl get managed -o yaml > /tmp/managed-resources.yaml
   ```

2. **Check events**:
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   ```

3. **Check resource status**:
   ```bash
   kubectl describe xvpc my-vpc
   ```

4. **Check provider logs**: Look for authentication or API errors

5. **Verify credentials**: Ensure ProviderConfig is correct

6. **Check timeouts**: E2E tests may need longer timeouts for AWS

---

## E2E Test Configuration

### AWS Credentials

**IMPORTANT**: E2E tests MUST use IAM role assumption, NEVER static credentials.

**IAM Role for E2E Tests**: `arn:aws:iam::609897127049:role/solutions-e2e-provider-aws`

This role should be configured in the ProviderConfig:

```kcl
{
    apiVersion = "aws.upbound.io/v1beta1"
    kind = "ProviderConfig"
    metadata.name = "default"
    spec = {
        assumeRoleChain = [
            {
                roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
            }
        ]
    }
}
```

### Cost Considerations

E2E tests create real AWS resources. While costs should not prevent running necessary tests, it's good to understand what resources are created:

- **VPC**: Free
- **Subnets**: Free
- **Internet Gateway**: Free
- **NAT Gateway**: ~$0.045/hour
- **VPC Endpoints**: ~$0.01/hour per endpoint
- **Elastic IP**: $0.005/hour when not attached
- **Control Plane**: Free (dev control planes are free for 24h)

**Best practices**:
1. Run E2E tests when needed for validation
2. Use skipDelete=false to ensure cleanup
3. Set reasonable timeouts to avoid stuck resources
4. Use composition tests for most validation (faster feedback)

---

## Recommended Testing Commands

```bash
# During active development
up composition render apis/vpc/composition.yaml examples/simple-vpc.yaml

# Before committing
up project build && up test run tests/composition/*

# Before creating PR
up test run tests/composition/* --verbose

# After PR approval (add label)
# GitHub Actions will run: up test run tests/e2e/* --e2e

# Debug specific test
up test run tests/composition/xvpc-basic/main.k --verbose

# Local E2E test (careful - creates real resources!)
up login
up test run tests/e2e/xvpc-e2e-basic/main.k --e2e
```

---

## References

- **Upbound Testing Docs**: https://docs.upbound.io/build/control-plane-projects/testing/
- **Unified Testing Blog**: https://blog.upbound.io/unified-testing-with-upbound
- **Composition Testing Patterns**: https://blog.upbound.io/composition-testing-patterns-rendering
- **Example Repository**: https://github.com/upbound/composition-testing
- **Crossplane CLI**: https://docs.crossplane.io/latest/cli/

---

## Summary

**Quick Reference**:

| Task | Command | Speed | Requires Cluster |
|------|---------|-------|------------------|
| Preview | `up composition render` | Fast | No |
| Unit Test | `up test run tests/composition/*` | Fast | No |
| E2E Test | `up test run tests/e2e/* --e2e` | Slow | Yes (auto-created) |

**When to use what**:
- **Development**: Composition render + composition tests
- **Pre-commit**: Composition tests
- **CI on all PRs**: Composition tests
- **CI on labeled PRs**: E2E tests
- **Pre-release**: Full E2E test suite

**Key principles**:
1. Test early and often with composition tests
2. Use E2E tests sparingly for critical paths
3. Preview with render during development
4. Automate in CI/CD
5. Monitor costs for E2E tests
6. Document test scenarios
7. Keep tests maintainable and organized
