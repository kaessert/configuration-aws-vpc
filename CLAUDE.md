# Instructions for Claude Code - AWS VPC Configuration for Upbound

Welcome! This document provides instructions for Claude Code (or any coding agent) working on this project.

---

## Development Requirements

**MANDATORY**: E2E (End-to-End) tests are REQUIRED for ALL features.

**Rationale**: Composition tests validate KCL logic; E2E tests validate actual AWS behavior. Both required before feature completion.

**Workflow**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**See**: `thoughts/TASKS.md` for current critical tasks

---

## Project Overview

**Goal**: Build an Upbound control plane configuration that provides feature parity with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

**Implementation**: Using Crossplane Composite Resources, KCL composition functions, and AWS Upbound providers.

**Status**: Phase 2 implementation - Core VPC features complete (VPC, subnets, gateways, routing). E2E tests required before continuing.

## Architecture Decision: Namespaced VPC Claims

**CRITICAL**: This project uses Crossplane v2 with **namespaced claims**.

**What This Means**:
- XRD kind: `VPC` (NO X prefix)
- All resources require: `namespace: default`
- ProviderConfigs must be namespaced

**Common Mistake**:
- DO NOT use `kind: XVPC` (cluster-scoped composite)
- ALWAYS use `kind: VPC` (namespaced claim)

If you see `kind: XVPC` anywhere in examples or user-facing documentation, it's a documentation error. Report it immediately.

See `thoughts/ARCHITECTURE_DECISIONS.md` for full details.

---

## 🔄 Self-Correcting Documentation

**When your actions are corrected**: Launch the Documentation Correction Agent to fix root causes. See `.claude/agents/documentation-correction-agent.md` for details.

---

## First-Time Setup

**For complete documentation navigation, see [thoughts/README.md](thoughts/README.md)**

**Quick start:**
1. Read [thoughts/ONBOARDING.md](thoughts/ONBOARDING.md) - Setup and prerequisites
2. Check [thoughts/TASKS.md](thoughts/TASKS.md) - What to work on next
3. Review [thoughts/TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) - How to develop features

## Current Project Status

**See [thoughts/TASKS.md](thoughts/TASKS.md) for current status and task list**


## How to Work on This Project

**Essential workflow:** 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

**For complete TDD workflow**, see [TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md)
**For git conventions**, see [GIT_WORKFLOW.md](thoughts/GIT_WORKFLOW.md)

### Before Every Commit

- ✅ All composition tests pass
- ✅ All E2E tests pass (MANDATORY)
- ✅ Project builds
- ✅ Follow conventional commits

**CRITICAL**: E2E tests are MANDATORY. Features are NOT complete without E2E validation.

## Essential References

**For complete navigation, see [thoughts/README.md](thoughts/README.md)**

Quick links:
- **Tasks**: [TASKS.md](thoughts/TASKS.md) - What to work on
- **Testing**: [TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) - How to test
- **Git**: [GIT_WORKFLOW.md](thoughts/GIT_WORKFLOW.md) - How to commit
- **Commands**: [UPBOUND_REFERENCE.md](thoughts/UPBOUND_REFERENCE.md) - up CLI reference
- **KCL**: [KCL_REFERENCE.md](thoughts/KCL_REFERENCE.md) - KCL syntax

## Remember

- **START HERE**: [thoughts/TASKS.md](thoughts/TASKS.md)
- **Test BEFORE committing**: ALL tests must pass (composition + E2E)
- **Follow TDD**: Write tests first, always
- **Keep it simple**: Don't over-engineer
