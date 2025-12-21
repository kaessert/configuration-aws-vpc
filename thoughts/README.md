# Thoughts Directory - Documentation Index

Welcome to the `thoughts/` directory! This is your central hub for all project documentation, planning, and technical knowledge.

**New here? Start with [ONBOARDING.md](ONBOARDING.md)** - Complete setup and first task guide (2 hours)

## Quick Navigation by Use Case

**I'm new to this project**
→ Start with [Onboarding Guide](ONBOARDING.md)

**I'm implementing a new feature**
→ Follow [TDD Strategy](TDD_STRATEGY.md)

**I need to check what tasks to work on**
→ Review [Task List](planning/tasks.md)

**I need testing reference (composition + E2E)**
→ Reference [Testing Guide](tools/testing-reference.md)

**I need to look up KCL syntax or patterns**
→ Reference [KCL Guide](tools/kcl-reference.md)

**I need Upbound CLI commands**
→ Reference [Upbound CLI Guide](tools/upbound-reference.md)

**I need to understand project terminology**
→ Consult [Glossary](GLOSSARY.md)

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
│   └── initial_prompt.md        # Original project requirements
│
├── SPECIFICATION.md             # Complete feature specification (WHAT to build)
├── IMPLEMENTATION_GUIDE.md      # Architecture, workflow, testing (HOW to build)
├── TDD_STRATEGY.md              # Test-driven development workflow
├── TESTING_HISTORICAL_NOTES.md  # Historical testing implementation notes
│
└── tools/                       # Comprehensive tool references
    ├── testing-reference.md     # Complete testing guide (composition + E2E)
    ├── kcl-reference.md         # Complete KCL language reference
    └── upbound-reference.md     # Complete Upbound CLI + console reference
```

---

## Document Index

### Planning & Tasks

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [tasks.md](planning/tasks.md) | **Prioritized task list** - Source of truth for what to work on next | Always - before starting new work |
| [initial_prompt.md](planning/initial_prompt.md) | Original project requirements and goals | Understanding project origins |

### Core Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPECIFICATION.md](SPECIFICATION.md) | **Complete feature specification** - All 50+ features from Terraform module (WHAT to build) | Understanding what to implement |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | **Architecture & workflow** - Modular design, TDD process, testing strategy (HOW to build) | Planning features, implementing, testing |
| [TDD_STRATEGY.md](TDD_STRATEGY.md) | **TDD workflow** - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT | Before implementing any feature |

### Comprehensive Tool References (tools/)

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [tools/testing-reference.md](tools/testing-reference.md) | **Complete testing guide** - Composition tests, E2E tests, workflows, patterns | Writing tests, understanding testing strategy |
| [tools/kcl-reference.md](tools/kcl-reference.md) | **Complete KCL reference** - Language syntax, Crossplane patterns, typed models | Writing KCL code, looking up syntax |
| [tools/upbound-reference.md](tools/upbound-reference.md) | **Complete Upbound reference** - CLI commands, console navigation, workflows | Using Upbound CLI, managing control planes |

### Additional Resources

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [README.md](README.md) | **This file** - Navigation and index | Finding documentation |
| [ONBOARDING.md](ONBOARDING.md) | **Complete onboarding** - Setup, first task, workflows | Your first day on the project |
| [GLOSSARY.md](GLOSSARY.md) | **Terminology** - Definitions of project terms | Understanding unfamiliar terms |
| [TESTING_HISTORICAL_NOTES.md](TESTING_HISTORICAL_NOTES.md) | **Testing history** - Work sessions, lessons learned | Understanding testing decisions |

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

### Q: How do I write tests (composition or E2E)?
**A**: Reference [tools/testing-reference.md](tools/testing-reference.md) - comprehensive guide covering all testing!

### Q: What task should I work on?
**A**: Check [planning/tasks.md](planning/tasks.md) for the prioritized task list.

### Q: How do I understand what features to implement?
**A**: Read [SPECIFICATION.md](SPECIFICATION.md) for complete feature list.

### Q: How do I write KCL code?
**A**: Reference [tools/kcl-reference.md](tools/kcl-reference.md) for complete language reference and patterns.

### Q: What's the TDD workflow?
**A**: Follow [TDD_STRATEGY.md](TDD_STRATEGY.md) and [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

### Q: How do I use Upbound CLI or console?
**A**: Reference [tools/upbound-reference.md](tools/upbound-reference.md) for complete Upbound reference.

### Q: What if I'm stuck?
**A**: See "Getting Help" section in [ONBOARDING.md](ONBOARDING.md) for complete troubleshooting guide.


---

## See Also

- **Project Root**: [../CLAUDE.md](../CLAUDE.md) - Instructions for Claude Code (references this directory)
- **Testing Guide**: [../TESTING.md](../TESTING.md) - User-facing testing documentation
- **Project README**: [../README.md](../README.md) - User-facing project documentation

---

**Ready to get started?** Head to [ONBOARDING.md](ONBOARDING.md) for your first steps!

**Need testing reference?** Check [tools/testing-reference.md](tools/testing-reference.md) for complete testing guide!

**Looking for a specific topic?** Use the "Quick Navigation by Use Case" section at the top of this README.
