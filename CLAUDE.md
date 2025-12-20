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

See `thoughts/tasks.md` for the new critical task (0.1) that blocks all other work.

---

## Project Overview

**Goal**: Build an Upbound control plane configuration that provides feature parity with the popular [terraform-aws-modules/terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

**Implementation**: Using Crossplane Composite Resources, KCL composition functions, and AWS Upbound providers.

**Status**: Project is in the planning/foundation phase. All research and documentation is complete. Ready for implementation.

---

## 🔄 Self-Correcting Documentation System

**CRITICAL FOR ALL AGENTS**: This project implements a self-correcting documentation mechanism.

### When Your Actions Are Corrected

If a human user **corrects, denies, or de-validates** any of your actions or assumptions:

1. **IMMEDIATELY** launch the Documentation Correction Agent
2. **DO NOT** continue with the main task until documentation is corrected
3. **DO NOT** pollute the main context with documentation investigation

### How to Invoke the Correction Agent

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

Follow the instructions in .claude/agents/documentation-correction-agent.md to:
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
   - Review `thoughts/initial_prompt.md` for the original requirements
   - Read `thoughts/tasks.md` for the complete task breakdown
   - Read `thoughts/SPECIFICATION.md` - Complete specification of what we're building

2. **Understand the implementation approach**:
   - `thoughts/IMPLEMENTATION_GUIDE.md` - Architecture, workflow, testing strategy

3. **Learn KCL patterns**:
   - `thoughts/KCL_PATTERNS.md` - KCL coding patterns and reference

4. **Familiarize yourself with the tools**:
   - `thoughts/tools/up-cli-guide.md` - Upbound CLI reference
   - `thoughts/tools/kcl-guide.md` - KCL language guide

5. **Learn git workflows**:
   - `thoughts/git/git-workflow.md` - Git workflows and commit conventions
   - `thoughts/git/git-reference.md` - Git command reference

## The "thoughts" Directory Structure

All operational knowledge lives in the `thoughts/` directory:

```
thoughts/
├── SPECIFICATION.md            # Complete feature specification (WHAT to build)
├── IMPLEMENTATION_GUIDE.md     # Architecture and workflow (HOW to build)
├── KCL_PATTERNS.md             # KCL coding patterns reference
├── initial_prompt.md           # Original project requirements
├── tasks.md                    # Prioritized task list (START HERE)
├── tools/
│   ├── up-cli-guide.md         # How to use up CLI
│   └── kcl-guide.md            # KCL language reference
└── git/
    ├── git-workflow.md         # Git workflows and commit conventions
    └── git-reference.md        # Git command reference
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
Start with tasks from `thoughts/tasks.md`:
1. Initialize Upbound project (1.1)
2. Define XRD (1.2)
3. Create composition function scaffold (1.3)
4. Implement core VPC features (Phase 2)

## How to Work on This Project

### Starting a New Task

1. **Check tasks.md** for the next priority task
2. **Read relevant documentation** in thoughts/ directory
3. **Plan your approach** before coding
4. **Implement incrementally** with frequent testing
5. **Update tasks.md** when complete

### Before Writing Code

**ALWAYS** check these documents first:
- `thoughts/KCL_PATTERNS.md` - Ensure you follow established patterns
- `thoughts/SPECIFICATION.md` - Understand the feature requirements
- `thoughts/IMPLEMENTATION_GUIDE.md` - Architecture and workflow guidance

### Testing Your Changes

```bash
# Test locally with up project
up project run

# Apply example configurations
kubectl apply -f examples/simple-vpc.yaml

# Verify resources
kubectl get composite
kubectl describe xvpc my-vpc

# Stop when done
up project stop
```

### TDD Workflow for Features (MANDATORY)

**For EVERY new feature**, follow this workflow:

1. **🔴 RED Phase - Write Composition Test FIRST**
   ```bash
   # Generate test
   up test generate test-xvpc-<feature> --language=kcl

   # Edit test: tests/test-xvpc-<feature>/main.k
   # Assert expected resources and behavior

   # Run test (MUST fail)
   up test run tests/test-xvpc-<feature>
   # ❌ FAIL - feature not implemented (CORRECT!)
   ```

2. **🟢 GREEN Phase - Make Test Pass**
   ```bash
   # Implement minimum code in functions/vpc/
   # Edit main.k or appropriate module

   # Run test until it passes
   up test run tests/test-xvpc-<feature>
   # ✅ PASS

   # Run ALL tests (check for regressions)
   up test run tests/test-*
   # If ANY tests fail: FIX THEM NOW
   # Expected: ✅ ALL PASS
   ```

3. **🔵 REFACTOR Phase - Improve Code**
   ```bash
   # Refactor for clarity/modularity
   # Extract to modules if needed

   # Keep tests passing during refactoring
   up test run tests/test-*
   # ✅ ALL PASS
   ```

4. **🧪 E2E TEST Phase - MANDATORY Real AWS Validation**
   ```bash
   # Generate E2E test (MANDATORY for ALL major features)
   up test generate e2etest-xvpc-<feature> --e2e --language=kcl

   # Edit test: tests/e2etest-xvpc-<feature>/main.k
   # Configure:
   # - ProviderConfig with IAM role: arn:aws:iam::609897127049:role/solutions-e2e-provider-aws
   # - Use assumeRoleChain (NEVER static credentials)
   # - Set timeout: 1800-3000 seconds (30-50 minutes)
   # - Set skipDelete: false (ensure cleanup)
   # - Set validate: true
   # - Add defaultConditions: ["Ready", "Synced"]

   # Run E2E test (requires up login and group specification)
   up login
   up group list  # Check available groups
   up test run tests/e2etest-xvpc-<feature> --e2e --control-plane-group=claude-testing
   # Wait 30+ minutes for AWS resource creation
   # ✅ PASS - Resources created, reached Ready/Synced, cleaned up

   # CRITICAL: Do NOT skip this step!
   # E2E tests are MANDATORY for ALL features
   ```

5. **✅ COMMIT Phase - Only When ALL Tests Pass**
   ```bash
   # Final checks - EVERYTHING must be green
   up project build              # ✅ MUST pass
   up test run tests/test-*      # ✅ ALL composition tests MUST pass
   up test run tests/e2etest-* --e2e --control-plane-group=claude-testing  # ✅ ALL E2E tests MUST pass
   # If ANY test fails: DO NOT COMMIT - fix tests first!

   # Only commit when everything is green
   git add .
   git commit -m "feat: implement <feature>

- Add composition test for <feature>
- Implement <feature> in functions/vpc/
- Add E2E test validating real AWS behavior
- All tests passing (17 composition + N E2E)
"
   ```

**CRITICAL**: E2E tests are NOW MANDATORY. A feature is NOT complete until it's validated in real AWS.

### Before Committing (CRITICAL CHECKS)

1. **✅ ALL composition tests pass** - Run `up test run tests/test-*`
2. **✅ ALL E2E tests pass** - Run `up test run tests/e2etest-* --e2e` (MANDATORY)
3. **✅ Project builds** - Run `up project build`
4. **✅ No regressions** - All existing tests still pass
5. **✅ AWS cleanup verified** - No orphaned resources after E2E tests
6. **Update documentation** - If you changed behavior, update docs
7. **Update tasks.md** - Mark tasks complete, add new ones if needed
8. **Use conventional commits** - feat:, fix:, docs:, test:, etc.

**NEVER commit if ANY test fails (composition OR E2E). Fix tests first.**

**CRITICAL**: E2E tests are NO LONGER optional. Every feature must pass E2E validation before it's considered complete.

## Key Files to Know

### Project Files
- `upbound.yaml` - Project manifest (create in task 1.1)
- `apis/` - XRD definitions (start in task 1.2)
- `functions/` - KCL composition functions (start in task 1.3)
- `examples/` - Example configurations (task 5.1)
- `tests/` - Test configurations (task 5.2)

### Documentation Files
- `CLAUDE.md` (this file) - Instructions for coding agents
- `README.md` - User-facing documentation (create in task 6.1)
- `thoughts/tasks.md` - Always up-to-date task list

## Working with Upbound CLI

Quick reference (see thoughts/tools/up-cli-guide.md for details):

```bash
# Initialize project
up project init .

# Build project
up project build

# Run locally for testing
up project run

# Push to registry
up project push

# Login to Upbound
up login

# Stop local run
up project stop
```

## Working with KCL

Key patterns (see thoughts/KCL_PATTERNS.md):

```kcl
# Import dependencies
import models.io.upbound.sa.v1 as sav1
import utils

# Access composition parameters
oxr = option("params").oxr
oxrSpec = sav1.XVPC.spec{**oxr.spec}

# Create resources with proper metadata
items = [
    Object{
        metadata = utils._metadata("vpc") | {
            name = "my-vpc"
        }
        spec = { /* ... */ }
    }
]
```

## Common Questions

### Q: Where do I start?
**A**: Open `thoughts/tasks.md` and start with task 1.1 (Initialize Upbound Project)

### Q: How do I understand what features to implement?
**A**: Read `thoughts/SPECIFICATION.md` - it has the complete feature list from the Terraform module

### Q: What coding patterns should I follow?
**A**: Follow patterns in `thoughts/KCL_PATTERNS.md` - it's based on production Upbound projects

### Q: How do I use up-cli?
**A**: Check `thoughts/tools/up-cli-guide.md` for comprehensive up-cli documentation

### Q: How do I write KCL code?
**A**: Reference `thoughts/tools/kcl-guide.md` for language syntax and patterns

### Q: How do I commit my changes?
**A**: Follow the git workflows in `thoughts/git/git-workflow.md`

### Q: What if I'm stuck?
**A**:
1. Re-read the relevant docs in thoughts/
2. Check thoughts/KCL_PATTERNS.md for patterns
3. Review thoughts/SPECIFICATION.md for feature requirements
4. Consult thoughts/IMPLEMENTATION_GUIDE.md for workflow guidance

## Important Principles

### 1. Follow the Patterns
The patterns in `thoughts/KCL_PATTERNS.md` are based on real Upbound projects. Don't reinvent the wheel.

### 2. Test Early and Often
Use `up project run` frequently to test your changes locally before pushing.

### 3. Incremental Development
Build features incrementally. Get VPC working before adding complex features.

### 4. Document as You Go
If you learn something new or make a decision, document it in the appropriate thoughts/ file.

### 5. Keep tasks.md Updated
Always keep the task list current. It's the source of truth for project status.

### 6. Self-Correct When Wrong
When corrected by a human, **immediately** launch the Documentation Correction Agent (see Self-Correcting Documentation System above). Every mistake is an opportunity to improve documentation for future agents.

## Task Workflow

For each task in tasks.md:

```
1. Read task description and acceptance criteria
2. Review relevant documentation in thoughts/
3. Plan implementation approach
4. Implement with frequent local testing
5. Verify acceptance criteria met
6. Update tasks.md to mark complete
7. Commit with conventional commit message
8. Move to next task
```

## File Naming Conventions

- **XRDs**: `apis/<resource-name>/definition.yaml`
- **Compositions**: `apis/<resource-name>/composition.yaml`
- **Functions**: `functions/<resource-name>/main.k`
- **Utilities**: `functions/<resource-name>/utils/*.k`
- **Examples**: `examples/<use-case>.yaml`
- **Tests**: `tests/test-<scenario>/`

## Code Organization Standards

Follow the structure from platform-ref-upbound:

```
functions/vpc/
├── main.k              # Entry point, orchestration
├── kcl.mod             # Dependencies
├── vpc.k               # VPC resource generation
├── subnet.k            # Subnet logic
├── gateway.k           # Gateway logic
├── route.k             # Routing logic
└── utils/
    ├── metadata.k      # Metadata helpers
    └── tags.k          # Tag management
```

## Testing Strategy (CRITICAL - TEST-DRIVEN DEVELOPMENT)

**MANDATORY**: This project follows **strict Test-Driven Development (TDD)** with **MANDATORY E2E validation**

### The Iron Rule: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

1. **🔴 RED**: Write composition test FIRST (test MUST fail)
2. **🟢 GREEN**: Write minimum code to pass test
3. **🔵 REFACTOR**: Improve code while keeping tests green
4. **🧪 E2E TEST**: Write and pass E2E test (MANDATORY)
5. **✅ COMMIT**: Only commit when ALL tests pass (composition + E2E)

### NEVER:
- ❌ Write code before tests
- ❌ Commit failing tests
- ❌ Skip tests for "simple" features
- ❌ Write tests after implementation
- ❌ Skip E2E tests - they are MANDATORY
- ❌ Mark a feature "complete" without E2E validation

### Test Levels:

1. **Composition Tests (Unit)** - MAJORITY
   - Fast (< 10 seconds)
   - Isolated (no AWS calls)
   - 100% feature coverage
   - Run: `up test run tests/test-*`

2. **E2E Tests** - MANDATORY FOR ALL FEATURES
   - Slow (10-30 minutes)
   - Real AWS resources
   - **MANDATORY** - Required for ALL major features
   - Run: `up test run tests/e2etest-* --e2e`
   - **CRITICAL**: Composition tests validate KCL logic, E2E tests validate real AWS behavior

### Read These First:
- **[thoughts/TDD_STRATEGY.md](thoughts/TDD_STRATEGY.md)** - Complete TDD workflow
- **[thoughts/ARCHITECTURE.md](thoughts/ARCHITECTURE.md)** - Modular architecture
- **[TESTING.md](TESTING.md)** - Testing guide for contributors

## Version Control

### Branching
- `main` - Production-ready code
- `feature/*` - Feature development
- `fix/*` - Bug fixes

### Commit Messages
Use conventional commits:
```
feat: add VPC creation logic
fix: correct subnet CIDR calculation
docs: update API documentation
test: add multi-AZ test case
```

## Documentation Standards

When updating documentation:
- Keep it concise and actionable
- Include examples
- Update thoughts/tasks.md if scope changes
- Reference external docs where appropriate

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
3. Consult thoughts/git/git-workflow.md for recovery

## Success Criteria

The project is successful when:
- ✅ All P0 and P1 tasks complete (see tasks.md)
- ✅ Feature parity with Terraform module achieved
- ✅ Comprehensive tests pass
- ✅ Documentation complete
- ✅ Package published to Upbound Marketplace

## Quick Commands Cheatsheet

```bash
# Project Management
up project init .                 # Initialize project
up project build                  # Build package
up project run                    # Test locally
up project stop                   # Stop local test
up project push                   # Push to registry

# Resource Management
kubectl apply -f examples/*.yaml  # Apply examples
kubectl get composite             # List composites
kubectl get managed               # List managed resources
kubectl describe xvpc <name>      # Inspect VPC

# Testing
up test run tests/*               # Run tests
kubectl get events --sort-by='.lastTimestamp'  # Check events

# Git Operations (see thoughts/git/git-workflow.md and git-reference.md)
git status                        # Check status
git add .                         # Stage changes
git commit -m "feat: ..."         # Commit
git push                          # Push changes
```

## Remember

- **tasks.md is your source of truth** for what to work on next
- **thoughts/ directory has all the knowledge** you need
- **Test frequently** with `up project run`
- **Follow the patterns** in KCL_PATTERNS.md
- **Keep documentation updated** as you work
- **Commit often** with clear messages

---

**Ready to start?** Open `thoughts/tasks.md` and begin with task 1.1!

**Questions?** Everything you need is in the thoughts/ directory.

**Good luck!** You have all the resources needed to build a great Upbound configuration.
