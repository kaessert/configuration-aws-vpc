# Glossary - Project Terminology

**New to the project? Start with [ONBOARDING.md](ONBOARDING.md)** for complete setup and context.

This glossary defines project-specific terms and concepts. Use this when you encounter unfamiliar terminology.

---

## Crossplane Terms

### XRD (Composite Resource Definition)
**Definition**: Defines the API schema for a composite resource. Think of it as a "custom API" that users interact with.

**Example**: `XVPC` is our XRD that defines the VPC API with fields like `cidr`, `azs`, `publicSubnets`, etc.

**File**: `apis/vpc/definition.yaml`

**Analogy**: Like a Kubernetes Custom Resource Definition (CRD), but for composition.

---

### XR (Composite Resource)
**Definition**: An instance of an XRD. The actual resource created by a user based on the XRD schema.

**Example**: When you `kubectl apply -f examples/simple-vpc.yaml`, you create an XR of type `XVPC`.

**Also called**: Composite Resource

**Relationship**: XRD is to XR as Class is to Instance (in OOP)

---

### Composition
**Definition**: Defines HOW to create managed resources from an XR. Links an XRD to a composition function.

**Example**: `apis/vpc/composition.yaml` links `XVPC` to the `vpc` KCL function.

**Contains**:
- Reference to XRD (`compositeTypeRef`)
- Reference to composition function (`pipeline`)
- Mode (`Pipeline` for function-based compositions)

**Analogy**: The "controller" that orchestrates resource creation based on user input.

---

### Managed Resource (MR)
**Definition**: A Crossplane resource that represents an actual cloud resource (VPC, Subnet, etc.). Managed by a provider.

**Example**: `VPC.ec2.aws.upbound.io` is a managed resource representing an AWS VPC.

**Lifecycle**: Created by composition function → Synced by provider → Becomes AWS resource

**States**:
- `Creating` - Resource is being created in cloud
- `Syncing` - Crossplane is syncing with cloud state
- `Ready` - Resource is ready and functional
- `Deleting` - Resource is being deleted

---

### Claim
**Definition**: A namespace-scoped version of a composite resource. Used when you want multi-tenancy.

**Example**: `VPC` (claim) vs `XVPC` (composite)

**Usage in this project**: We use Claims in E2E tests to isolate test resources.

**Relationship**: Claim → XR → Managed Resources

---

### Provider
**Definition**: A Crossplane controller that manages cloud resources. Communicates with cloud APIs.

**Example**: `upbound-provider-aws` manages AWS resources (VPC, Subnet, EC2, etc.)

**Responsibilities**:
- Create/update/delete cloud resources
- Sync cloud state with Kubernetes
- Handle authentication (via ProviderConfig)

---

### ProviderConfig
**Definition**: Configuration for how a provider authenticates with the cloud provider (AWS, Azure, GCP, etc.)

**Authentication Methods**:
1. **Web Identity Federation** (RECOMMENDED for E2E tests)
   - Uses Upbound as OIDC identity provider
   - NO static AWS credentials required
   - Temporary credentials via IAM role assumption
   - Most secure approach

2. **Static Credentials** (NOT recommended)
   - AWS access keys stored as secrets
   - Requires credential rotation
   - Higher security risk

**Example - Web Identity (E2E Tests)**:
```yaml
apiVersion: aws.m.upbound.io/v1beta1  # Note: .m. for namespaced provider
kind: ProviderConfig
metadata:
  name: default
  namespace: default
spec:
  credentials:
    source: Upbound  # Uses web identity federation
    upbound:
      webIdentity:
        roleARN: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
```

**How Web Identity Works**:
1. Upbound acts as an OIDC identity provider
2. IAM role trusts Upbound's identity provider
3. Upbound obtains temporary AWS credentials automatically
4. NO AWS access keys needed locally
5. More secure than static credentials

**Critical for**: E2E tests (authentication to real AWS)

**Security note**: Always use web identity federation for E2E tests, NEVER static credentials!

---

## Upbound Terms

### Upbound
**Definition**: The company and platform for building and running control planes. Think "Crossplane as a Service."

**Website**: https://upbound.io

**Products**:
- Upbound Spaces: Hosted control planes
- Upbound CLI: `up` command for managing projects
- Upbound Marketplace: Registry for configurations and functions

---

### Control Plane
**Definition**: A Kubernetes cluster running Crossplane and your configuration. The "brain" that manages infrastructure.

**Types**:
- **Local**: `up project run` (development)
- **Spaces**: Upbound Cloud (production or E2E tests)
- **Self-hosted**: Your own Kubernetes cluster with Crossplane

**Components**:
- Crossplane core
- Providers (e.g., AWS provider)
- Your configuration package
- Composition functions

---

### Spaces
**Definition**: Upbound's hosted control plane service. Provides production-ready control planes in the cloud.

**Features**:
- Ephemeral control planes for E2E tests
- Production control planes with SLA
- Multi-tenancy and RBAC
- Automatic upgrades

**Usage**: All E2E tests run on Spaces (auto-provisioned control planes)


---

### Configuration Package
**Definition**: A distributable package containing XRDs, Compositions, and Functions. The "product" you build.

**Format**: OCI container image (`.uppkg`)

**Contents**:
- `apis/` - XRD and Composition YAML
- `functions/` - Compiled KCL functions
- `upbound.yaml` - Package metadata

**Lifecycle**: Build → Push to registry → Install on control plane

**Commands**:
```bash
up project build   # Build package
up project push    # Push to registry
```

---

### Function (Composition Function)
**Definition**: Code that generates managed resources from an XR. The "logic" of your composition.

**Languages supported**: KCL, Python, Go

**This project uses**: KCL

**Location**: `functions/vpc/`

**Execution**: Runs in composition pipeline when XR is created/updated

**Analogy**: Like a "template engine" that takes user input (XR) and outputs managed resources.

---

## KCL Terms

### KCL (KCL Configuration Language)
**Definition**: A domain-specific language for writing Crossplane composition functions. Focuses on configuration and validation.

**Why KCL**: Type-safe, concise, designed for cloud configuration

**File extension**: `.k`

**Docs**: https://kcl-lang.io/docs

**Example**:
```kcl
import models.io.upbound.aws.v1beta1 as awsv1beta1

items = [
    awsv1beta1.VPC{
        metadata.name = "my-vpc"
        spec.forProvider.cidrBlock = "10.0.0.0/16"
    }
]
```

---

### Schema
**Definition**: Defines the structure and types of data in KCL. Like a TypeScript interface or Go struct.

**Example**:
```kcl
schema VPCConfig:
    cidr: str
    azs: [str]
    publicSubnets: [str]
```

**Usage**: Type checking, validation, IDE autocomplete

---

### Lambda (in KCL context)
**Definition**: Anonymous function in KCL. Used for filtering, mapping, and transforming data.

**Example**:
```kcl
# Filter subnets
publicSubnets = [s for s in subnets if s.type == "public"]

# Map to names
names = [subnet.name for subnet in publicSubnets]
```

**Syntax**: Similar to Python list comprehensions

---

### Option
**Definition**: Access composition context (input XR, observed resources, etc.) in KCL.

**Usage**:
```kcl
oxr = option("params").oxr  # Get input XR
ocds = option("params").ocds  # Get observed composite resources
```

**Available options**:
- `oxr` - Observed composite resource (input)
- `ocds` - Observed composed resources (what currently exists)
- `dxr` - Desired composite resource (output)

---

### Import
**Definition**: Include external modules or models in KCL.

**Example**:
```kcl
# Import AWS provider models
import models.io.upbound.aws.v1beta1 as awsv1beta1

# Use imported model
vpc = awsv1beta1.VPC{ ... }
```

**Types of imports**:
- Provider models (from kcl.mod dependencies)
- Local modules (from `utils/`)
- Standard library

---

## Testing Terms

### Composition Test
**Definition**: Fast unit test that validates composition logic without requiring a real control plane or cloud resources.

**Speed**: Seconds

**What it tests**: KCL logic, resource generation, conditional logic

**When to use**: Development (fast feedback), CI on every PR

**Tool**: `up test run tests/test-*`

**Also called**: Unit test, function test

---

### E2E Test (End-to-End Test)
**Definition**: Slow integration test that validates composition with REAL cloud resources. Creates actual AWS resources.

**Speed**: 30-40 minutes per test (expected and acceptable)

**What it tests**: Complete lifecycle (create → ready → delete), AWS behavior, provider integration

**Authentication**: Uses Upbound's web identity federation - NO AWS credentials required locally

**When to use**: Before merging to main, on labeled PRs, MANDATORY for all features

**Tool**: `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`

**Critical**: MUST verify cleanup (orphaned resources cost money!)

**Also called**: Integration test, system test

**Common misconception**: E2E tests do NOT require AWS credentials to be configured locally. Upbound handles authentication via web identity federation automatically.

---

### Test Pyramid
**Definition**: Testing strategy with many fast unit tests, fewer slow integration tests.

**Structure**:
```
        /\
       /E2E\       ← Few, slow, expensive (real AWS)
      /------\
     / Comp. \    ← Many, fast, cheap (local)
    /________\
```

**Ratio**: ~10-20 composition tests per 1 E2E test

**Philosophy**: Fast feedback (composition) + high confidence (E2E)

---

### assertResources
**Definition**: Validates that composition function generates expected managed resources in composition tests.

**Usage**:
```kcl
assertResources: [
    {
        apiVersion: "ec2.aws.upbound.io/v1beta1"
        kind: "VPC"
        name: "test-vpc"
        # Assert specific fields...
    }
]
```

**Validates**: Resource exists, has correct spec, has correct metadata

---

### observedResources
**Definition**: Validates resource status and conditions in composition or E2E tests.

**Usage**:
```kcl
observedResources: [
    {
        name: "test-vpc"
        conditions: [
            { type: "Ready", status: "True" }
            { type: "Synced", status: "True" }
        ]
    }
]
```

**Validates**: Resource reached desired state (Ready, Synced, etc.)

---

### defaultConditions
**Definition**: List of conditions that ALL resources must meet for E2E test to pass.

**Common values**:
- `["Ready"]` - Resource is ready
- `["Synced"]` - Resource is synced with cloud
- `["Ready", "Synced"]` - Both (recommended)

**Usage in E2E tests**:
```kcl
spec.defaultConditions: ["Ready", "Synced"]
```

---

## AWS Terms

### VPC (Virtual Private Cloud)
**Definition**: Isolated virtual network in AWS. The container for all your AWS resources.

**CIDR Block**: IP address range (e.g., `10.0.0.0/16` = 65,536 IPs)

**Key features**: DNS, DHCP, routing, security groups

**This project**: Creates and configures VPCs based on user input

---

### Subnet
**Definition**: Subdivision of a VPC in a specific Availability Zone. Resources launch into subnets.

**Types**:
- **Public**: Has route to Internet Gateway (0.0.0.0/0 → IGW)
- **Private**: No direct internet access (may route through NAT)
- **Isolated**: No internet access at all

**CIDR**: Must be subset of VPC CIDR (e.g., VPC: `10.0.0.0/16`, Subnet: `10.0.1.0/24`)

**Multi-AZ**: Spread subnets across multiple AZs for high availability

---

### Internet Gateway (IGW)
**Definition**: Allows communication between VPC and the internet. Required for public subnets.

**Usage**: Attach to VPC, add route in public route table (0.0.0.0/0 → IGW)

**High availability**: Redundant and scalable by default (AWS managed)

---

### NAT Gateway
**Definition**: Allows private subnet resources to access the internet (outbound only) without exposing them to inbound traffic.

**Usage**: Place in public subnet, add route in private route table (0.0.0.0/0 → NAT)

**Strategies**:
- **Single**: One NAT for all AZs (cheap but not HA)
- **One per AZ**: NAT in each AZ (expensive but HA)

---

### Route Table
**Definition**: Contains rules (routes) that determine where network traffic is directed.

**Types**:
- **Public**: Routes 0.0.0.0/0 to Internet Gateway
- **Private**: Routes 0.0.0.0/0 to NAT Gateway
- **Isolated**: No 0.0.0.0/0 route (local VPC only)

**Associations**: Links route table to subnets

**Main route table**: Default table for VPC (usually used for private/isolated subnets)

---

### Elastic IP (EIP)
**Definition**: Static public IPv4 address that can be assigned to AWS resources (NAT Gateway, EC2, etc.).

**Usage**: Required for NAT Gateway (NAT needs public IP)

---

### Availability Zone (AZ)
**Definition**: Isolated data center within an AWS region. Used for high availability.

**Examples**: `us-west-2a`, `us-west-2b`, `us-west-2c`

**Best practice**: Spread resources across multiple AZs (minimum 2, preferably 3)

**This project**: User specifies AZs, we create subnets in each AZ

---

## Project-Specific Terms

### Feature Parity
**Definition**: Our goal to match ALL features of the Terraform AWS VPC module.

**Source**: [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)

**Scope**: 50+ input variables, 30+ outputs, 20+ resource types

**Status**: Core features implemented, advanced features in progress

---

### TDD (Test-Driven Development)
**Definition**: Development methodology where you write tests BEFORE writing code.

**Our workflow**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**See [TDD_STRATEGY.md](TDD_STRATEGY.md) for complete workflow and best practices**

---


### Composition Function
**Definition**: KCL code that transforms an XR into managed resources. The "brain" of the composition.

**Location**: `functions/vpc/main.k`

**Input**: User's XR (desired state)

**Output**: List of managed resources to create

**Execution**: Runs in composition pipeline on control plane

---

### Modular Architecture
**Definition**: Our design principle to organize code by concern, not by resource type.

**Benefits**: Testable, maintainable, scalable

**See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for complete architectural principles and structure**

---

## Common Acronyms

| Acronym | Full Name | Meaning |
|---------|-----------|---------|
| **XRD** | Composite Resource Definition | API schema definition |
| **XR** | Composite Resource | Instance of XRD |
| **MR** | Managed Resource | Cloud resource (VPC, Subnet, etc.) |
| **KCL** | KCL Configuration Language | Language for composition functions |
| **IGW** | Internet Gateway | Gateway for internet access |
| **NAT** | Network Address Translation | Gateway for private subnet internet access |
| **EIP** | Elastic IP | Static public IP address |
| **AZ** | Availability Zone | Data center within region |
| **CIDR** | Classless Inter-Domain Routing | IP address range notation |
| **TDD** | Test-Driven Development | Write tests first methodology |
| **E2E** | End-to-End | Integration test with real resources |
| **HA** | High Availability | Fault-tolerant architecture |
| **IAM** | Identity and Access Management | AWS authentication/authorization |

---

## Quick Reference

### Hierarchy

```
Control Plane
  └── Configuration Package
      ├── XRD (API definition)
      ├── Composition (orchestration)
      └── Function (KCL logic)
          └── Generates Managed Resources
              └── Synced by Provider
                  └── Creates Cloud Resources (AWS)
```

### User Flow

```
User creates Claim/XR
  → Composition function executes
    → Generates managed resources
      → Provider syncs with AWS
        → AWS resources created
          → Resources reach Ready state
            → User can use infrastructure
```

### Testing Flow

```
Write composition test (RED)
  → Implement feature (GREEN)
    → Refactor code (BLUE)
      → Write E2E test (E2E)
        → All tests pass (COMMIT)
```

---

## See Also

- [README.md](README.md) - Documentation navigation
- [ONBOARDING.md](ONBOARDING.md) - Complete onboarding guide
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Architecture and implementation patterns
- [TDD_STRATEGY.md](TDD_STRATEGY.md) - Development workflow

---

**Pro tip**: Bookmark this glossary! You'll reference it frequently as you learn the project.

**Not finding a term?** Add it! This glossary should grow as we discover new concepts.
