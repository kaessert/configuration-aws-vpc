# Getting Started with AWS VPC Configuration for Upbound

Welcome to the project! This guide will get you from zero to productive contributor in under an hour.

---

## What Is This Project?

**Goal**: Build an Upbound control plane configuration that provides feature parity with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

**Technology Stack**:
- **Crossplane**: Kubernetes-native infrastructure management
- **Upbound**: Platform for building and running control planes
- **KCL**: Configuration language for composition functions
- **AWS Upbound Providers**: Crossplane providers for AWS resources

**Current Status**: Foundation complete, core features implemented (VPC, subnets, NAT, routing), E2E tests in progress

---

## Prerequisites

Before you start, ensure you have these tools installed:

### Required Tools

1. **Upbound CLI** (`up`)
   ```bash
   # Install on macOS/Linux
   curl -sL https://cli.upbound.io | sh

   # Verify installation
   up --version
   ```

2. **Git**
   ```bash
   # Should already be installed
   git --version
   ```

3. **kubectl** (for local testing)
   ```bash
   # Install on macOS
   brew install kubectl

   # Verify installation
   kubectl version --client
   ```

4. **Upbound Account**
   - Sign up at https://console.upbound.io
   - Free tier available for development

### Optional But Helpful

- **AWS CLI** (for verifying E2E test resources)
- **VS Code** with KCL extension (syntax highlighting)
- **GitHub CLI** (`gh`) for PR workflows

---

## First-Time Setup

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone <repository-url>
cd configuration-aws-vpc

# Check current status
git status
git log --oneline -5
```

### Step 2: Authenticate with Upbound

```bash
# Login to Upbound Cloud
up login

# Verify authentication
up whoami

# Expected output:
# Organization: solutions
# Account: <your-account>
```

### Step 3: Verify Your Environment

```bash
# Check project structure
ls -la

# You should see:
# - upbound.yaml (project manifest)
# - apis/ (XRD definitions)
# - functions/ (KCL composition functions)
# - examples/ (example configurations)
# - tests/ (composition and E2E tests)
# - thoughts/ (this documentation!)

# Build the project (verify everything compiles)
up project build

# Expected output:
# Checking dependencies ✓
# Building functions ✓
# Building configuration package ✓
```

If all commands succeed, your environment is ready!

---

## Understanding the Project (15 Minutes)

### Essential Documents to Read

**1. Project Tasks** (5 minutes)
→ [planning/tasks.md](planning/tasks.md)
- See what's been done
- See what's next
- **CRITICAL**: Task 0.1 is currently BLOCKING all work!

**2. Architecture Overview** (5 minutes)
→ [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)
- Modular design principles
- Test hierarchy
- Feature organization

**3. Feature Specification** (5 minutes - skim)
→ [architecture/terraform-vpc-analysis.md](architecture/terraform-vpc-analysis.md)
- Complete feature list from Terraform module
- 50+ input variables
- 30+ outputs
- 20+ resource types

**Key Takeaway**: We're building feature parity with a mature Terraform module, following test-driven development, with mandatory E2E tests.

---

## Project Structure

```
configuration-aws-vpc/
├── upbound.yaml              # Project manifest
│
├── apis/                     # Crossplane XRDs (API definitions)
│   └── vpc/
│       ├── definition.yaml   # XVPC composite resource definition
│       └── composition.yaml  # Composition linking XRD to function
│
├── functions/                # KCL composition functions (the logic!)
│   └── vpc/
│       ├── main.k            # Entry point, orchestration
│       ├── kcl.mod           # Dependencies
│       ├── vpc.k             # VPC resource generation
│       ├── subnet.k          # Subnet logic
│       ├── gateway.k         # Gateway logic (IGW, NAT)
│       ├── route.k           # Routing logic
│       └── utils/            # Helper functions
│
├── examples/                 # Example VPC configurations
│   └── simple-vpc.yaml       # Basic VPC example
│
├── tests/                    # Tests (composition + E2E)
│   ├── test-xvpc-*/          # Composition tests (fast)
│   └── e2etest-xvpc-*/       # E2E tests (slow, real AWS)
│
├── thoughts/                 # Documentation (you are here!)
│   ├── README.md             # Documentation index
│   ├── planning/             # Task lists and planning
│   ├── architecture/         # Design and specs
│   ├── development/          # Dev guides (TDD, KCL, Git)
│   ├── testing/              # Testing guides
│   └── reference/            # Tool references
│
├── CLAUDE.md                 # Instructions for Claude Code (AI assistant)
├── README.md                 # User-facing project documentation
└── TESTING.md                # User-facing testing guide
```

---

## Your First Task

### Current Priority: Task 0.1

**Status**: **BLOCKING ALL WORK**

**Task 0.1**: Write E2E tests for all implemented features (VPC, subnets, NAT, routing)

**Why it's blocking**: E2E tests are now MANDATORY. We discovered that composition tests validate KCL logic only, but E2E tests validate actual AWS behavior. Without E2E validation, we risk shipping broken features.

**What you need to do**:
1. Read [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) (30 minutes)
2. Pick a feature from Task 0.1 in [planning/tasks.md](planning/tasks.md)
3. Write E2E test following the guide
4. Run E2E test: `up test run tests/e2etest-xvpc-<feature> --e2e`
5. Wait 20-40 minutes for AWS resources to create and cleanup
6. Verify cleanup in AWS Console (CRITICAL!)
7. Commit when test passes

**Estimated time**: 1-2 hours per E2E test (including waiting for AWS)

---

## Development Workflow (TDD)

This project follows **strict Test-Driven Development** with **MANDATORY E2E validation**.

### The Iron Rule

**🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT**

For every feature, you must:

1. **🔴 RED Phase**: Write composition test FIRST (test MUST fail)
2. **🟢 GREEN Phase**: Write minimum code to pass test
3. **🔵 REFACTOR Phase**: Improve code while keeping tests green
4. **🧪 E2E TEST Phase**: Write and pass E2E test (**MANDATORY**)
5. **✅ COMMIT Phase**: Only commit when ALL tests pass

**Read the full workflow**: [development/TDD_STRATEGY.md](development/TDD_STRATEGY.md)

---

## Your First Commit

When you've completed a task (e.g., written an E2E test), follow this workflow:

### 1. Run ALL Tests

```bash
# Run ALL composition tests (MUST pass)
up test run tests/test-*

# Run ALL E2E tests (MUST pass) - takes 2-4 hours!
up test run tests/e2etest-* --e2e

# Build project (MUST pass)
up project build
```

**CRITICAL**: NEVER commit if ANY test fails!

### 2. Verify AWS Cleanup (for E2E tests)

If you ran E2E tests, verify NO resources remain in AWS:
- VPCs: https://console.aws.amazon.com/vpc → Your VPCs → Filter by TestName tag → Should be EMPTY
- NAT Gateways: Check for expensive resources! → Should be EMPTY
- Elastic IPs: Check for billable resources! → Should be EMPTY

### 3. Update Documentation

- Update [planning/tasks.md](planning/tasks.md) - Mark tasks complete
- Update relevant guides if you learned something new

### 4. Commit with Conventional Commits

```bash
# Stage changes
git add .

# Commit with conventional commit message
git commit -m "feat: write E2E test for VPC creation

- Add E2E test validating real AWS VPC behavior
- Configure ProviderConfig with IAM role
- Set timeout to 30 minutes
- Verify cleanup after test
- E2E test passes, all resources cleaned up

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
"

# Push to remote
git push
```

**Commit message format**: `<type>: <subject>`
- `feat:` New feature
- `fix:` Bug fix
- `test:` Add or update tests
- `docs:` Documentation changes
- `refactor:` Code refactoring

**Read the full guide**: [development/git-workflow.md](development/git-workflow.md)

---

## Common Tasks Reference

### Build and Test

```bash
# Build project
up project build

# Run specific composition test
up test run tests/test-xvpc-simple

# Run all composition tests (fast - <1 min)
up test run tests/test-*

# Run specific E2E test (slow - 20-40 min)
up test run tests/e2etest-xvpc-basic --e2e

# Run all E2E tests (very slow - 2-4 hours!)
up test run tests/e2etest-* --e2e
```

### Local Development

```bash
# Preview composition output
up composition render examples/simple-vpc.yaml

# Run project locally (starts local control plane)
up project run

# In another terminal: Apply example
kubectl apply -f examples/simple-vpc.yaml

# Check resources
kubectl get composite
kubectl get managed
kubectl describe xvpc my-vpc

# Stop local run
up project stop
```

### Upbound Cloud

```bash
# Login
up login

# Check authentication
up whoami

# List control planes
up controlplane list

# Push package to registry (for production)
up project push
```

---

## Getting Help

### Where to Find Answers

**KCL syntax questions**
→ [development/kcl-guide.md](development/kcl-guide.md)

**Coding patterns**
→ [development/upbound-patterns.md](development/upbound-patterns.md)

**Testing questions**
→ [testing/TESTING_OVERVIEW.md](testing/TESTING_OVERVIEW.md)

**E2E test issues**
→ [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) (troubleshooting section)

**Git operations**
→ [development/git-workflow.md](development/git-workflow.md)

**Upbound CLI commands**
→ [reference/up-cli-guide.md](reference/up-cli-guide.md)

**Terminology**
→ [GLOSSARY.md](GLOSSARY.md)

**Navigation**
→ [README.md](README.md) (documentation index)

### External Documentation

**Upbound Docs**: https://docs.upbound.io
**Crossplane Docs**: https://docs.crossplane.io
**KCL Docs**: https://kcl-lang.io/docs
**Terraform VPC Module**: https://github.com/terraform-aws-modules/terraform-aws-vpc

---

## Common Mistakes to Avoid

### DON'T:
- ❌ Skip writing tests ("it's simple, I don't need tests")
- ❌ Write code before writing tests (violates TDD)
- ❌ Skip E2E tests (they're now MANDATORY)
- ❌ Commit failing tests
- ❌ Forget to verify AWS cleanup after E2E tests
- ❌ Use `skipDelete: True` in E2E tests (prevents cleanup verification)
- ❌ Use static AWS credentials (security risk!)
- ❌ Implement features not in the Terraform module spec
- ❌ Make commits without running ALL tests first

### DO:
- ✅ Follow TDD workflow religiously
- ✅ Write composition tests first (fast feedback)
- ✅ Write E2E tests for all features (mandatory)
- ✅ Verify AWS cleanup after E2E tests (cost risk!)
- ✅ Update [planning/tasks.md](planning/tasks.md) as you work
- ✅ Use IAM role authentication (ProviderConfig)
- ✅ Reference [architecture/terraform-vpc-analysis.md](architecture/terraform-vpc-analysis.md) for feature specs
- ✅ Ask questions and document learnings

---

## Next Steps

### Immediate Actions (Today)

1. ✅ **Complete this setup** (you're almost done!)
2. ✅ **Read 3 essential docs** (30 minutes):
   - [planning/tasks.md](planning/tasks.md)
   - [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)
   - [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md)
3. ✅ **Pick a task from Task 0.1** (write E2E test)
4. ✅ **Complete your first E2E test** (2 hours)
5. ✅ **Make your first commit** (following git workflow)

### This Week

1. **Complete Task 0.1** - Write ALL E2E tests for implemented features
2. **Master TDD workflow** - Read [development/TDD_STRATEGY.md](development/TDD_STRATEGY.md)
3. **Learn KCL patterns** - Read [development/kcl-guide.md](development/kcl-guide.md)
4. **Understand architecture** - Deep dive into [architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)

### Ongoing

1. **Check tasks.md daily** - Always know what's next
2. **Update documentation** - Share what you learn
3. **Run tests frequently** - Fast feedback prevents bugs
4. **Follow TDD religiously** - It works!

---

## Success Checklist

Before you start coding, verify you can:

- [ ] Build the project: `up project build` succeeds
- [ ] Run a composition test: `up test run tests/test-xvpc-simple` passes
- [ ] Navigate documentation: Find answers in thoughts/ directory
- [ ] Understand TDD workflow: 🔴 → 🟢 → 🔵 → 🧪 → ✅
- [ ] Read the current task: Know what Task 0.1 requires
- [ ] Use git properly: Know how to commit with conventions

If you checked all boxes: **You're ready to contribute!** 🎉

---

## Emergency Contacts

**Stuck on something?**

1. **Check documentation**: Use [README.md](README.md) to find relevant guide
2. **Check examples**: Look at existing tests and code
3. **Check external docs**: Upbound, Crossplane, KCL official docs
4. **Check git history**: `git log` to see how similar tasks were done
5. **Ask for help**: Create an issue or reach out to the team

**Environment broken?**
```bash
# Stop any running local control planes
up project stop

# Clean build artifacts
rm -rf .upbound/

# Rebuild
up project build
```

---

## Summary

**You've learned**:
- ✅ Project goals and technology stack
- ✅ How to set up your development environment
- ✅ Where to find documentation
- ✅ The TDD workflow we follow
- ✅ How to make your first commit
- ✅ Common tasks and commands

**You're ready to**:
- ✅ Pick a task from [planning/tasks.md](planning/tasks.md)
- ✅ Write E2E tests following [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md)
- ✅ Follow TDD workflow from [development/TDD_STRATEGY.md](development/TDD_STRATEGY.md)
- ✅ Make meaningful contributions to the project

**Your first task**: Write E2E test for an implemented feature (Task 0.1)

**Time to productivity**: ~1 hour (reading docs) + 2 hours (first E2E test) = **3 hours total**

---

## See Also

- [README.md](README.md) - Documentation navigation index
- [GLOSSARY.md](GLOSSARY.md) - Project terminology
- [planning/tasks.md](planning/tasks.md) - What to work on
- [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) - Your first task!
- [development/TDD_STRATEGY.md](development/TDD_STRATEGY.md) - Development workflow

---

**Welcome to the team!** Now head to [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) and write your first E2E test. You've got this! 🚀
