# Upbound Documentation Index

Quick reference guide to all Upbound-related documentation in this project.

## Core Documentation Files

### 1. [upbound-cloud-management.md](./upbound-cloud-management.md) ⭐ NEW
**Comprehensive guide for managing Upbound Cloud resources**

**What's inside:**
- Complete explanation of the hierarchy: Organization → Space → Group → Control Plane
- How to create, list, get, and delete Groups
- How to create, list, get, and delete Control Planes
- Profile safety checks (CRITICAL: must be on "solutions" profile)
- Context management with `up ctx`
- Common workflows and best practices
- Troubleshooting and debugging
- Safety checklists

**Use this when:**
- Creating or deleting groups
- Creating or deleting control planes
- You need to understand the Upbound Cloud structure
- Running E2E tests with control plane groups
- Managing multiple environments

### 2. [up-cli-guide.md](./up-cli-guide.md)
**Complete reference for all up CLI commands**

**What's inside:**
- Authentication and profiles
- Project management (init, build, push, run)
- Control plane basics (now references upbound-cloud-management.md)
- Space and group basics (now references upbound-cloud-management.md)
- Organization and team management
- Repository and dependency management
- Testing commands
- Output formatting
- Common workflows
- Environment variables
- Quick reference cheatsheet

**Use this when:**
- You need a quick command reference
- Working with projects (build, push, test)
- Managing dependencies
- Looking for command syntax and flags
- Need to find a specific up command

### 3. [e2e-test-control-plane-setup.md](./e2e-test-control-plane-setup.md)
**E2E test configuration and control plane group usage**

**What's inside:**
- Why you must use `--control-plane-group=claude-testing` for local E2E tests
- What control plane groups are and how they work
- E2E test lifecycle (automatic creation and cleanup)
- Debugging failed E2E tests
- Best practices for test control planes

**Use this when:**
- Running E2E tests locally
- Debugging E2E test failures
- Understanding E2E test cleanup

### 4. [kcl-guide.md](./kcl-guide.md)
**KCL language reference for writing composition functions**

**Use this when:**
- Writing KCL composition functions
- Need syntax reference for KCL

### 5. [upbound-console-guide.md](./upbound-console-guide.md)
**Guide for using the Upbound Cloud web console**

**What's inside:**
- How to navigate to spaces, groups, and control planes in the UI
- Monitoring E2E test progress
- Viewing package installations
- Checking resource status
- Analyzing events and logs

**Use this when:**
- Monitoring E2E tests in the browser
- Debugging resource creation issues
- Checking control plane status visually
- Need to access the web console

## Quick Decision Tree

**I need to...**

### Create a group
→ Read: [upbound-cloud-management.md](./upbound-cloud-management.md)
→ Section: "Working with Groups" → "Create a Group"

### Create a control plane
→ Read: [upbound-cloud-management.md](./upbound-cloud-management.md)
→ Section: "Working with Control Planes" → "Create a Control Plane"

### Delete a group or control plane
→ Read: [upbound-cloud-management.md](./upbound-cloud-management.md)
→ Section: "Safety Checklist" FIRST, then relevant delete section

### Understand the Upbound hierarchy
→ Read: [upbound-cloud-management.md](./upbound-cloud-management.md)
→ Section: "Understanding the Upbound Cloud Hierarchy"

### Run E2E tests
→ Read: [e2e-test-control-plane-setup.md](./e2e-test-control-plane-setup.md)
→ And: [upbound-cloud-management.md](./upbound-cloud-management.md) for group creation

### Build and push a project
→ Read: [up-cli-guide.md](./up-cli-guide.md)
→ Section: "Project Management"

### Write KCL code
→ Read: [kcl-guide.md](./kcl-guide.md)

### Monitor tests in browser
→ Read: [upbound-console-guide.md](./upbound-console-guide.md)

### Find a specific up command
→ Read: [up-cli-guide.md](./up-cli-guide.md)
→ Section: "Quick Reference" at the end

## Critical Safety Reminders

### 🚨 ALWAYS Check Profile First

Before ANY operation that creates or deletes resources:

```bash
up profile current
```

**Must show**: `"organization": "solutions"`

If not on "solutions" profile: **STOP IMMEDIATELY**

### 🚨 Deletion Warnings

- **Deleting a group deletes ALL control planes in it**
- **Deleting a control plane deletes all resources it manages**
- **Always backup before deletion**
- **Always verify context before deletion**

See [upbound-cloud-management.md](./upbound-cloud-management.md) → "Safety Checklist"

## File Locations

All documentation is in `thoughts/tools/`:

```
thoughts/tools/
├── UPBOUND_DOCS_INDEX.md              # This file
├── upbound-cloud-management.md        # NEW: Groups & Control Planes
├── up-cli-guide.md                    # Complete CLI reference
├── e2e-test-control-plane-setup.md    # E2E test configuration
├── kcl-guide.md                       # KCL language reference
└── upbound-console-guide.md           # Web console guide
```

## Recent Changes

**2025-12-19**: Created comprehensive Upbound Cloud management guide
- Added complete hierarchy explanation (Organization → Space → Group → Control Plane)
- Documented all group operations (create, list, get, delete)
- Documented all control plane operations (create, list, get, delete)
- Added CRITICAL profile safety checks
- Added context management guide
- Added common workflows and troubleshooting
- Added safety checklists
- Updated up-cli-guide.md with references to new guide

## Additional Resources

- [Upbound Documentation](https://docs.upbound.io/)
- [Upbound Cloud Console](https://console.upbound.io/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [up CLI GitHub](https://github.com/upbound/up)

---

**Need help?** Start with [upbound-cloud-management.md](./upbound-cloud-management.md) for most common tasks!
