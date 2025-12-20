# Thoughts Directory - Documentation Index

Welcome to the `thoughts/` directory! This is your central hub for all project documentation, planning, and technical knowledge.

**New here? Start with [ONBOARDING.md](ONBOARDING.md)** - Complete setup and first task guide (2 hours)

## Quick Navigation by Use Case

**I'm new to this project**
→ Start with [Onboarding Guide](ONBOARDING.md)

**I need to write an E2E test** (Critical for Task 0.1!)
→ Follow [E2E Test Implementation Guide](testing/e2e-implementation-guide.md)

**I need to understand the architecture**
→ Read [Architecture Overview](architecture/ARCHITECTURE.md)

**I'm implementing a new feature**
→ Follow [TDD Strategy](development/TDD_STRATEGY.md)

**I need to check what tasks to work on**
→ Review [Task List](planning/tasks.md)

**I need to look up a KCL pattern**
→ Reference [KCL Guide](development/kcl-guide.md)

**I'm stuck on a git operation**
→ Check [Git Workflow Guide](development/git-workflow.md)

**I need to understand project terminology**
→ Consult [Glossary](GLOSSARY.md)

**I need Upbound CLI commands**
→ Reference [Upbound CLI Guide](reference/up-cli-guide.md)

**I'm reviewing code or running tests**
→ Read [Testing Overview](testing/TESTING_OVERVIEW.md)

---

## Directory Structure

```
thoughts/
├── README.md                    # This file - navigation index
├── ONBOARDING.md                # Complete onboarding guide for new contributors
├── GLOSSARY.md                  # Project terminology
│
├── planning/                    # Project planning and tasks
│   ├── tasks.md                 # Prioritized task list (SOURCE OF TRUTH)
│   ├── initial_prompt.md        # Original project requirements
│   └── initial_summary.md       # Foundation setup summary
│
├── SPECIFICATION.md             # Complete feature specification (WHAT to build)
├── IMPLEMENTATION_GUIDE.md      # Architecture, workflow, testing (HOW to build)
├── KCL_PATTERNS.md              # KCL coding patterns reference
├── TDD_STRATEGY.md              # Test-driven development workflow
│
├── tools/                       # Tool references
│   ├── up-cli-guide.md          # Upbound CLI command reference
│   └── kcl-guide.md             # KCL language reference
│
├── git/                         # Git workflows
│   ├── git-workflow.md          # Git operations and commit conventions
│   └── git-reference.md         # Git command reference
│
├── testing/                     # Testing documentation
│   ├── TESTING_OVERVIEW.md      # Testing philosophy and strategy
│   ├── composition-testing.md   # Composition test guide
│   ├── e2e-testing.md           # E2E test reference documentation
│   └── e2e-implementation-guide.md  # Step-by-step E2E test guide (CRITICAL)
│
└── reference/                   # Tool references and external docs
    ├── up-cli-guide.md          # Upbound CLI command reference
    ├── upbound-cloud.md         # Upbound Cloud console and management
    └── UPBOUND_DOCS_INDEX.md    # Index of external Upbound documentation
```

---

## Document Index

### Planning & Tasks

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [tasks.md](planning/tasks.md) | **Prioritized task list** - Source of truth for what to work on next | Always - before starting new work |
| [initial_prompt.md](planning/initial_prompt.md) | Original project requirements and goals | Understanding project origins |
| [initial_summary.md](planning/initial_summary.md) | Foundation setup summary | Understanding what was done initially |

### Core Documentation (CONSOLIDATED)

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPECIFICATION.md](SPECIFICATION.md) | **Complete feature specification** - All 50+ features from Terraform module (WHAT to build) | Understanding what to implement |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | **Architecture & workflow** - Modular design, TDD process, testing strategy (HOW to build) | Planning features, implementing, testing |
| [KCL_PATTERNS.md](KCL_PATTERNS.md) | **KCL coding patterns** - Production patterns from platform-ref-upbound | Writing composition functions |
| [TDD_STRATEGY.md](TDD_STRATEGY.md) | **TDD workflow** - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT | Before implementing any feature |

### Tool References

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [tools/up-cli-guide.md](tools/up-cli-guide.md) | **Upbound CLI reference** - Commands, workflows | Using up CLI |
| [tools/kcl-guide.md](tools/kcl-guide.md) | **KCL language reference** - Syntax, patterns, examples | Writing KCL code |
| [git/git-workflow.md](git/git-workflow.md) | **Git operations** - Branching, commits, PRs, conventions | Making commits and PRs |

### Testing Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [TESTING_OVERVIEW.md](testing/TESTING_OVERVIEW.md) | **Testing strategy** - Test pyramid, when to use each test type | Understanding testing approach |
| [composition-testing.md](testing/composition-testing.md) | **Composition tests** - Writing fast unit tests | Writing composition tests |
| [e2e-testing.md](testing/e2e-testing.md) | **E2E testing reference** - Complete E2E test documentation | Understanding E2E test phases |
| [e2e-implementation-guide.md](testing/e2e-implementation-guide.md) | **E2E implementation** - Step-by-step guide with examples | **Writing E2E tests** (CRITICAL for Task 0.1) |

### Reference Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [up-cli-guide.md](reference/up-cli-guide.md) | **Upbound CLI** - Complete command reference | Using up CLI commands |
| [upbound-cloud.md](reference/upbound-cloud.md) | **Upbound Cloud** - Console navigation, management | Monitoring E2E tests, managing control planes |
| [UPBOUND_DOCS_INDEX.md](reference/UPBOUND_DOCS_INDEX.md) | **External docs index** - Links to official Upbound docs | Finding official documentation |

### Quick Reference

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [README.md](README.md) | **This file** - Navigation and index | Finding documentation |
| [ONBOARDING.md](ONBOARDING.md) | **Complete onboarding** - Setup, first task, workflows | Your first day on the project |
| [GLOSSARY.md](GLOSSARY.md) | **Terminology** - Definitions of project terms | Understanding unfamiliar terms |

---

## Getting Started

**New to this project?** Follow the [ONBOARDING.md](ONBOARDING.md) guide for:
- Complete setup instructions (prerequisites, installation, authentication)
- Essential reading plan with time estimates
- Your first task (writing E2E tests for Task 0.1)
- TDD workflow overview
- First commit guide
- Common commands and troubleshooting

**Time to productivity**: ~2 hours

---

## Maintenance Notes

### Updating Documentation

**When to update**:
- ✅ Behavior changes → Update relevant guide
- ✅ New pattern discovered → Add to KCL_PATTERNS.md
- ✅ Task completed → Update tasks.md
- ✅ New feature added → Update SPECIFICATION.md if needed
- ✅ Tool version changed → Update relevant tool reference doc

**How to update**:
1. Find the relevant document using this README
2. Edit the document directly
3. Update cross-references if paths change
4. Keep this README in sync if you add/remove/move files

### Adding New Documents

**Process**:
1. Create document in appropriate directory (planning/, architecture/, development/, testing/, reference/)
2. Add entry to this README in "Document Index" section
3. Update [ONBOARDING.md](ONBOARDING.md) if it's essential reading for new contributors
4. Add "See Also" section to new document with links to related docs
5. Update related documents to link to new document

### Archiving Old Documents

**When to archive**:
- Document is outdated and replaced by newer doc
- Information has been merged into another doc
- No longer relevant to project

**Process**:
1. Create `thoughts/archive/` directory if doesn't exist
2. Move document to archive with date prefix: `YYYY-MM-DD-original-name.md`
3. Update this README to remove references
4. Update cross-references in other documents
5. Add note in commit message explaining why archived

---

## Common Questions

### Q: Where do I start?
**A**: Read [ONBOARDING.md](ONBOARDING.md) for complete setup and first task guide.

### Q: How do I write an E2E test?
**A**: Follow [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) - it's step-by-step with examples!

### Q: What task should I work on?
**A**: Check [planning/tasks.md](planning/tasks.md) - currently **Task 0.1** (write E2E tests) is BLOCKING all other work!

### Q: How do I understand what features to implement?
**A**: Read [SPECIFICATION.md](SPECIFICATION.md) for complete feature list.

### Q: What coding patterns should I follow?
**A**: Follow [KCL_PATTERNS.md](KCL_PATTERNS.md) based on production Upbound projects.

### Q: How do I write KCL code?
**A**: Reference [KCL_PATTERNS.md](KCL_PATTERNS.md) for patterns and [tools/kcl-guide.md](tools/kcl-guide.md) for syntax.

### Q: What's the TDD workflow?
**A**: Follow [TDD_STRATEGY.md](TDD_STRATEGY.md) and [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

### Q: How do I commit my changes?
**A**: Follow [git/git-workflow.md](git/git-workflow.md) for git operations and conventions.

### Q: What if I'm stuck?
**A**: See "Getting Help" section in [ONBOARDING.md](ONBOARDING.md) for complete troubleshooting guide.


---

## See Also

- **Project Root**: [../CLAUDE.md](../CLAUDE.md) - Instructions for Claude Code (references this directory)
- **Testing Guide**: [../TESTING.md](../TESTING.md) - User-facing testing documentation
- **Project README**: [../README.md](../README.md) - User-facing project documentation

---

**Ready to get started?** Head to [ONBOARDING.md](ONBOARDING.md) for your first steps!

**Need to write E2E tests?** Jump to [testing/e2e-implementation-guide.md](testing/e2e-implementation-guide.md) right now!

**Looking for a specific topic?** Use the "Quick Navigation by Use Case" section at the top of this README.
