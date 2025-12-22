# Onboarding Guide - AWS VPC Configuration for Upbound

Welcome! This guide will get you productive in under 2 hours.

---

## Overview

This project builds an Upbound control plane configuration for AWS VPC with complete feature parity to the [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

**See [../CLAUDE.md](../CLAUDE.md) for complete project overview, architecture, and requirements.**

---

## Prerequisites

### Required Tools

1. **Upbound CLI** (`up`)
   ```bash
   curl -sL https://cli.upbound.io | sh
   up --version
   ```

2. **Git** (already installed)
   ```bash
   git --version
   ```

3. **kubectl** (for local testing)
   ```bash
   brew install kubectl  # macOS
   kubectl version --client
   ```

4. **Upbound Account**
   - Sign up via `up login` command
   - Free tier available

### Optional Tools

- AWS CLI (for manual E2E verification only - NOT required for E2E tests)
- VS Code with KCL extension
- GitHub CLI (`gh`)

**Note on AWS CLI**: The AWS CLI is purely optional for manual verification. E2E tests do NOT require AWS credentials to be configured locally - they use Upbound's web identity federation for authentication.

---

## Setup Steps

### 1. Clone Repository

```bash
git clone <repository-url>
cd configuration-aws-vpc
git status
git log --oneline -5
```

### 2. Authenticate with Upbound

```bash
up login
up whoami
up group list  # Should see "claude-testing" for E2E tests
```

### 3. Verify Environment

```bash
# Build project to verify everything works
up project build

# Expected: All checks pass, project builds successfully
```

---

## Reading Plan (Essential Docs)

**Read in this order** (~75 minutes):

1. **[TASKS.md → Current Status](TASKS.md#current-status)** (15 min) - Current task list, see what's done and what's next
2. **[IMPLEMENTATION_GUIDE.md → Architecture](IMPLEMENTATION_GUIDE.md#architecture-overview)** (20 min) - Architecture, modular design, code organization
3. **[SPECIFICATION.md](SPECIFICATION.md)** (10 min) - Feature requirements from Terraform module (skim for now)
4. **[TDD_STRATEGY.md → TDD Workflow](TDD_STRATEGY.md#tdd-workflow-step-by-step)** (30 min) - Complete TDD workflow (CRITICAL for development)

**Reference docs** (lookup as needed):

- **[TESTING_REFERENCE.md](TESTING_REFERENCE.md)** - Complete testing guide
- **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** - Git conventions and workflow
- **[GIT_REFERENCE.md](GIT_REFERENCE.md)** - Git command syntax
- **[KCL_REFERENCE.md](KCL_REFERENCE.md)** - KCL language reference
- **[UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)** - Upbound CLI commands
- **[GLOSSARY.md](GLOSSARY.md)** - Project terminology

---

## Common Mistakes to Avoid

**Quick reminders**:
- ✅ Follow TDD workflow (RED → GREEN → REFACTOR → E2E → COMMIT)
- ✅ E2E tests are MANDATORY for all features
- ✅ Update [TASKS.md](TASKS.md) as you work

---

## Success Checklist

Before you start coding, verify:

- [ ] Build works: `up project build` succeeds
- [ ] Can run tests: `up test run tests/test-vpc-simple` passes
- [ ] Can navigate docs: Find answers in thoughts/ directory
- [ ] Understand TDD: Read [TDD_STRATEGY.md → TDD Workflow](TDD_STRATEGY.md#tdd-workflow-step-by-step)
- [ ] Know current tasks: Read [TASKS.md → Current Status](TASKS.md#current-status)
- [ ] Know git conventions: Read [GIT_WORKFLOW.md → Commit Conventions](GIT_WORKFLOW.md#1-commit-message-conventions)
- [ ] Know E2E requirements: Understand `--control-plane-group=claude-testing`

**All checked?** You're ready to contribute!

---

## Getting Help

### External Resources

- **Upbound**: https://docs.upbound.io
- **Crossplane**: https://docs.crossplane.io
- **KCL**: https://kcl-lang.io/docs
- **Terraform VPC**: https://github.com/terraform-aws-modules/terraform-aws-vpc

### Troubleshooting

```bash
# Environment broken?
up project stop
rm -rf .upbound/
up project build
```

---

## Next Steps

**Today** (2 hours):
1. ✅ Complete setup (above)
2. ✅ Read 4 essential docs (75 minutes)
3. ✅ Pick a task from [TASKS.md → Current Status](TASKS.md#current-status)
4. ✅ Complete your first task using TDD workflow
5. ✅ Make your first commit following [GIT_WORKFLOW.md → Making Commits](GIT_WORKFLOW.md#3-making-commits)

**This Week**:
- Master TDD workflow
- Learn KCL patterns from [KCL_REFERENCE.md](KCL_REFERENCE.md)
- Complete current priority tasks
- Write E2E tests

**Ongoing**:
- Check [TASKS.md](TASKS.md) daily
- Update documentation when you learn something
- Run tests frequently
- Follow TDD religiously

---

## Summary

**You've learned**:
- ✅ Project goals and tech stack
- ✅ How to set up your environment
- ✅ Where to find documentation
- ✅ The TDD workflow (🔴→🟢→🔵→🧪→✅)
- ✅ Essential commands
- ✅ Common mistakes to avoid

**You're ready to**:
- ✅ Pick tasks from [TASKS.md](TASKS.md)
- ✅ Follow TDD from [TDD_STRATEGY.md](TDD_STRATEGY.md)
- ✅ Make commits per [GIT_WORKFLOW.md](GIT_WORKFLOW.md)
- ✅ Contribute to the project

**Time to productivity**: ~2 hours

---

**Welcome to the team!** Now that setup is complete, check [TASKS.md](TASKS.md) to see what to work on next.
