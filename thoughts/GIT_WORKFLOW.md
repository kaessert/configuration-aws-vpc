# Git Workflow Guide

A comprehensive guide to git workflows and commit conventions for the AWS VPC Configuration for Upbound project. For command syntax reference, see [git-reference.md](git-reference.md).

---

## Table of Contents

1. [Commit Message Conventions](#1-commit-message-conventions)
2. [Branch Strategy](#2-branch-strategy)
3. [Making Commits](#3-making-commits)
4. [Creating Pull Requests](#4-creating-pull-requests)
5. [Standard Workflows](#5-standard-workflows)
6. [Best Practices](#6-best-practices)
7. [Git Hooks](#7-git-hooks)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Commit Message Conventions

### CRITICAL: What NOT to Include

**NEVER mention these in commit messages**:
- ❌ "Claude" or "Claude Code"
- ❌ "Anthropic"
- ❌ "Generated with Claude Code"
- ❌ "Co-Authored-By: Claude Sonnet"
- ❌ Any AI attribution or generation references

**Reason**: Commits should appear as human-authored without AI tooling references.

---

### Conventional Commits Format

Follow **Conventional Commits** specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type (Required)

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

#### Scope (Optional)

Scope indicates which module is affected:
- `vpc` - VPC-related changes
- `subnets` - Subnet logic
- `gateways` - IGW, NAT Gateway
- `routes` - Routing logic
- `endpoints` - VPC Endpoints
- `tests` - Testing infrastructure
- `workflows` - CI/CD workflows

#### Subject Line Rules

- ✅ Use imperative mood ("add" not "added" or "adds")
- ✅ Don't capitalize first letter
- ✅ No period at the end
- ✅ Keep under 50 characters
- ✅ Be specific and descriptive

**Good examples**:
```
feat(vpc): add secondary CIDR support
fix(nat): resolve EIP allocation issue
test: add composition tests for routing
```

**Bad examples**:
```
❌ feat: Update files (too vague)
❌ Added VPC support. (wrong tense, capitalized, has period)
❌ WIP (not descriptive)
```

#### Body (Optional but Recommended)

- Wrap at 72 characters
- Explain **what** and **why**, not how
- Separate from subject with blank line
- Use bullet points for multiple items

#### Footer (Optional)

- Reference issues: `Closes #123` or `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`

---

### Example Commit Messages

#### Good Examples

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

#### Bad Examples

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

## 2. Branch Strategy

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

### Branch Lifecycle

```
main (protected)
├── feature/vpc-endpoints  → PR → merge → delete
├── fix/subnet-bug         → PR → merge → delete
└── test/add-e2e-tests     → PR → merge → delete
```

### Branch Protection

- `main` - Protected, requires PR and reviews
- Never commit directly to `main`
- Always work in feature branches
- Delete branches after merge

---

## 3. Making Commits

### Pre-Commit Checklist

1. **Review changes**: `git diff` and `git diff --staged`
2. **Run tests**: Ensure all tests pass
3. **Stage relevant files**: `git add <files>`
4. **Write clear message**: Follow conventions above
5. **Verify staging**: `git status`

### Commit Commands

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

# View commit in log
git log --oneline -1

# Amend if needed (only if not pushed!)
git commit --amend

# Push to remote
git push origin <branch-name>
```

### Amending Commits

**Only amend commits that haven't been pushed!**

```bash
# Add forgotten files
git add forgotten-file.k
git commit --amend --no-edit

# Or change commit message
git commit --amend -m "new message"
```

---

## 4. Creating Pull Requests

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

# Auto-fill from commits
gh pr create --fill
```

### PR Template Format

Use this structure for PR bodies:

```markdown
## Summary
- Brief overview of changes
- List key features or fixes
- Mention related work

## Test Plan
- [ ] Composition tests pass
- [ ] E2E tests pass (if applicable)
- [ ] Manual testing completed
- [ ] No regressions

## Related Issues
Closes #123
Fixes #456

## Breaking Changes
(if applicable)

## Screenshots
(if applicable)
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

## 5. Standard Workflows

### Workflow 1: Feature Development

```bash
# 1. Start from main
git checkout main
git pull

# 2. Create feature branch
git checkout -b feature/vpc-endpoints

# 3. Make changes and commit frequently
git add functions/vpc/endpoints.k
git commit -m "feat(endpoints): add VPC endpoint support"

# 4. Run tests
up test run tests/test-xvpc-endpoints

# 5. Push to remote
git push -u origin feature/vpc-endpoints

# 6. Create PR
gh pr create --title "feat(endpoints): add VPC endpoint support" \
  --body "Implements VPC endpoints for S3, DynamoDB, and other services"

# 7. After approval and merge, clean up
git checkout main
git pull
git branch -d feature/vpc-endpoints
```

---

### Workflow 2: Bug Fix

```bash
# 1. Create fix branch from main
git checkout main
git pull
git checkout -b fix/subnet-cidr

# 2. Fix bug and commit
git add functions/vpc/subnet.k
git commit -m "fix(subnet): correct CIDR block calculation for private subnets"

# 3. Run tests to verify fix
up test run tests/test-xvpc-subnets-private

# 4. Push and create PR
git push -u origin fix/subnet-cidr
gh pr create --title "fix(subnet): correct CIDR calculation" \
  --body "Fixes #78"

# 5. After merge, clean up
git checkout main
git pull
git branch -d fix/subnet-cidr
```

---

### Workflow 3: Adding Tests (TDD Workflow)

This workflow follows the mandatory TDD approach: 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT

```bash
# 1. Create test branch
git checkout -b test/add-e2e-vpc-basic

# 2. 🔴 RED - Write composition test FIRST
up test generate test-xvpc-basic --language=kcl
# Edit tests/test-xvpc-basic/main.k
# Write assertions for expected behavior

# Run test - MUST FAIL
up test run tests/test-xvpc-basic
# ❌ Expected: Test fails (feature not implemented)

# 3. 🟢 GREEN - Implement minimum code to pass test
# Edit functions/vpc/main.k
# Implement feature

# Run test until it passes
up test run tests/test-xvpc-basic
# ✅ Expected: Test passes

# Run ALL tests to check for regressions
up test run tests/test-*
# ✅ Expected: All tests pass

# 4. 🔵 REFACTOR - Improve code quality
# Refactor for clarity/modularity
# Keep tests passing during refactoring

# 5. 🧪 E2E - Write and run E2E test (MANDATORY)
up test generate e2etest-xvpc-basic --e2e --language=kcl
# Edit tests/e2etest-xvpc-basic/main.k
# Configure ProviderConfig with IAM role
# Set timeout: 1800 seconds (30 minutes)
# Set skipDelete: false (ensure cleanup)

# Run E2E test
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing
# ✅ Expected: Test passes, resources created and cleaned up

# 6. ✅ COMMIT - Only when ALL tests pass
# Final checks
up project build              # ✅ MUST pass
up test run tests/test-*      # ✅ ALL composition tests MUST pass
up test run tests/e2etest-* --e2e --control-plane-group=claude-testing  # ✅ E2E test MUST pass

# Commit with descriptive message
git add tests/test-xvpc-basic/ tests/e2etest-xvpc-basic/ functions/vpc/
git commit -m "$(cat <<'EOF'
test: add composition and E2E tests for basic VPC

- Add composition test for basic VPC creation
- Implement basic VPC feature in functions/vpc/main.k
- Add E2E test validating real AWS VPC behavior
- All tests passing (composition + E2E)
- E2E test verified resource creation and cleanup
EOF
)"

# 7. Push and create PR
git push -u origin test/add-e2e-vpc-basic
gh pr create --title "test: add E2E test for basic VPC" \
  --body "Adds composition and E2E tests for Task 0.1" \
  --label "run-e2e-tests"

# 8. After merge, clean up
git checkout main
git pull
git branch -d test/add-e2e-vpc-basic
```

**CRITICAL**: Never commit if ANY test fails (composition OR E2E). Fix tests first.

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
git push -u origin docs/update-testing-guide
gh pr create --title "docs: improve E2E testing guide" \
  --body "Adds troubleshooting section and examples"

# 5. After merge, clean up
git checkout main
git pull
git branch -d docs/update-testing-guide
```

---

### Workflow 5: Syncing Feature Branch with Main

When your feature branch is behind main:

**Option 1: Merge main into feature (preserves history)**
```bash
git checkout feature/my-feature
git merge main
# Resolve conflicts if any
git push
```

**Option 2: Rebase feature on main (cleaner history)**
```bash
git checkout feature/my-feature
git rebase main
# Resolve conflicts if any
git push --force-with-lease
```

**When to use each**:
- Use **merge** if branch is already pushed and others may be working on it
- Use **rebase** for personal feature branches to keep history linear
- Never rebase shared branches or commits that have been pushed to PRs

---

## 6. Best Practices

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
- ✅ **Delete branches after merge** (keep repository clean)
- ✅ **Pull before push** (avoid conflicts)
- ✅ **Follow TDD workflow** (🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT)

### DON'T:

- ❌ **Include AI attribution** (no Claude, Anthropic references)
- ❌ **Write vague messages** ("fix bug", "update code")
- ❌ **Commit unrelated changes** (mix features/fixes)
- ❌ **Commit broken code** (tests must pass)
- ❌ **Force push to shared branches** (unless necessary and coordinated)
- ❌ **Commit large binary files** (use Git LFS)
- ❌ **Commit secrets or credentials** (use .gitignore)
- ❌ **Skip PR reviews** (always get code reviewed)
- ❌ **Amend pushed commits** (on shared branches)
- ❌ **Commit directly to main** (always use PRs)
- ❌ **Skip E2E tests** (they are MANDATORY for features)

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

### Code Review Checklist

Before requesting review:
- [ ] All tests pass (composition + E2E)
- [ ] Code follows project patterns
- [ ] Documentation updated (if needed)
- [ ] Commit messages follow conventions
- [ ] No debugging code or comments
- [ ] No secrets or credentials
- [ ] Branch is up to date with main

When reviewing:
- [ ] Code is clear and maintainable
- [ ] Tests adequately cover changes
- [ ] No regressions introduced
- [ ] Documentation is accurate
- [ ] Commit history is clean
- [ ] No security issues

---

## 7. Git Hooks

Git hooks automate checks before commits and pushes.

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run composition tests before commit

echo "Running composition tests..."
up test run tests/test-*

if [ $? -ne 0 ]; then
  echo "❌ Composition tests failed! Commit aborted."
  echo "Fix tests before committing."
  exit 1
fi

echo "✅ All tests passed!"
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

# Check conventional commits format
if ! echo "$commit_msg" | grep -qE '^(feat|fix|docs|test|refactor|perf|style|chore|ci)(\(.+\))?: .+'; then
  echo "❌ Error: Commit message doesn't follow conventional commits format"
  echo ""
  echo "Format: <type>(<scope>): <subject>"
  echo ""
  echo "Types: feat, fix, docs, test, refactor, perf, style, chore, ci"
  echo "Example: feat(vpc): add DNS support"
  exit 1
fi

# Check for AI attribution (FORBIDDEN)
if echo "$commit_msg" | grep -qiE '(claude|anthropic|generated with|co-authored-by.*claude)'; then
  echo "❌ Error: Commit message contains AI attribution"
  echo ""
  echo "NEVER include references to:"
  echo "  - Claude or Claude Code"
  echo "  - Anthropic"
  echo "  - AI generation or assistance"
  echo ""
  echo "Commits should appear as human-authored."
  exit 1
fi

echo "✅ Commit message format valid"
```

Make executable:
```bash
chmod +x .git/hooks/commit-msg
```

### Pre-push Hook

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
# Run all tests before push

echo "Running all tests before push..."

# Run composition tests
echo "Running composition tests..."
up test run tests/test-*
if [ $? -ne 0 ]; then
  echo "❌ Composition tests failed! Push aborted."
  exit 1
fi

# Check if branch has E2E tests
if ls tests/e2etest-* 1> /dev/null 2>&1; then
  echo "⚠️  E2E tests found. Make sure they pass before merging!"
  echo "Run: up test run tests/e2etest-* --e2e --control-plane-group=claude-testing"
fi

# Check if pushing to protected branch
protected_branch='main'
current_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [ $protected_branch = $current_branch ]; then
  read -p "You're about to push to main. Are you sure? [y|n] " -n 1 -r < /dev/tty
  echo
  if echo $REPLY | grep -E '^[Yy]$' > /dev/null
  then
    exit 0 # push will execute
  fi
  exit 1 # push will not execute
fi

echo "✅ All checks passed!"
```

Make executable:
```bash
chmod +x .git/hooks/pre-push
```

### Installing Hooks

```bash
# Copy hooks to .git/hooks/ directory
cp scripts/git-hooks/* .git/hooks/
chmod +x .git/hooks/*
```

**Note**: Git hooks are local and not committed to the repository. Each developer must set them up individually.

---

## 8. Troubleshooting

### Common Issues

#### Issue: Merge Conflicts

**Symptom**: Git reports conflicts during merge/pull/rebase

**Solution**:
```bash
# 1. View conflicted files
git status

# 2. Open files and resolve conflicts
# Look for conflict markers: <<<<<<<, =======, >>>>>>>

# 3. Stage resolved files
git add resolved-file.k

# 4. Complete merge
git commit  # for merge
git rebase --continue  # for rebase

# If you want to abort
git merge --abort
git rebase --abort
```

---

#### Issue: Accidentally Committed to Wrong Branch

**Solution**:
```bash
# If not pushed yet:
# 1. Create correct branch from current commit
git branch correct-branch

# 2. Reset wrong branch
git reset --hard HEAD~1

# 3. Switch to correct branch
git checkout correct-branch
```

---

#### Issue: Need to Undo Last Commit

**Solution**:
```bash
# Keep changes, undo commit (most common)
git reset --soft HEAD~1

# Keep changes unstaged
git reset --mixed HEAD~1
git reset HEAD~1

# Discard changes completely (DANGEROUS)
git reset --hard HEAD~1
```

---

#### Issue: Pushed Sensitive Data (Credentials)

**Solution**:
```bash
# 1. Remove file and commit
git rm --cached sensitive-file
git commit -m "remove sensitive file"

# 2. Rewrite history (if recent)
git reset --hard HEAD~2  # Go back before sensitive commit
git push --force-with-lease

# 3. Rotate credentials immediately!
# 4. Consider using git-filter-repo for older commits
```

**Better**: Prevent with `.gitignore` and pre-commit hooks

---

#### Issue: Need to Edit Multiple Old Commits

**Solution**:
```bash
# Interactive rebase
git rebase -i HEAD~5  # Edit last 5 commits

# In editor:
# - Change 'pick' to 'edit' for commits to modify
# - Change 'pick' to 'squash' to combine commits
# - Save and close

# For each commit marked 'edit':
git commit --amend  # Make changes
git rebase --continue  # Move to next

# Force push if already pushed (DANGEROUS on shared branches)
git push --force-with-lease
```

---

#### Issue: Lost Commits After Reset

**Solution**:
```bash
# View reflog (history of HEAD)
git reflog

# Find lost commit hash
# Recover commit
git checkout <commit-hash>
git branch recovered-branch

# Or reset to that point
git reset --hard <commit-hash>
```

---

#### Issue: Diverged Branch (Push Rejected)

**Symptom**: `! [rejected] main -> main (non-fast-forward)`

**Solution**:
```bash
# Option 1: Pull and merge (creates merge commit)
git pull origin main

# Option 2: Pull and rebase (linear history)
git pull --rebase origin main

# Option 3: Force push (DANGEROUS - only for personal branches)
git push --force-with-lease
```

---

#### Issue: Detached HEAD State

**Symptom**: `HEAD detached at <commit>`

**Solution**:
```bash
# If you made commits you want to keep:
git branch new-branch-name
git checkout new-branch-name

# If you don't want changes:
git checkout main
```

---

#### Issue: Too Many WIP Commits

**Solution**:
```bash
# Squash last N commits
git rebase -i HEAD~N

# In editor, change 'pick' to 'squash' for commits to combine
# Save and write new commit message

# If already pushed
git push --force-with-lease
```

---

#### Issue: Need to Undo Merge

**Solution**:
```bash
# If merge not committed yet
git merge --abort

# If merge committed but not pushed
git reset --hard HEAD~1

# If merge committed and pushed
git revert -m 1 <merge-commit-hash>
```

---

#### Issue: Wrong Commit Message

**Solution**:
```bash
# If not pushed yet
git commit --amend -m "correct message"

# If already pushed (avoid if possible)
git commit --amend -m "correct message"
git push --force-with-lease
```

---

### Recovery Commands

**Undo almost anything**:
```bash
# View reflog
git reflog

# Find the commit you want
# Reset to that commit
git reset --hard HEAD@{N}
```

**Create backup before risky operations**:
```bash
git branch backup-before-rebase
git rebase main
# If something goes wrong:
git checkout backup-before-rebase
```

---

## Summary

### Key Principles

1. **Follow Conventional Commits** - Type, scope, clear subject
2. **Never Include AI Attribution** - Commits should appear human-authored
3. **Use Feature Branches** - Never commit directly to main
4. **Write Clear Messages** - Explain what and why
5. **Run Tests Before Commit** - Ensure nothing breaks
6. **Keep Commits Atomic** - One logical change per commit
7. **Review Before Staging** - Know what you're committing
8. **Create Good PRs** - Clear title, description, test plan
9. **Follow TDD Workflow** - 🔴 RED → 🟢 GREEN → 🔵 REFACTOR → 🧪 E2E → ✅ COMMIT
10. **Clean Up After Merge** - Delete merged branches

### Essential Commands

```bash
# Daily workflow
git status                           # Check status
git add .                            # Stage changes
git commit -m "type(scope): subject" # Commit
git push                             # Push to remote

# Branch management
git checkout -b feature/name         # Create branch
git checkout main                    # Switch to main
git pull                             # Update from remote
git branch -d feature/name           # Delete merged branch

# Testing
up test run tests/test-*             # Run composition tests
up test run tests/e2etest-* --e2e    # Run E2E tests

# PR creation
gh pr create --title "..." --body "..." # Create PR
```

### Commit Message Template

```
<type>(<scope>): <subject>

<body explaining what and why>

<footer with issue references>
```

### Workflow Summary

1. Create feature branch
2. 🔴 Write composition test FIRST (must fail)
3. 🟢 Implement feature (make test pass)
4. 🔵 Refactor code (keep tests passing)
5. 🧪 Add E2E test (MANDATORY)
6. ✅ Commit when all tests pass
7. Push to remote
8. Create PR with clear description
9. Get review and address feedback
10. Merge and delete branch

---

## See Also

- [git-reference.md](git-reference.md) - Command syntax reference
- [TDD Strategy](../TDD_STRATEGY.md) - Test-driven development workflow
- [Testing Overview](../testing/TESTING_OVERVIEW.md) - Testing strategy
- [GETTING_STARTED](../GETTING_STARTED.md) - First-time setup
- [Upbound Patterns](../coding/upbound-patterns.md) - Coding standards

---

**Remember**: Commits should be clear, professional, and focused on technical changes. Follow conventions consistently for maintainable project history. **NEVER** include AI attribution - commits must appear human-authored.
