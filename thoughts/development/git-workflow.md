# Git Workflow Guide

## Overview

This guide covers git operations and commit conventions for the AWS VPC Configuration for Upbound project. Follow these workflows for consistent, professional git practices.

---

## Table of Contents

1. [Commit Message Conventions](#commit-message-conventions)
2. [Making Commits](#making-commits)
3. [Branch Management](#branch-management)
4. [Creating Pull Requests](#creating-pull-requests)
5. [Common Workflows](#common-workflows)
6. [Best Practices](#best-practices)

---

## Commit Message Conventions

### Format

Follow **Conventional Commits** format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature | `feat(vpc): add DNS support` |
| `fix` | Bug fix | `fix(nat): correct EIP allocation` |
| `docs` | Documentation | `docs: update testing guide` |
| `test` | Tests | `test(subnets): add composition tests` |
| `refactor` | Code refactoring | `refactor(routes): extract route logic` |
| `perf` | Performance improvement | `perf(vpc): optimize CIDR calculation` |
| `style` | Formatting, whitespace | `style: format KCL code` |
| `chore` | Dependencies, config | `chore: update dependencies` |
| `ci` | CI configuration | `ci: update E2E workflow` |

### Scope (Optional)

Scope indicates which module is affected:
- `vpc` - VPC-related changes
- `subnets` - Subnet logic
- `gateways` - IGW, NAT Gateway
- `routes` - Routing logic
- `endpoints` - VPC Endpoints
- `tests` - Testing infrastructure
- `workflows` - CI/CD workflows

### Subject Line Rules

- ✅ Use imperative mood ("add" not "added" or "adds")
- ✅ Don't capitalize first letter
- ✅ No period at the end
- ✅ Keep under 50 characters
- ✅ Be specific and descriptive

**Good examples**:
- `feat(vpc): add secondary CIDR support`
- `fix(nat): resolve EIP allocation issue`
- `test: add composition tests for routing`

**Bad examples**:
- ❌ `feat: Update files` (too vague)
- ❌ `Added VPC support.` (wrong tense, capitalized, has period)
- ❌ `WIP` (not descriptive)

### Body (Optional but Recommended)

- Wrap at 72 characters
- Explain **what** and **why**, not how
- Separate from subject with blank line
- Use bullet points for multiple items

### Footer (Optional)

- Reference issues: `Closes #123` or `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

---

### IMPORTANT: What NOT to Include

**NEVER include in commit messages**:
- ❌ "Claude" or "Claude Code"
- ❌ "Anthropic"
- ❌ "Generated with Claude Code"
- ❌ "Co-Authored-By: Claude Sonnet"
- ❌ Any AI attribution or generation references

**Reason**: Commits should appear as human-authored without AI tooling references.

---

### Example Commits

**Good commit messages**:

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
for test isolation. Tests now run in claude-testing group
with proper IAM role assumption.
```

---

## Making Commits

### Check Repository Status

```bash
# View current status
git status

# Short format
git status -s

# Show branch info
git branch --show-current
```

### Staging Files

```bash
# Stage specific files
git add functions/vpc/main.k
git add tests/test-xvpc-basic/main.k

# Stage all changes in current directory
git add .

# Stage all changes in repository
git add -A

# Stage only modified/deleted files (not new files)
git add -u

# Stage files interactively
git add -p
```

### Review Changes Before Committing

```bash
# View unstaged changes
git diff

# View staged changes
git diff --staged

# View changes for specific file
git diff functions/vpc/main.k
```

### Writing Commits

**Simple commit**:
```bash
git commit -m "feat(vpc): add DNS support"
```

**Commit with body** (recommended):
```bash
git commit -m "feat(vpc): add DNS support" -m "Added enableDnsHostnames and enableDnsSupport parameters to VPC spec. These control DNS resolution and hostname assignment in the VPC."
```

**Multi-line commit with heredoc** (best for complex commits):
```bash
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

# View commit history
git log --oneline -5

# Push to remote
git push origin <branch-name>
```

---

## Branch Management

### Creating Branches

```bash
# Create and switch to new branch
git checkout -b feature/nat-gateway-strategies

# Alternative with newer syntax
git switch -c feature/nat-gateway-strategies

# Create branch from specific commit
git checkout -b hotfix/security-patch main
```

### Branch Naming Conventions

Use descriptive branch names with prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New features | `feature/nat-gateway-strategies` |
| `fix/` | Bug fixes | `fix/subnet-cidr-calculation` |
| `test/` | Testing work | `test/add-composition-tests` |
| `docs/` | Documentation | `docs/update-testing-guide` |
| `refactor/` | Refactoring | `refactor/extract-route-logic` |
| `hotfix/` | Urgent production fixes | `hotfix/security-patch` |

### Switching Branches

```bash
# Switch to existing branch
git checkout main
git switch main

# Switch to previous branch
git checkout -
git switch -
```

### Viewing Branches

```bash
# Show current branch
git branch --show-current

# List all local branches (* indicates current)
git branch

# List all branches (local and remote)
git branch -a

# List with last commit info
git branch -v

# List merged branches
git branch --merged

# List unmerged branches
git branch --no-merged
```

### Deleting Branches

```bash
# Delete local branch (safe - prevents deletion if unmerged)
git branch -d feature/completed-feature

# Force delete local branch
git branch -D feature/abandoned-feature

# Delete remote branch
git push origin --delete feature/old-feature

# Prune deleted remote branches from local
git fetch --prune
```

---

## Creating Pull Requests

### Using gh CLI

**Basic PR creation**:
```bash
# Create PR interactively
gh pr create

# Create PR with title and body
gh pr create --title "Add NAT Gateway support" --body "Implements single and per-AZ NAT strategies"
```

**PR with formatted body**:
```bash
gh pr create --title "Add NAT Gateway support" --body "$(cat <<'EOF'
## Summary
- Implement single NAT Gateway strategy
- Implement per-AZ NAT Gateway strategy
- Add composition tests for both strategies
- Add E2E test for NAT validation

## Test Plan
- Run composition tests: up test run tests/test-xvpc-nat-*
- Run E2E test: up test run tests/e2etest-xvpc-nat-single --e2e
- Verify AWS resources created and cleaned up

## Related Issues
Closes #42
EOF
)"
```

**Advanced PR options**:
```bash
# Create PR with reviewers
gh pr create --title "Fix NAT bug" --body "..." --reviewer user1,user2

# Create PR with labels
gh pr create --title "Add E2E tests" --body "..." --label "run-e2e-tests"

# Create PR as draft
gh pr create --title "WIP: Feature" --body "..." --draft

# Create PR to different base branch
gh pr create --base develop --title "..." --body "..."
```

### PR Commit Strategy

**During development**:
- Make small, frequent commits
- Use WIP commits if needed
- Focus on making progress

**Before creating PR**:

**Option 1: Clean up commits**
```bash
# Squash WIP commits into meaningful commits
git rebase -i HEAD~N
# Change 'pick' to 'squash' for commits to combine
```

**Option 2: Squash on merge**
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

## Common Workflows

### Workflow 1: Feature Development

```bash
# 1. Create feature branch
git checkout -b feature/vpc-endpoints

# 2. Make changes and commit
git add functions/vpc/endpoints.k
git commit -m "feat(endpoints): add VPC endpoint support"

# 3. Run tests
up test run tests/test-xvpc-endpoints

# 4. Push to remote
git push origin feature/vpc-endpoints

# 5. Create PR
gh pr create --title "feat(endpoints): add VPC endpoint support" \
  --body "Implements VPC endpoints for S3, DynamoDB, and other services"

# 6. After approval, merge (via GitHub UI or CLI)
gh pr merge --squash
```

---

### Workflow 2: Bug Fix

```bash
# 1. Create fix branch
git checkout -b fix/subnet-cidr

# 2. Fix bug and commit
git add functions/vpc/subnet.k
git commit -m "fix(subnet): correct CIDR block calculation for private subnets"

# 3. Run tests to verify fix
up test run tests/test-xvpc-subnets-private

# 4. Push and create PR
git push origin fix/subnet-cidr
gh pr create --title "fix(subnet): correct CIDR calculation" \
  --body "Fixes #78"

# 5. Merge after approval
gh pr merge --squash
```

---

### Workflow 3: Adding Tests (Task 0.1)

```bash
# 1. Create test branch
git checkout -b test/add-e2e-tests

# 2. Generate and write E2E test
up test generate e2etest-xvpc-feature --e2e --language=kcl
# Edit tests/e2etest-xvpc-feature/main.k

# 3. Run E2E test
up test run tests/e2etest-xvpc-feature --e2e --control-plane-group=claude-testing

# 4. Verify cleanup in AWS Console (CRITICAL!)

# 5. Commit
git add tests/e2etest-xvpc-feature/
git commit -m "$(cat <<'EOF'
test: add E2E test for VPC feature

- Add E2E test validating real AWS VPC behavior
- Configure ProviderConfig with IAM role
- Set timeout to 30 minutes
- Verify cleanup after test completes
- E2E test passes, all resources cleaned up
EOF
)"

# 6. Push and create PR
git push origin test/add-e2e-tests
gh pr create --title "test: add E2E test for VPC feature" \
  --body "Adds E2E validation for Task 0.1" \
  --label "run-e2e-tests"
```

---

### Workflow 4: Updating Documentation

```bash
# 1. Create docs branch
git checkout -b docs/update-testing-guide

# 2. Update documentation
# Edit thoughts/testing/e2e-implementation-guide.md

# 3. Commit
git add thoughts/testing/e2e-implementation-guide.md
git commit -m "docs: add troubleshooting section to E2E guide"

# 4. Push and create PR
git push origin docs/update-testing-guide
gh pr create --title "docs: improve E2E testing guide" \
  --body "Adds troubleshooting section and examples"
```

---

## Best Practices

### DO:
- ✅ **Write clear commit messages** (follow conventional commits)
- ✅ **Commit logical units** (one feature/fix per commit)
- ✅ **Run tests before committing** (ensure tests pass)
- ✅ **Review changes before staging** (`git diff`)
- ✅ **Keep commits focused** (don't mix unrelated changes)
- ✅ **Use descriptive branch names** (include prefix and description)
- ✅ **Create PRs from feature branches** (never commit directly to main)
- ✅ **Write PR descriptions** (explain what and why)
- ✅ **Squash WIP commits** (before or during merge)

### DON'T:
- ❌ **Include AI attribution** (no Claude, Anthropic references)
- ❌ **Write vague messages** ("fix bug", "update code")
- ❌ **Commit unrelated changes** (mix features/fixes)
- ❌ **Commit broken code** (tests must pass)
- ❌ **Force push to shared branches** (unless necessary)
- ❌ **Commit large binary files** (use Git LFS)
- ❌ **Commit secrets or credentials** (use .gitignore)
- ❌ **Skip PR reviews** (always get code reviewed)

---

### Commit Frequency

**When to commit**:
- ✅ After completing a logical unit of work
- ✅ After tests pass
- ✅ Before switching tasks
- ✅ At end of work session
- ✅ After fixing a bug
- ✅ After adding a feature

**Commit size**:
- **Too small**: Every line change separately
- **Too large**: Multiple features in one commit
- **Just right**: One logical change per commit

**Good examples**:
- One feature implementation
- One bug fix with test
- One refactoring
- Related tests for a feature

**Bad examples**:
- Half of a feature
- Multiple unrelated fixes
- Mixing features and refactoring
- WIP commits in main branch

---

## Fixing Mistakes

### Amend Last Commit (Not Pushed)

```bash
# Add forgotten files
git add forgotten-file.k
git commit --amend --no-edit

# Or change commit message
git commit --amend -m "new message"
```

**Warning**: Only amend commits that haven't been pushed!

### Unstage Files

```bash
# Unstage specific file
git restore --staged file.k

# Unstage all files
git restore --staged .
```

### Discard Local Changes

```bash
# Discard changes in specific file
git restore file.k

# Discard all local changes (DANGEROUS!)
git restore .
```

### Revert a Commit

```bash
# Create revert commit
git revert <commit-hash>

# Revert without committing (for manual fixes)
git revert -n <commit-hash>
```

### Undo Last Commit (Not Pushed)

```bash
# Keep changes, undo commit
git reset --soft HEAD~1

# Discard changes and commit (DANGEROUS!)
git reset --hard HEAD~1
```

---

## Git Hooks

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run tests before commit
up test run tests/test-*
if [ $? -ne 0 ]; then
  echo "Tests failed! Commit aborted."
  exit 1
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Commit-msg Hook

Create `.git/hooks/commit-msg`:

```bash
#!/bin/bash
# Validate commit message format
commit_msg=$(cat "$1")
if ! echo "$commit_msg" | grep -qE '^(feat|fix|docs|test|refactor|perf|style|chore|ci)(\(.+\))?: .+'; then
  echo "Error: Commit message doesn't follow conventional commits format"
  echo "Format: <type>(<scope>): <subject>"
  exit 1
fi
```

Make executable:
```bash
chmod +x .git/hooks/commit-msg
```

---

## Summary

**Key Points**:
- Follow conventional commits format
- Write clear, descriptive commit messages
- Never include AI attribution
- Use feature branches for all changes
- Create PRs with good descriptions
- Run tests before committing
- Review changes before staging
- Keep commits focused and atomic

**Commit Template**:
```
<type>(<scope>): <subject>

<body explaining what and why>

<footer with issue references>
```

**Workflow**:
1. Create feature branch
2. Make changes
3. Run tests
4. Commit with good message
5. Push to remote
6. Create PR
7. Get review
8. Merge

---

## See Also

- [TDD Strategy](TDD_STRATEGY.md) - Test-driven development workflow
- [Testing Overview](../testing/TESTING_OVERVIEW.md) - Testing strategy
- [GETTING_STARTED](../GETTING_STARTED.md) - First-time setup and workflow
- [Upbound Patterns](upbound-patterns.md) - Coding patterns and standards

---

**Remember**: Commits should be clear, professional, and focused on technical changes. Follow conventions consistently for maintainable project history.
