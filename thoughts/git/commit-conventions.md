# Git Commit Conventions

## IMPORTANT: Commit Message Rules

### What NOT to Include

**NEVER mention these in commit messages**:
- ❌ "Claude" or "Claude Code"
- ❌ "Anthropic"
- ❌ "Generated with Claude Code"
- ❌ "Co-Authored-By: Claude Sonnet"
- ❌ Any AI attribution or generation references

**Reason**: Commits should appear as human-authored without AI tooling references.

---

## Commit Message Format

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools
- **ci**: Changes to CI configuration files and scripts

### Scope (optional)

The scope should be the name of the module/area affected:
- vpc
- subnets
- gateways
- routes
- endpoints
- tests
- workflows
- etc.

### Subject

- Use imperative mood ("add" not "added" or "adds")
- Don't capitalize first letter
- No period at the end
- Keep under 50 characters

### Body

- Wrap at 72 characters
- Explain what and why, not how
- Separate from subject with blank line
- Use bullet points for multiple items

### Footer

- Reference issues: `Closes #123` or `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

---

## Examples

### Good Commit Messages

```
feat(vpc): add support for secondary CIDR blocks

- Implement VPC CIDR block association
- Support multiple CIDR blocks per VPC
- Update routing logic to handle secondary CIDRs

Closes #42
```

```
test(subnets): add composition tests for all subnet types

Added comprehensive composition tests covering:
- Public subnets with IGW routing
- Private subnets with NAT routing
- Database, elasticache, redshift subnets (isolated)
- Intra subnets (no internet access)
- Multi-AZ distribution validation
```

```
fix(nat): correct EIP allocation for NAT Gateway

Fixed issue where EIP was not properly allocated when using
single NAT Gateway strategy. Now creates EIP before NAT Gateway
and properly references it in the NAT spec.

Fixes #78
```

```
docs: add comprehensive testing guide

Created detailed testing documentation covering:
- Composition tests for unit testing
- E2E tests for integration testing
- Test organization and naming conventions
- CI/CD integration patterns
- AWS credentials configuration
```

```
ci: update E2E workflow for dedicated control plane group

Modified E2E workflow to use dedicated control plane group
for test isolation. Tests now run in configuration-aws-vpc-e2e
group with proper IAM role assumption.
```

### Bad Commit Messages

```
❌ Update files

# Too vague, doesn't explain what was updated or why
```

```
❌ feat: implemented the thing

# Not descriptive, unclear what "the thing" is
```

```
❌ Fixed bug.

# Missing details about what bug and how it was fixed
```

```
❌ WIP

# Work-in-progress commits should be squashed before merging
```

```
❌ feat: add VPC support

Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

# ❌ NEVER include AI attribution
```

---

## Commit Workflow

### Before Committing

1. **Review changes**: `git diff` or `git diff --staged`
2. **Run tests**: Ensure tests pass
3. **Stage relevant files**: `git add <files>`
4. **Write clear message**: Follow conventions above

### Commit Command

```bash
# For simple commits
git commit -m "feat(vpc): add DNS support"

# For commits with body
git commit -m "feat(vpc): add DNS support" -m "Added enableDnsHostnames and enableDnsSupport parameters to VPC spec. These control DNS resolution and hostname assignment in the VPC."

# Using heredoc for multi-line (recommended for complex commits)
git commit -m "$(cat <<'EOF'
feat(subnets): implement subnet distribution across AZs

Added logic to distribute subnets evenly across specified
availability zones. Each subnet type (public, private, database,
etc.) now creates one subnet per AZ with proper CIDR allocation.

Changes:
- Add AZ distribution logic to subnet.k
- Implement CIDR block calculation
- Update subnet naming to include AZ suffix
- Add validation for CIDR conflicts
EOF
)"
```

### After Committing

```bash
# Review commit
git show HEAD

# Amend if needed (only if not pushed!)
git commit --amend

# Push to remote
git push origin <branch>
```

---

## Special Cases

### Fixing Previous Commit

```bash
# Fix and amend (only if not pushed!)
git add <fixed-files>
git commit --amend --no-edit

# Or amend with new message
git commit --amend -m "new message"
```

### Squashing WIP Commits

```bash
# Interactive rebase to squash last N commits
git rebase -i HEAD~N

# Change 'pick' to 'squash' for commits to combine
# Save and edit combined commit message
```

### Reverting a Commit

```bash
# Create revert commit
git revert <commit-hash>

# Revert without committing (for manual fixes)
git revert -n <commit-hash>
```

---

## Branch Naming

Use descriptive branch names:

```
feature/<feature-name>
fix/<issue-description>
test/<test-description>
docs/<doc-update>
refactor/<what-is-refactored>
```

Examples:
- `feature/nat-gateway-strategies`
- `fix/subnet-cidr-calculation`
- `test/add-composition-tests`
- `docs/update-testing-guide`
- `refactor/extract-route-logic`

---

## Commit Frequency

### When to Commit

- ✅ After completing a logical unit of work
- ✅ After tests pass
- ✅ Before switching tasks
- ✅ At the end of work session
- ✅ After fixing a bug
- ✅ After adding a feature

### Commit Size

- **Too small**: Every line change separately
- **Too large**: Multiple features in one commit
- **Just right**: One logical change per commit

**Good examples**:
- One feature implementation
- One bug fix
- One refactoring
- Related tests for a feature

**Bad examples**:
- Half of a feature
- Multiple unrelated fixes
- Mixing features and refactoring

---

## PR Commit Strategy

### During Development

- Make small, frequent commits
- Use WIP commits if needed
- Focus on making progress

### Before Creating PR

**Option 1: Squash WIP commits**
```bash
git rebase -i HEAD~N
# Squash WIP commits into meaningful commits
```

**Option 2: Use squash merge**
- Keep all commits during development
- Use "Squash and merge" when merging PR
- Write good commit message during merge

### PR Title

PR title should follow same conventions as commits:
```
feat(vpc): add support for secondary CIDR blocks
fix(nat): correct EIP allocation for NAT Gateway
test(subnets): add composition tests for all types
```

---

## Summary

**DO**:
- ✅ Use conventional commit format
- ✅ Write clear, descriptive messages
- ✅ Explain what and why
- ✅ Keep commits focused and atomic
- ✅ Run tests before committing
- ✅ Review changes before committing

**DON'T**:
- ❌ Mention AI tools (Claude, Anthropic, etc.)
- ❌ Add AI attribution or generation markers
- ❌ Write vague messages ("fix bug", "update code")
- ❌ Commit unrelated changes together
- ❌ Commit broken code
- ❌ Forget to stage files

**Remember**:
- Commits should read as if written by a human developer
- No references to AI assistance, tooling, or generation
- Clear, professional, and focused on the technical changes
