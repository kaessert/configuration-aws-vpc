# Git Operations Guide for Coding Agents

A practical guide to common git workflows for coding agents working on this project.

## 1. Making Commits

### Check Repository Status
```bash
# View current status - untracked files, modifications, staged changes
git status

# View short status (compact format)
git status -s
```

### Staging Files
```bash
# Stage specific files
git add path/to/file.js
git add path/to/another/file.py

# Stage all changes in current directory
git add .

# Stage all changes in repository
git add -A

# Stage only modified/deleted files (not new files)
git add -u

# Stage files interactively
git add -p
```

### Writing Good Commit Messages

#### Basic Commit
```bash
git commit -m "Add user authentication feature"
```

#### Multi-line Commit
```bash
git commit -m "$(cat <<'EOF'
Add user authentication feature

Implement JWT-based authentication with refresh tokens.
Add middleware for route protection.
Include tests for auth flows.
EOF
)"
```

### Conventional Commit Format

Use semantic prefixes for better changelog generation:

```bash
# Feature addition
git commit -m "feat: add user profile page"

# Bug fix
git commit -m "fix: resolve login timeout issue"

# Documentation
git commit -m "docs: update API documentation"

# Refactoring
git commit -m "refactor: simplify authentication logic"

# Tests
git commit -m "test: add unit tests for user service"

# Chores (dependencies, config, etc.)
git commit -m "chore: update dependencies"

# Performance improvements
git commit -m "perf: optimize database queries"

# Style changes (formatting, whitespace)
git commit -m "style: format code with prettier"
```

### Adding Co-Authors (Claude)

When Claude assists with code changes:

```bash
git commit -m "$(cat <<'EOF'
feat: implement dark mode toggle

Add theme context and toggle component.
Update styles to support dark theme.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### Best Practices
- Write commit messages in imperative mood ("add" not "added" or "adds")
- Keep first line under 50 characters
- Add detailed explanation in body if needed
- Reference issue numbers when applicable: "fixes #123"

## 2. Branch Management

### Creating Feature Branches
```bash
# Create and switch to new branch
git checkout -b feature/user-authentication

# Alternative with newer syntax
git switch -c feature/user-authentication

# Create branch from specific commit
git checkout -b hotfix/security-patch main
```

### Branch Naming Conventions
- `feature/description` - New features
- `fix/description` - Bug fixes
- `hotfix/description` - Urgent production fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation updates

### Switching Branches
```bash
# Switch to existing branch
git checkout main
git switch main

# Switch to previous branch
git checkout -
git switch -
```

### Checking Current Branch
```bash
# Show current branch
git branch --show-current

# List all local branches (* indicates current)
git branch

# List all branches (local and remote)
git branch -a

# List with last commit info
git branch -v
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

## 3. Creating Pull Requests

### Using gh CLI

#### Basic PR Creation
```bash
# Create PR interactively
gh pr create

# Create PR with title and body
gh pr create --title "Add user authentication" --body "Implements JWT-based auth system"

# Create PR using heredoc for formatted body
gh pr create --title "Add user authentication" --body "$(cat <<'EOF'
## Summary
- Implement JWT-based authentication
- Add user login and registration endpoints
- Include middleware for protected routes

## Test Plan
- Test user registration flow
- Test login with valid/invalid credentials
- Verify token refresh mechanism

Generated with Claude Code
EOF
)"
```

#### Advanced PR Options
```bash
# Create PR with reviewers
gh pr create --title "Fix login bug" --body "..." --reviewer username1,username2

# Create PR with labels
gh pr create --title "Update docs" --body "..." --label documentation,enhancement

# Create PR with assignees
gh pr create --title "Refactor auth" --body "..." --assignee @me

# Create PR for specific branch
gh pr create --base main --head feature/new-feature

# Create draft PR
gh pr create --draft --title "WIP: New feature"

# Create PR and auto-fill from commits
gh pr create --fill
```

### Linking Issues
```bash
# In PR body, use keywords to auto-close issues
gh pr create --body "$(cat <<'EOF'
Fixes #123
Closes #456
Resolves #789

This PR addresses the authentication issues.
EOF
)"
```

### Viewing PRs
```bash
# List open PRs
gh pr list

# View specific PR
gh pr view 123

# View PR in browser
gh pr view 123 --web

# Check PR status
gh pr status
```

## 4. Syncing with Remote

### Pulling Latest Changes
```bash
# Pull from current branch's upstream
git pull

# Pull from specific remote and branch
git pull origin main

# Pull with rebase (cleaner history)
git pull --rebase

# Pull and prune deleted remote branches
git pull --prune
```

### Pushing Branches
```bash
# Push current branch to remote
git push

# Push and set upstream tracking
git push -u origin feature/new-feature

# Push specific branch
git push origin feature/new-feature

# Push all branches
git push --all

# Push tags
git push --tags
```

### Fetching Updates
```bash
# Fetch from all remotes
git fetch

# Fetch from specific remote
git fetch origin

# Fetch and prune deleted branches
git fetch --prune

# Fetch all remotes and prune
git fetch --all --prune
```

### Handling Merge Conflicts Basics

When conflicts occur during pull/merge:

```bash
# 1. Identify conflicted files
git status

# 2. View conflicts in a file
cat path/to/conflicted/file.js
# Look for conflict markers:
# <<<<<<< HEAD
# Your changes
# =======
# Their changes
# >>>>>>> branch-name

# 3. Edit files to resolve conflicts manually

# 4. Stage resolved files
git add path/to/conflicted/file.js

# 5. Complete the merge
git commit  # For merge conflicts
git rebase --continue  # If in rebase

# Abort if needed
git merge --abort
git rebase --abort
```

## 5. Viewing History and Changes

### Git Log
```bash
# View commit history
git log

# Compact one-line format
git log --oneline

# View with graph
git log --oneline --graph --all

# Limit number of commits
git log -n 10

# View commits by author
git log --author="username"

# View commits in date range
git log --since="2024-01-01" --until="2024-12-31"

# View commits affecting specific file
git log -- path/to/file.js

# View commits with diff
git log -p

# View commits with stat summary
git log --stat

# Pretty format with author and date
git log --pretty=format:"%h - %an, %ar : %s"
```

### Git Diff
```bash
# View unstaged changes
git diff

# View staged changes
git diff --staged
git diff --cached

# View all changes (staged and unstaged)
git diff HEAD

# Compare two branches
git diff main..feature/new-feature

# Compare specific file between branches
git diff main feature/new-feature -- path/to/file.js

# View word-level diff
git diff --word-diff

# View diff stat summary
git diff --stat
```

### Git Show
```bash
# Show latest commit
git show

# Show specific commit
git show abc123

# Show specific file from commit
git show abc123:path/to/file.js

# Show commit with stat
git show --stat abc123

# Show only changed file names
git show --name-only abc123
```

### Finding Specific Commits
```bash
# Search commit messages
git log --grep="authentication"

# Search commit content
git log -S "function_name"

# Find when file was added
git log --diff-filter=A -- path/to/file.js

# Find who changed specific line
git blame path/to/file.js

# Find commit that introduced bug (binary search)
git bisect start
git bisect bad  # Current commit is bad
git bisect good abc123  # Known good commit
# Git will checkout commits to test
# Mark each as good/bad until found
git bisect reset  # When done
```

## 6. Undoing Changes

### Discarding Local Changes
```bash
# Discard changes in specific file (DESTRUCTIVE)
git checkout -- path/to/file.js
git restore path/to/file.js

# Discard all local changes (DESTRUCTIVE)
git checkout -- .
git restore .

# Remove untracked files (DESTRUCTIVE)
git clean -fd

# Preview what clean would remove
git clean -fd --dry-run
```

### Unstaging Files
```bash
# Unstage specific file
git reset HEAD path/to/file.js
git restore --staged path/to/file.js

# Unstage all files
git reset HEAD
git restore --staged .
```

### Amending Commits

**WARNING: Only amend commits that haven't been pushed, or you'll need to force push!**

```bash
# Amend last commit message
git commit --amend -m "New commit message"

# Amend last commit with new changes
git add forgotten-file.js
git commit --amend --no-edit

# Amend with new message and changes
git add forgotten-file.js
git commit --amend -m "Updated commit message"
```

**Safety Rules for Amending:**
- NEVER amend commits that have been pushed to shared branches
- ONLY amend commits that are local-only
- If you must amend a pushed commit, you'll need `git push --force-with-lease`
- Coordinate with team before force pushing

### Reverting Commits
```bash
# Revert specific commit (creates new commit)
git revert abc123

# Revert without auto-commit
git revert --no-commit abc123

# Revert range of commits
git revert abc123..def456

# Revert merge commit
git revert -m 1 abc123
```

### Resetting (Use with Caution)
```bash
# Soft reset - keep changes staged
git reset --soft HEAD~1

# Mixed reset (default) - keep changes unstaged
git reset HEAD~1
git reset --mixed HEAD~1

# Hard reset - discard all changes (DESTRUCTIVE)
git reset --hard HEAD~1

# Reset to specific commit
git reset --hard abc123
```

**WARNING: Hard reset is DESTRUCTIVE and cannot be undone easily!**

### Stashing Changes
```bash
# Stash current changes
git stash

# Stash with message
git stash save "Work in progress on feature X"

# List stashes
git stash list

# Apply most recent stash
git stash apply

# Apply and remove most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Drop specific stash
git stash drop stash@{2}

# Clear all stashes
git stash clear
```

## Common Workflows

### Standard Feature Development
```bash
# 1. Start from main
git checkout main
git pull

# 2. Create feature branch
git checkout -b feature/new-feature

# 3. Make changes and commit
git add .
git commit -m "feat: implement new feature"

# 4. Push branch
git push -u origin feature/new-feature

# 5. Create PR
gh pr create --fill

# 6. After PR merged, clean up
git checkout main
git pull
git branch -d feature/new-feature
```

### Quick Bug Fix
```bash
# 1. Create hotfix branch from main
git checkout main
git pull
git checkout -b hotfix/critical-bug

# 2. Fix and commit
git add .
git commit -m "fix: resolve critical authentication bug"

# 3. Push and create PR
git push -u origin hotfix/critical-bug
gh pr create --title "Fix critical auth bug" --label bug,priority:high

# 4. After merge, delete branch
git checkout main
git pull
git branch -d hotfix/critical-bug
```

### Syncing Feature Branch with Main
```bash
# Option 1: Merge main into feature
git checkout feature/my-feature
git merge main

# Option 2: Rebase feature on main (cleaner history)
git checkout feature/my-feature
git rebase main
```

## Safety Reminders

1. **Never force push to main/master** unless absolutely necessary and coordinated
2. **Always pull before pushing** to avoid conflicts
3. **Don't amend or rebase pushed commits** on shared branches
4. **Use `--force-with-lease`** instead of `--force` if you must force push
5. **Commit frequently** with meaningful messages
6. **Review changes before committing** with `git diff` and `git status`
7. **Use branches** for all work, never commit directly to main
8. **Test before pushing** to ensure code works

## Quick Reference

```bash
# Status and info
git status                    # Check status
git log --oneline -n 10      # Recent commits
git branch -v                 # List branches

# Common operations
git add .                     # Stage all
git commit -m "message"       # Commit
git push                      # Push to remote
git pull                      # Pull from remote

# Branch operations
git checkout -b branch-name   # Create and switch
git checkout branch-name      # Switch branch
git branch -d branch-name     # Delete branch

# Undoing
git restore file              # Discard changes
git restore --staged file     # Unstage
git revert commit-hash        # Revert commit

# Viewing
git diff                      # View changes
git diff --staged             # View staged
git show commit-hash          # Show commit
```

---

**Remember:** Git is powerful but potentially destructive. When in doubt, create a backup branch or stash your changes before performing risky operations.
