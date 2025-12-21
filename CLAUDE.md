# Instructions for Claude Code - AWS VPC Configuration for Upbound

Welcome! This document provides instructions for Claude Code (or any coding agent) working on this project.

---

## 🚨 CRITICAL PRIORITY CHANGE - READ FIRST 🚨

**EFFECTIVE IMMEDIATELY**: E2E (End-to-End) tests are now **MANDATORY** for ALL features.

### What Changed:
- **OLD**: E2E tests were optional, mainly for "critical features"
- **NEW**: E2E tests are MANDATORY before marking ANY feature complete

### Why:
- Composition tests validate KCL logic only
- E2E tests validate actual AWS behavior
- Without E2E validation, we risk shipping broken features
- We discovered features may pass composition tests but fail in real AWS

### Action Required:
1. **STOP ALL NEW WORK** - Complete Task 0.1 first (add E2E tests for tasks 2.1-2.5)
2. **NEW WORKFLOW**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT
3. **BEFORE COMMIT**: ALL composition tests + ALL E2E tests MUST pass

See `thoughts/TASKS.md` for the new critical task (0.1) that blocks all other work.

---

## Project Overview

**Goal**: Build an Upbound control plane configuration that provides feature parity with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

**Implementation**: Using Crossplane Composite Resources, KCL composition functions, and AWS Upbound providers.

**Status**: Project is in the planning/foundation phase. All research and documentation is complete. Ready for implementation.

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

## 🔄 Self-Correcting Documentation System

**CRITICAL FOR ALL AGENTS**: This project implements a self-correcting documentation mechanism.

### When Your Actions Are Corrected

If a human user **corrects, denies, or de-validates** any of your actions or assumptions:

1. **IMMEDIATELY** launch the Documentation Correction Agent
2. **DO NOT** continue with the main task until documentation is corrected
3. **DO NOT** pollute the main context with documentation investigation

### How to Invoke the Correction Agent

**CRITICAL FIRST STEP**: Before launching the agent, ask the human for DEEP understanding of the right solution:

```
Before I fix the documentation, I need to deeply understand the RIGHT solution:

1. WHAT is the correct approach? (the solution itself)
2. WHY is this the right approach? (reasoning, trade-offs, context)
3. WHEN should this approach be used? (conditions, scenarios)
4. HOW should this be implemented? (concrete steps, examples)

[Ask specific clarifying questions based on the correction]
```

**Then launch the agent with this understanding**:

```bash
# Use the Task tool to launch the specialized agent
Task(
  subagent_type="general-purpose",
  description="Investigate documentation issue",
  prompt="""
You are the Documentation Correction Agent for this project.

CONTEXT:
- Incorrect action taken: [describe what was wrong]
- Correct approach: [describe what should have happened]
- Problem being solved: [original problem]

DEEP UNDERSTANDING OF RIGHT SOLUTION:
- What: [the solution itself]
- Why: [reasoning and context]
- When: [conditions for using this approach]
- How: [concrete implementation steps]

Follow the instructions in .claude/agents/documentation-correction-agent.md to:
0. Start with the deep understanding above (Phase 0)
1. Investigate why the wrong path was taken
2. Find contradicting/missing/duplicate documentation
3. Fix all documentation issues
4. Implement prevention measures

Your goal: Ensure this mistake never happens again.
"""
)
```

### Why This Matters

- **Prevents repeated mistakes**: Fix root causes in documentation
- **Improves agent performance**: Future agents learn from corrections
- **Keeps main context clean**: Investigation happens in sub-agent
- **Systemic improvement**: Don't just fix the issue, fix the documentation

### Examples of When to Invoke

1. **Wrong assumption made**: "I assumed E2E tests were optional" → INVOKE
2. **Contradicting guidance followed**: "File A said X, but Y was correct" → INVOKE
3. **Missed critical requirement**: "I didn't know Z was mandatory" → INVOKE
4. **Used wrong pattern**: "I followed pattern A, but pattern B was correct" → INVOKE

### Agent Responsibilities

The Documentation Correction Agent (see `.claude/agents/documentation-correction-agent.md`) will:
- ✅ Audit all documentation for contradictions
- ✅ Find missing or hard-to-find information
- ✅ Resolve conflicts between documents
- ✅ Improve discoverability of critical information
- ✅ Implement prevention measures
- ✅ Ensure consistency across all documentation

### Your Responsibility

When corrected by a human:
1. Acknowledge the correction
2. Launch the Documentation Correction Agent immediately
3. Wait for the agent to complete its investigation
4. Only then resume your main task with correct information

**Remember**: Every correction is an opportunity to improve the project's documentation system. Take it seriously.

---

## First-Time Setup

If this is your first time working on this project:

1. **Read the project context**:
   - Review `thoughts/INITIAL_PROMPT.md` for the original requirements
   - Read `thoughts/TASKS.md` for the complete task breakdown
   - Read `thoughts/SPECIFICATION.md` - Complete specification of what we're building

2. **Understand the implementation approach**:
   - `thoughts/IMPLEMENTATION_GUIDE.md` - Architecture, workflow, testing strategy

3. **Learn KCL patterns**:
   - `thoughts/KCL_REFERENCE.md` - KCL language reference

4. **Familiarize yourself with the tools**:
   - `thoughts/UPBOUND_REFERENCE.md` - Upbound CLI reference
   - `thoughts/TESTING_REFERENCE.md` - Testing guide

5. **Learn git workflows**:
   - `thoughts/GIT_WORKFLOW.md` - Git workflows and commit conventions
   - `thoughts/GIT_REFERENCE.md` - Git command reference

## The "thoughts" Directory Structure

All operational knowledge lives in the `thoughts/` directory (flat structure):

```
thoughts/
├── SPECIFICATION.md            # Complete feature specification (WHAT to build)
├── IMPLEMENTATION_GUIDE.md     # Architecture and workflow (HOW to build)
├── TDD_STRATEGY.md             # TDD workflow and testing strategy
├── INITIAL_PROMPT.md           # Original project requirements
├── TASKS.md                    # Prioritized task list (START HERE)
├── KCL_REFERENCE.md            # KCL language reference
├── UPBOUND_REFERENCE.md        # Upbound CLI reference
├── TESTING_REFERENCE.md        # Testing guide
├── GIT_WORKFLOW.md             # Git workflows and commit conventions
└── GIT_REFERENCE.md            # Git command reference
```

## Current Project Status

**Phase**: Foundation / Planning Complete
**Next Step**: Phase 1 - Project Foundation (see tasks.md)

### What's Done
- ✅ Complete analysis of Terraform AWS VPC module
- ✅ Research of Upbound platform-ref-upbound patterns
- ✅ Documentation of KCL language
- ✅ Documentation of up-cli
- ✅ Comprehensive task breakdown
- ✅ Git workflow documentation

### What's Next
Start with tasks from `thoughts/TASKS.md`:
1. Initialize Upbound project (1.1)
2. Define XRD (1.2)
3. Create composition function scaffold (1.3)
4. Implement core VPC features (Phase 2)

## Documentation Principles

**CRITICAL**: This project maintains concise, compact documentation optimized for agent discoverability.

### What to Document

✅ **DO Document**:
- System setup steps and external dependencies
- Critical lessons extracted from debugging (in optimal locations)
- Configuration requirements and patterns
- Troubleshooting solutions (where agents would look first)
- Architecture decisions and rationale

❌ **DO NOT Document**:
- Work sessions or debugging journeys
- Historical narratives ("what we did on date X")
- Session summaries or meeting notes
- Temporal context ("today we discovered...")
- Process descriptions without lessons

### How to Document Lessons Learned

When you discover an important lesson:

1. **Extract the lesson**: What's the specific, reusable insight?
2. **Find optimal location**: Where would an agent look FIRST for this information?
3. **Document once**: Place in the best spot for quick discoverability
4. **Add cross-references**: Link from related sections if needed

**Example**:
- ❌ WRONG: Create "E2E_DEBUGGING_SESSION_2025-12-19.md"
- ✅ CORRECT: Add ProviderConfig troubleshooting to TESTING_REFERENCE.md → Common Issues → E2E Tests

### Documentation Location Strategy

| Discovery Question | Optimal Location |
|-------------------|------------------|
| "How do I configure E2E tests?" | TESTING_REFERENCE.md → E2E Tests section |
| "Why is my E2E test hanging?" | TESTING_REFERENCE.md → Common Issues → E2E Tests |
| "What's the correct ProviderConfig?" | TESTING_REFERENCE.md → E2E Test Example (in code) |
| "How do I use KCL?" | KCL_REFERENCE.md |
| "What git commands do I need?" | GIT_REFERENCE.md |

**Golden Rule**: Optimize for "Where would an agent look FIRST?" not "Where did I learn this?"

---

## How to Work on This Project

> 📖 **Complete Guides**: See [TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) for the full TDD workflow and [GIT_WORKFLOW.md](thoughts/GIT_WORKFLOW.md) for git conventions

### Starting a New Task

1. **Check** `thoughts/TASKS.md` for the next priority task
2. **Read** relevant documentation in thoughts/ directory
3. **Follow TDD workflow**: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT
4. **Update** TASKS.md when complete

### Essential Workflow

**MANDATORY TDD Workflow** (see [TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) for details):

1. 🔴 **RED**: Write composition test FIRST (must fail)
2. 🟢 **GREEN**: Implement minimum code to pass test
3. 🔵 **REFACTOR**: Improve code quality
4. 🧪 **E2E**: Write and pass E2E test (MANDATORY)
5. ✅ **COMMIT**: Only when ALL tests pass

**Before Every Commit**:
- ✅ All composition tests pass: `up test run tests/test-*`
- ✅ All E2E tests pass: `up test run tests/e2etest-* --e2e --control-plane-group=claude-testing`
- ✅ Project builds: `up project build`
- ✅ Follow conventional commits (see [GIT_WORKFLOW.md](thoughts/GIT_WORKFLOW.md))

**CRITICAL**: E2E tests are MANDATORY. Features are NOT complete without E2E validation.

## Key Files and References

> 📖 **Architecture & Patterns**: See [IMPLEMENTATION_GUIDE.md](thoughts/IMPLEMENTATION_GUIDE.md) for file structure, naming conventions, and code organization standards

### Essential References

- **Testing**: [TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md) - Complete TDD workflow
- **Git**: [GIT_WORKFLOW.md](thoughts/GIT_WORKFLOW.md) - Branching, commits, PRs
- **Commands**: [UPBOUND_REFERENCE.md](thoughts/UPBOUND_REFERENCE.md) - All `up` CLI commands
- **KCL**: [KCL_REFERENCE.md](thoughts/KCL_REFERENCE.md) - KCL patterns and syntax
- **Specification**: [SPECIFICATION.md](thoughts/SPECIFICATION.md) - Feature requirements
- **Tasks**: [TASKS.md](thoughts/TASKS.md) - Current task list

## Getting Help

If you need more context:
1. **Terraform Module**: https://github.com/terraform-aws-modules/terraform-aws-vpc
2. **Upbound Docs**: https://docs.upbound.io/
3. **Crossplane Docs**: https://docs.crossplane.io/
4. **KCL Docs**: https://kcl-lang.io/docs
5. **Platform Ref**: https://github.com/upbound/platform-ref-upbound

## Emergency Contacts

If something is fundamentally broken:
1. Check `up project stop` to clean up local runs
2. Review recent commits for issues
3. Consult thoughts/GIT_WORKFLOW.md for recovery

## Success Criteria

The project is successful when:
- ✅ All P0 and P1 tasks complete (see tasks.md)
- ✅ Feature parity with Terraform module achieved
- ✅ Comprehensive tests pass
- ✅ Documentation complete
- ✅ Package published to Upbound Marketplace

## Quick Start Commands

> 📖 **Complete Command Reference**: See [UPBOUND_REFERENCE.md](thoughts/UPBOUND_REFERENCE.md) and [GIT_REFERENCE.md](thoughts/GIT_REFERENCE.md)

```bash
# Essential Commands
up test run tests/test-*                      # Run composition tests
up test run tests/e2etest-* --e2e             # Run E2E tests
up project build                              # Build project
git commit -m "feat(scope): description"      # Commit with conventional format
```

## Remember

- **TASKS.md is your source of truth** for what to work on next
- **thoughts/ directory has all the knowledge** you need
- **Test frequently** with `up project run`
- **Follow the patterns** in KCL_REFERENCE.md
- **Keep documentation updated** as you work
- **Commit often** with clear messages

---

**Ready to start?** Open `thoughts/TASKS.md` and begin with task 1.1!

**Questions?** Everything you need is in the thoughts/ directory.

**Good luck!** You have all the resources needed to build a great Upbound configuration.
