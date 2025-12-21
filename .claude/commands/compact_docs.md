# Compact Documentation

You are instructed to analyze and compact the project documentation by removing duplicate information and optimizing discoverability.

## Parameters

- **Target directory**: `thoughts/` (default, can be overridden)
- **File pattern**: `*.md` (default, can be overridden)
- **Context file**: `CLAUDE.md` (check for existing references)

## Process

### Phase 1: Discovery & Analysis

1. **Auto-discover files**:
   - List all markdown files in target directory
   - Read structure (headings, sections) of each file
   - Identify logical groupings based on topics and cross-references

2. **Build content matrix**:
   - Map all topics across all files
   - Identify where each piece of information appears
   - Note overlaps, duplicates, and redundancies

3. **Apply "first place to look" heuristic**:
   - For each topic, determine where an agent/developer would look FIRST
   - Consider file naming, purpose, and organization
   - Flag content that's in suboptimal locations

### Phase 2: Parallel Analysis (if >5 files)

For each logical group of related files:

1. Launch a sub-agent with Task tool to analyze the group
2. Each agent identifies:
   - Exact duplicates (same content, different locations)
   - Semantic duplicates (same meaning, different wording)
   - Overlapping content (80%+ similarity)
   - Content in wrong location (not where you'd look first)

3. Each agent suggests:
   - **KEEP**: Content in optimal location
   - **MOVE**: Content should relocate to different file
   - **MERGE**: Consolidate duplicate information
   - **DELETE**: Redundant information with no unique value
   - **SKIP**: Already optimally compact

### Phase 3: Synthesis & Planning

1. **Collect all findings** from analysis agents (or single analysis if <5 files)

2. **Resolve conflicts**:
   - If multiple locations claimed as "first place to look"
   - Use file purpose and naming as tie-breaker
   - Prefer fewer, more comprehensive files over scattered information

3. **Create execution plan**:
   - List specific edits to make (file, section, action)
   - Order by risk (low-risk consolidations first)
   - Note dependencies (change A before B)
   - Flag any ambiguous cases for human review

4. **Generate report**:
   - Summary statistics (X duplicates found, Y files affected)
   - Detailed action plan with file diffs
   - Expected outcomes (size reduction, clarity improvement)
   - Recommended execution order

### Phase 4: Execution (with approval)

1. **Present plan** to user for approval
2. **Execute changes** systematically:
   - Start with low-risk consolidations
   - Remove exact duplicates
   - Merge semantic duplicates
   - Relocate misplaced content
   - Delete pure redundancy
3. **Verify integrity**: Ensure no unique information was lost

## Principles

- **Optimize for discoverability**: Information should be where you'd look FIRST
- **Preserve all unique content**: Only remove true duplicates
- **Keep documentation flat**: Prefer scannable structure over deep nesting
- **Trust your judgment**: If files are "compact enough", skip them
- **No historical narratives**: Remove session logs, keep extracted lessons

## Parallel Execution Strategy

```bash
# If >5 files, use parallel sub-agents for speed
# Example grouping (auto-generated based on discovery):

Task(
  subagent_type="general-purpose",
  description="Analyze [group-name] docs",
  run_in_background=true,
  prompt="Analyze files: [file1, file2, ...] for duplicates..."
)

# Spawn one agent per logical group (2-5 files per group)
# Collect results and synthesize
```

## Output Format

```markdown
## Documentation Compaction Report

### Summary
- Files analyzed: X
- Duplicates found: Y
- Files to modify: Z
- Estimated size reduction: N%

### Findings by Group
#### [Group Name]
- **File**: filename.md
  - Duplicate: [description]
  - Action: [KEEP/MOVE/MERGE/DELETE]
  - Reasoning: [why this is optimal]

### Execution Plan
1. [Low-risk change 1]
2. [Low-risk change 2]
3. ...
N. [High-risk change requiring review]

### Expected Outcomes
- Improved discoverability: [specific improvements]
- Reduced redundancy: [metrics]
- Clearer organization: [structural improvements]
```

## Success Criteria

- All duplicate information removed or consolidated
- Each piece of information in the "first place to look" location
- No unique content lost
- Documentation remains flat and scannable
- Future agents can find information faster

## Notes

- This command can be re-run periodically as documentation grows
- It's self-correcting: improves its own discoverability over time
- Can be invoked on any directory, not just `thoughts/`
- Adapts to whatever file structure exists

## Related Commands

- `/iterate_project` - Main project workflow
- Documentation Correction Agent - Fixes documentation after errors
