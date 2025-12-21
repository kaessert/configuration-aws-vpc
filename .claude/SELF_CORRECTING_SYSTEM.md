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

**FIRST**: Ask human for deep understanding (What, Why, When, How)

**THEN**: Launch agent with understanding:

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

DEEP UNDERSTANDING (What/Why/When/How):
[Fill in from human's explanation]

Follow .claude/agents/documentation-correction-agent.md to:
0. Start with deep understanding (Phase 0)
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

0. Ensures deep understanding of right solution (Phase 0)
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
Ask for DEEP understanding (What/Why/When/How)
    ↓
Launch Documentation Correction Agent with understanding
    ↓
Wait for agent to complete
    ↓
Resume main task with correct info
```

## Example

**Scenario**: You assumed E2E tests were optional, but they're mandatory.

**First**: Ask human for deep understanding:
```
I need to understand WHY E2E tests are mandatory:
- Why not just composition tests?
- When did this become mandatory?
- What risks does E2E testing prevent?
- How should E2E tests be structured?
```

**Then**: Launch agent with understanding:
```bash
Task(
  subagent_type="general-purpose",
  description="Fix E2E testing docs",
  prompt="""
Documentation Correction Agent:

INCORRECT: I assumed E2E tests were optional
CORRECT: E2E tests are mandatory for all features
PROBLEM: Was implementing feature without E2E test

UNDERSTANDING:
- What: E2E tests validate actual AWS behavior, not just KCL logic
- Why: Composition tests can pass while AWS deployment fails
- When: Required for ALL features before commit
- How: Use up test run --e2e with real control plane

Follow .claude/agents/documentation-correction-agent.md to fix this.
"""
)
```

**Result**: Agent finds conflicting docs, updates with full context and reasoning.

## Remember

Every mistake is a **documentation improvement opportunity**.

Don't just fix your immediate problem - **fix the documentation** so future agents don't make the same mistake.

---

**Full details**: See `CLAUDE.md` section "Self-Correcting Documentation System"

**Agent prompt**: `.claude/agents/documentation-correction-agent.md`
