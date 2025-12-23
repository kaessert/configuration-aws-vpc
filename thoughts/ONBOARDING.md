# Onboarding Guide - AWS VPC Configuration for Upbound

Welcome! This guide will get you productive in under 2 hours.

---

## Overview

**Project Goal**: Build feature-complete AWS VPC configuration for Upbound. **See [../CLAUDE.md](../CLAUDE.md) for complete overview, architecture, and requirements.**

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

**Read in this order** (~60 minutes):

1. **[TASKS.md](TASKS.md)** (15 min) - Current status (at top) + task priorities
2. **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** (20 min) - Architecture & module structure
3. **[TDD_STRATEGY.md](TDD_STRATEGY.md)** (25 min) - TDD workflow (CRITICAL)

**Reference docs**: See [README.md](README.md) for complete index. Key references: [TESTING_REFERENCE.md](TESTING_REFERENCE.md), [KCL_REFERENCE.md](KCL_REFERENCE.md), [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)

---

## Common Mistakes to Avoid

See [TDD_STRATEGY.md](TDD_STRATEGY.md) for complete TDD workflow and [GIT_WORKFLOW.md](GIT_WORKFLOW.md) for commit conventions.

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
1. Complete setup (above)
2. Read 3 essential docs (60 minutes)
3. Pick first task from [TASKS.md](TASKS.md)
4. Complete task using TDD workflow
5. Make first commit per [GIT_WORKFLOW.md](GIT_WORKFLOW.md)

**This Week**: Master TDD, learn KCL patterns, complete priority tasks
**Ongoing**: Check [TASKS.md](TASKS.md) daily, run tests frequently, follow TDD

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
