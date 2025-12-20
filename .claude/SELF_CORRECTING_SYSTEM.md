# Self-Correcting Documentation System - Quick Reference

## The Rule

**When a human corrects you** → **Launch Documentation Correction Agent** → **Fix root cause in docs**

## When to Act

Invoke the Documentation Correction Agent when:
- ❌ Your action is denied or rejected
- ❌ Your assumption is proven wrong
- ❌ Human says "that's not correct"
- ❌ You followed wrong guidance
- ❌ You missed a critical requirement

## How to Invoke

```bash
Task(
  subagent_type="general-purpose",
  description="Fix documentation issue",
  prompt="""
You are the Documentation Correction Agent.

WHAT WENT WRONG:
[Describe the incorrect action/assumption]

WHAT SHOULD HAVE HAPPENED:
[Describe the correct approach]

ORIGINAL PROBLEM:
[What were you trying to solve?]

Follow .claude/agents/documentation-correction-agent.md to:
1. Find why wrong path was taken
2. Audit documentation for issues
3. Fix all documentation problems
4. Prevent future occurrences

Goal: This mistake never happens again.
"""
)
```

## Why This Matters

- **Fixes root causes**, not symptoms
- **Improves project** for all future agents
- **Prevents repeated mistakes**
- **Keeps main context clean**

## What the Agent Does

1. Investigates why you made the wrong decision
2. Finds contradicting/missing/duplicate docs
3. Proposes specific fixes
4. Implements documentation changes
5. Adds prevention measures

## Your Workflow

```
Human corrects you
    ↓
Acknowledge the correction
    ↓
Launch Documentation Correction Agent
    ↓
Wait for agent to complete
    ↓
Resume main task with correct info
```

## Example

**Scenario**: You assumed E2E tests were optional, but they're mandatory.

**Action**:
```bash
Task(
  subagent_type="general-purpose",
  description="Fix E2E testing docs",
  prompt="""
Documentation Correction Agent:

INCORRECT: I assumed E2E tests were optional
CORRECT: E2E tests are mandatory for all features
PROBLEM: Was implementing feature without E2E test

Follow .claude/agents/documentation-correction-agent.md to fix this.
"""
)
```

**Result**: Agent finds conflicting docs, updates all locations, adds prominent warnings, improves discoverability.

## Remember

Every mistake is a **documentation improvement opportunity**.

Don't just fix your immediate problem - **fix the documentation** so future agents don't make the same mistake.

---

**Full details**: See `CLAUDE.md` section "Self-Correcting Documentation System"

**Agent prompt**: `.claude/agents/documentation-correction-agent.md`
