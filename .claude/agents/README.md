# Claude Agents Directory

This directory contains specialized agent prompts for the configuration-aws-vpc project.

## Purpose

Specialized agents handle specific tasks that:
1. Require focused investigation without polluting main context
2. Follow a specific, repeatable methodology
3. Produce structured outputs
4. Can be invoked as sub-agents from the main session

## Available Agents

### Documentation Correction Agent

**File**: `documentation-correction-agent.md`

**Purpose**: Investigates and corrects documentation issues that led to incorrect agent decisions.

**When to use**: Immediately after a human corrects, denies, or de-validates an agent's action or assumption.

**What it does**:
- Audits project documentation for contradictions, gaps, and duplications
- Identifies root causes of incorrect decisions
- Proposes and implements documentation fixes
- Adds prevention measures to avoid future mistakes

**How to invoke**:
```bash
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

**Expected outcomes**:
- Documentation issues identified and fixed
- Consistency restored across all documentation
- Improved discoverability of critical information
- Prevention measures implemented

## Adding New Agents

When creating a new specialized agent:

1. **Create a markdown file** in this directory with a descriptive name
2. **Structure the prompt** with clear sections:
   - Purpose and mission
   - When to invoke
   - Investigation/execution steps
   - Output format requirements
   - Success criteria
3. **Update this README** with the new agent details
4. **Reference in CLAUDE.md** if it's a critical agent all agents should know about

## Design Principles

Good specialized agents:
- Have a **single, clear purpose**
- Follow a **structured methodology**
- Produce **actionable outputs**
- **Don't pollute** the main context
- Can be **repeatedly invoked** with consistent results
- **Improve the project** systematically

## Related Documentation

- `/CLAUDE.md` - Main agent instructions (references the self-correcting system)
- `/thoughts/` - Project knowledge base that agents work with
