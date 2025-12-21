# Thoughts Directory - Documentation Index

Welcome to the `thoughts/` directory! This is your central hub for all project documentation, planning, and technical knowledge.

**New here? Start with [ONBOARDING.md](ONBOARDING.md)** - Complete setup and first task guide (2 hours)

---

## Quick Navigation by Use Case

**I'm new to this project**
→ Start with [ONBOARDING.md](ONBOARDING.md)

**I'm implementing a new feature**
→ Follow [TDD_STRATEGY.md](TDD_STRATEGY.md)

**I need to check what tasks to work on**
→ Review [TASKS.md](TASKS.md)

**I need testing reference (composition + E2E)**
→ Reference [TESTING_REFERENCE.md](TESTING_REFERENCE.md)

**I need to look up KCL syntax or patterns**
→ Reference [KCL_REFERENCE.md](KCL_REFERENCE.md)

**I need Upbound CLI commands**
→ Reference [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md)

**I need git commands or workflows**
→ Reference [GIT_WORKFLOW.md](GIT_WORKFLOW.md) or [GIT_REFERENCE.md](GIT_REFERENCE.md)

**I need to understand project terminology**
→ Consult [GLOSSARY.md](GLOSSARY.md)

---

## Document Index

### Essential Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [ONBOARDING.md](ONBOARDING.md) | **Quick start guide** - Setup, first task, workflows | Your first day |
| [TASKS.md](TASKS.md) | **Prioritized task list** - Source of truth for what to work on | Always - before starting work |
| [TDD_STRATEGY.md](TDD_STRATEGY.md) | **TDD workflow** - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT | Before implementing any feature |

### Architecture & Specification

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPECIFICATION.md](SPECIFICATION.md) | **Complete feature spec** - All 50+ features from Terraform module | Understanding what to implement |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | **Architecture & patterns** - Modular design, code organization | Planning features, implementing |

### Tool References

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [TESTING_REFERENCE.md](TESTING_REFERENCE.md) | **Complete testing guide** - Composition tests, E2E tests, workflows | Writing tests |
| [KCL_REFERENCE.md](KCL_REFERENCE.md) | **Complete KCL reference** - Language syntax, Crossplane patterns | Writing KCL code |
| [UPBOUND_REFERENCE.md](UPBOUND_REFERENCE.md) | **Complete Upbound reference** - CLI commands, console navigation | Using Upbound CLI |
| [GIT_WORKFLOW.md](GIT_WORKFLOW.md) | **Git workflows** - Commit conventions, branching, PRs | Making commits |
| [GIT_REFERENCE.md](GIT_REFERENCE.md) | **Git commands** - Command syntax reference | Looking up git commands |

### Additional Resources

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [GLOSSARY.md](GLOSSARY.md) | **Terminology** - Definitions of project terms | Understanding unfamiliar terms |

---

## Getting Started

**New to this project?** → [ONBOARDING.md](ONBOARDING.md)

---

## Quick Answers

- **Where to start?** → [ONBOARDING.md](ONBOARDING.md)
- **What to work on?** → [TASKS.md](TASKS.md)
- **How to test?** → [TESTING_REFERENCE.md](TESTING_REFERENCE.md)
- **How to write KCL?** → [KCL_REFERENCE.md](KCL_REFERENCE.md)
- **How to commit?** → [GIT_WORKFLOW.md](GIT_WORKFLOW.md)

---

## Maintenance Notes

### Updating Documentation

**When to update**:
- ✅ Behavior changes → Update relevant guide
- ✅ New pattern discovered → Add to appropriate reference file
- ✅ Task completed → Update TASKS.md
- ✅ New feature added → Update SPECIFICATION.md if needed
- ✅ Tool version changed → Update relevant reference doc

**How to update**:
1. Find the relevant document using this README
2. Edit the document directly
3. Update cross-references if paths change
4. Keep this README in sync if you add/remove/move files

### Adding New Documents

**Process**:
1. Create document in thoughts/ directory (flat structure)
2. Add entry to this README in "Document Index" section
3. Update [ONBOARDING.md](ONBOARDING.md) if it's essential reading
4. Add "See Also" section to new document with links to related docs
5. Update related documents to link to new document

### Archiving Old Documents

**When to archive**:
- Document is outdated and replaced by newer doc
- Information has been merged into another doc
- No longer relevant to project

**Process**:
1. Move document to project root or delete if truly obsolete
2. Update this README to remove references
3. Update cross-references in other documents
4. Add note in commit message explaining why archived

---

## See Also

- **Project Root**: [../CLAUDE.md](../CLAUDE.md) - Instructions for Claude Code (references this directory)
- **Project README**: [../README.md](../README.md) - User-facing project documentation

---

**Ready to get started?** Head to [ONBOARDING.md](ONBOARDING.md) for your first steps!

**Need testing reference?** Check [TESTING_REFERENCE.md](TESTING_REFERENCE.md) for complete testing guide!

**Looking for a specific topic?** Use the "Quick Navigation by Use Case" section at the top of this README.
