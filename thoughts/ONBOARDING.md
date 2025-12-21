# Onboarding Guide - AWS VPC Configuration for Upbound

Welcome! This guide will get you productive in under 2 hours.

---

## Overview

**Goal**: Build an Upbound control plane configuration providing feature parity with [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc).

**Tech Stack**: Crossplane, Upbound, KCL, AWS Upbound Providers

**Current Status**: Foundation complete, core features implemented (VPC, subnets, NAT, routing), E2E tests in progress

**Development Approach**: Strict Test-Driven Development (TDD) with mandatory End-to-End (E2E) tests

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
   - Sign up at https://console.upbound.io
   - Free tier available

### Optional Tools

- AWS CLI (for E2E verification)
- VS Code with KCL extension
- GitHub CLI (`gh`)

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

1. **[TASKS.md](TASKS.md)** (15 min) - Current task list, see what's done and what's next
2. **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** (20 min) - Architecture, modular design, code organization
3. **[SPECIFICATION.md](SPECIFICATION.md)** (10 min) - Feature requirements from Terraform module (skim for now)
4. **[TDD_STRATEGY.md](TDD_STRATEGY.md)** (30 min) - Complete TDD workflow (CRITICAL for development)

**Reference docs** (lookup as needed):

- **[TESTING_REFERENCE.md](TESTING_REFERENCE.md)** - Complete testing guide
- **[GIT_WORKFLOW.md](GIT_WORKFLOW.md)** - Git conventions and workflow
- **[GIT_REFERENCE.md](GIT_REFERENCE.md)** - Git command syntax
- **[KCL_REFERENCE.md](KCL_REFERENCE.md)** - KCL language reference
- **[UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)** - Upbound CLI commands
- **[GLOSSARY.md](GLOSSARY.md)** - Project terminology

---

## Common Mistakes to Avoid

**DON'T**:
- ❌ Skip writing tests first (violates TDD)
- ❌ Skip E2E tests (now MANDATORY)
- ❌ Commit failing tests
- ❌ Forget to verify AWS cleanup after E2E tests
- ❌ Use `skipDelete: True` in E2E tests
- ❌ Run E2E tests without `--control-plane-group` flag
- ❌ Make commits without running ALL tests

**DO**:
- ✅ Follow TDD workflow religiously
- ✅ Write composition tests first (fast feedback)
- ✅ Write E2E tests for all features (mandatory)
- ✅ Verify AWS cleanup after E2E tests
- ✅ Always specify `--control-plane-group=claude-testing` for E2E tests
- ✅ Update [TASKS.md](TASKS.md) as you work
- ✅ Ask questions and document learnings

---

## Success Checklist

Before you start coding, verify:

- [ ] Build works: `up project build` succeeds
- [ ] Can run tests: `up test run tests/test-vpc-simple` passes
- [ ] Can navigate docs: Find answers in thoughts/ directory
- [ ] Understand TDD: Read [TDD_STRATEGY.md](TDD_STRATEGY.md)
- [ ] Know current tasks: Read [TASKS.md](TASKS.md)
- [ ] Know git conventions: Read [GIT_WORKFLOW.md](GIT_WORKFLOW.md)
- [ ] Know E2E requirements: Understand `--control-plane-group=claude-testing`

**All checked?** You're ready to contribute!

---

## Getting Help

### Quick Links

- **Documentation Index**: [README.md](README.md)
- **Testing Guide**: [TDD_STRATEGY.md](TDD_STRATEGY.md)
- **Git Guide**: [GIT_WORKFLOW.md](GIT_WORKFLOW.md)
- **Tasks**: [TASKS.md](TASKS.md)
- **Glossary**: [GLOSSARY.md](GLOSSARY.md)

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
3. ✅ Pick a task from [TASKS.md](TASKS.md)
4. ✅ Complete your first task following [TDD_STRATEGY.md](TDD_STRATEGY.md)
5. ✅ Make your first commit following [GIT_WORKFLOW.md](GIT_WORKFLOW.md)

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

**Welcome to the team!** Now read [TDD_STRATEGY.md](TDD_STRATEGY.md) and start your first task from [TASKS.md](TASKS.md).
