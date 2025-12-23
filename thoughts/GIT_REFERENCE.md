# Git Command Reference

A comprehensive command reference for git operations. This is a pure command syntax guide - for workflows and conventions, see [GIT_WORKFLOW.md](GIT_WORKFLOW.md).

---

## Table of Contents

1. [Status and Information](#status-and-information)
2. [Staging and Committing](#staging-and-committing)
3. [Branches](#branches)
4. [History and Changes](#history-and-changes)
5. [Remote Sync](#remote-sync)
6. [Undoing Changes](#undoing-changes)
7. [Conflict Resolution](#conflict-resolution)
8. [Stashing](#stashing)
9. [Advanced Operations](#advanced-operations)
10. [Quick Reference](#quick-reference)

---

## Status and Information

### Check Repository Status

```bash
# View current status - untracked files, modifications, staged changes
git status

# View short status (compact format)
git status -s

# Show current branch
git branch --show-current
```

### View Configuration

```bash
# List all configuration
git config --list

# View specific config
git config user.name
git config user.email

# View remote URLs
git remote -v
```

### Repository Information

```bash
# Show commit count
git rev-list --count HEAD

# Show repository root
git rev-parse --show-toplevel

# Check if inside git repository
git rev-parse --is-inside-work-tree
```

---

## Staging and Committing

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

# Stage files interactively (choose hunks)
git add -p

# Stage by pattern
git add '*.js'
```

### Committing

```bash
# Basic commit
git commit -m "commit message"

# Commit with multi-line message
git commit -m "title" -m "body"

# Commit using heredoc (recommended for complex commits)
git commit -m "$(cat <<'EOF'
title line

body paragraph with multiple lines
explaining the changes

footer with references
EOF
)"

# Commit all tracked changes (skip staging)
git commit -a -m "commit message"

# Empty commit (for triggering CI)
git commit --allow-empty -m "trigger CI"

# Amend commits: See "Undoing Changes → Amending Commits" section
```

---

## Branches

### Creating Branches

```bash
# Create and switch to new branch
git checkout -b branch-name

# Alternative with newer syntax
git switch -c branch-name

# Create branch from specific commit
git checkout -b branch-name commit-hash

# Create branch from specific branch
git checkout -b new-branch existing-branch
```

### Switching Branches

```bash
# Switch to existing branch
git checkout branch-name
git switch branch-name

# Switch to previous branch
git checkout -
git switch -

# Switch and create if doesn't exist
git switch -C branch-name
```

### Viewing Branches

```bash
# List all local branches (* indicates current)
git branch

# List all branches (local and remote)
git branch -a

# List only remote branches
git branch -r

# List with last commit info
git branch -v

# List with more commit info
git branch -vv

# List merged branches
git branch --merged

# List unmerged branches
git branch --no-merged
```

### Deleting Branches

```bash
# Delete local branch (safe - prevents deletion if unmerged)
git branch -d branch-name

# Force delete local branch
git branch -D branch-name

# Delete remote branch
git push origin --delete branch-name

# Alternative syntax for deleting remote branch
git push origin :branch-name

# Prune deleted remote branches from local
git fetch --prune
git fetch -p
```

### Renaming Branches

```bash
# Rename current branch
git branch -m new-name

# Rename specific branch
git branch -m old-name new-name
```

---

## History and Changes

### Git Log

```bash
# View commit history
git log

# Compact one-line format
git log --oneline

# View with graph
git log --oneline --graph --all

# View graph with decorations
git log --oneline --graph --decorate --all

# Limit number of commits
git log -n 10
git log -10

# View commits by author
git log --author="username"
git log --author="email@example.com"

# View commits in date range
git log --since="2024-01-01" --until="2024-12-31"
git log --since="2 weeks ago"
git log --after="2024-01-01" --before="2024-12-31"

# View commits affecting specific file
git log -- path/to/file.js

# View commits with diff
git log -p

# View commits with stat summary
git log --stat

# View commits with short stat
git log --shortstat

# Pretty format with author and date
git log --pretty=format:"%h - %an, %ar : %s"

# Custom pretty format
git log --pretty=format:"%h %ad | %s%d [%an]" --date=short

# View merge commits only
git log --merges

# View non-merge commits only
git log --no-merges

# Show commits in reverse order
git log --reverse

# Show first-parent only (mainline history)
git log --first-parent
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
git diff branch1..branch2
git diff branch1...branch2  # since common ancestor

# Compare specific file between branches
git diff branch1 branch2 -- path/to/file.js

# Compare with specific commit
git diff commit-hash

# View word-level diff
git diff --word-diff

# View diff stat summary
git diff --stat

# View compact stat
git diff --shortstat

# View only changed file names
git diff --name-only

# View changed files with status
git diff --name-status

# Ignore whitespace changes
git diff -w
git diff --ignore-all-space

# Ignore whitespace at line end
git diff --ignore-space-at-eol

# View diff between working directory and specific commit
git diff commit-hash -- path/to/file
```

### Git Show

```bash
# Show latest commit
git show

# Show specific commit
git show commit-hash

# Show specific file from commit
git show commit-hash:path/to/file.js

# Show commit with stat
git show --stat commit-hash

# Show only changed file names
git show --name-only commit-hash

# Show changed files with status
git show --name-status commit-hash

# Show specific file at HEAD
git show HEAD:path/to/file

# Show file from different branch
git show branch-name:path/to/file
```

### Finding Commits

```bash
# Search commit messages
git log --grep="search term"

# Search commit messages (case insensitive)
git log --grep="search term" -i

# Search commit content (pickaxe)
git log -S "function_name"

# Search commit content with regex
git log -G "regex pattern"

# Find when file was added
git log --diff-filter=A -- path/to/file.js

# Find when file was deleted
git log --diff-filter=D -- path/to/file.js

# Find when file was modified
git log --diff-filter=M -- path/to/file.js

# Find who changed specific line (blame)
git blame path/to/file.js

# Blame with line range
git blame -L 10,20 path/to/file.js

# Blame ignoring whitespace
git blame -w path/to/file.js
```

### Git Bisect (Binary Search for Bugs)

```bash
# Start bisect session
git bisect start

# Mark current commit as bad
git bisect bad

# Mark known good commit
git bisect good commit-hash

# Git checks out a commit to test
# Test the commit, then mark as good or bad
git bisect good    # if this commit is good
git bisect bad     # if this commit is bad

# Git continues binary search
# Repeat until bug commit is found

# End bisect session
git bisect reset

# Automate bisect with script
git bisect run ./test-script.sh
```

---

## Remote Sync

### Cloning

```bash
# Clone repository
git clone https://github.com/user/repo.git

# Clone to specific directory
git clone https://github.com/user/repo.git my-directory

# Clone specific branch
git clone -b branch-name https://github.com/user/repo.git

# Clone with depth (shallow clone)
git clone --depth 1 https://github.com/user/repo.git

# Clone without history (single branch)
git clone --single-branch https://github.com/user/repo.git
```

### Remote Management

```bash
# List remotes
git remote

# List remotes with URLs
git remote -v

# Add remote
git remote add remote-name https://github.com/user/repo.git

# Remove remote
git remote remove remote-name
git remote rm remote-name

# Rename remote
git remote rename old-name new-name

# Change remote URL
git remote set-url remote-name https://new-url.git

# Show remote info
git remote show origin
```

### Fetching

```bash
# Fetch from all remotes
git fetch

# Fetch from specific remote
git fetch origin

# Fetch and prune deleted branches
git fetch --prune
git fetch -p

# Fetch all remotes and prune
git fetch --all --prune

# Fetch specific branch
git fetch origin branch-name

# Fetch tags
git fetch --tags
```

### Pulling

```bash
# Pull from current branch's upstream
git pull

# Pull from specific remote and branch
git pull origin main

# Pull with rebase (cleaner history)
git pull --rebase

# Pull and prune deleted remote branches
git pull --prune

# Pull all submodules
git pull --recurse-submodules

# Pull without committing merge
git pull --no-commit
```

### Pushing

```bash
# Push current branch to remote
git push

# Push and set upstream tracking
git push -u origin branch-name
git push --set-upstream origin branch-name

# Push specific branch
git push origin branch-name

# Push all branches
git push --all

# Push tags
git push --tags

# Push specific tag
git push origin tag-name

# Delete remote branch
git push origin --delete branch-name

# Delete remote tag
git push origin --delete tag-name

# Force push (DANGEROUS - overwrites remote history)
git push --force

# Force push with lease (safer - fails if remote has new commits)
git push --force-with-lease

# Dry run (show what would be pushed)
git push --dry-run
```

**WARNING**: Never force push to shared branches (main/master) unless absolutely necessary and coordinated with team!

---

## Undoing Changes

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
git clean -fdn

# Remove untracked files and ignored files (VERY DESTRUCTIVE)
git clean -fdx

# Interactive clean
git clean -fdi
```

**WARNING**: These operations are DESTRUCTIVE and cannot be undone!

### Unstaging Files

```bash
# Unstage specific file
git reset HEAD path/to/file.js
git restore --staged path/to/file.js

# Unstage all files
git reset HEAD
git restore --staged .
```

### Reverting Commits

```bash
# Revert specific commit (creates new commit)
git revert commit-hash

# Revert without auto-commit
git revert --no-commit commit-hash
git revert -n commit-hash

# Revert range of commits
git revert commit1..commit2

# Revert merge commit (specify parent)
git revert -m 1 commit-hash

# Continue revert after resolving conflicts
git revert --continue

# Abort revert
git revert --abort
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
git reset --hard commit-hash

# Reset specific file
git reset HEAD -- path/to/file.js

# Reset to origin/main (discard all local commits)
git reset --hard origin/main
```

**WARNING**: Hard reset is DESTRUCTIVE and cannot be undone easily! Use with extreme caution.

**Safety tip**: Create a backup branch before resetting:
```bash
git branch backup-branch
git reset --hard commit-hash
```

### Amending Commits

```bash
# Amend last commit message
git commit --amend -m "New commit message"

# Amend last commit with new changes
git add forgotten-file.js
git commit --amend --no-edit

# Amend with new message and changes
git add forgotten-file.js
git commit --amend -m "Updated commit message"

# Amend author
git commit --amend --author="Name <email@example.com>"

# Amend date
git commit --amend --date="2024-01-01 12:00:00"
```

**WARNING**: Only amend commits that haven't been pushed, or you'll need to force push!

---

## Conflict Resolution

### During Merge/Rebase

```bash
# 1. Identify conflicted files
git status

# 2. View conflicts
# Files will contain conflict markers:
# <<<<<<< HEAD
# Your changes
# =======
# Their changes
# >>>>>>> branch-name

# 3. Choose conflict resolution strategy
# Edit files manually, or use:

# Accept theirs
git checkout --theirs path/to/file

# Accept ours
git checkout --ours path/to/file

# 4. After resolving, stage files
git add path/to/resolved-file

# 5. Complete the merge
git commit  # For merge conflicts
git rebase --continue  # If in rebase

# Abort merge/rebase
git merge --abort
git rebase --abort

# Skip current patch in rebase
git rebase --skip
```

### Merge Tools

```bash
# Launch configured merge tool
git mergetool

# Use specific merge tool
git mergetool --tool=vimdiff
git mergetool --tool=meld

# Configure default merge tool
git config --global merge.tool vimdiff
```

---

## Stashing

### Basic Stashing

```bash
# Stash current changes
git stash

# Stash with message
git stash save "Work in progress on feature X"
git stash push -m "Work in progress on feature X"

# Stash including untracked files
git stash -u
git stash --include-untracked

# Stash all files (including ignored)
git stash -a
git stash --all
```

### Viewing Stashes

```bash
# List stashes
git stash list

# Show stash contents
git stash show

# Show stash diff
git stash show -p
git stash show stash@{0} -p

# Show specific stash
git stash show stash@{2}
```

### Applying Stashes

```bash
# Apply most recent stash
git stash apply

# Apply and remove most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Pop specific stash
git stash pop stash@{2}

# Apply stash to new branch
git stash branch branch-name
git stash branch branch-name stash@{1}
```

### Managing Stashes

```bash
# Drop specific stash
git stash drop stash@{2}

# Drop most recent stash
git stash drop

# Clear all stashes
git stash clear

# Create stash without removing changes
git stash create
```

---

## Advanced Operations

### Rebasing

```bash
# Rebase current branch onto another
git rebase branch-name

# Interactive rebase (squash, reorder, edit commits)
git rebase -i HEAD~N

# Rebase onto specific commit
git rebase commit-hash

# Continue rebase after resolving conflicts
git rebase --continue

# Skip current commit in rebase
git rebase --skip

# Abort rebase
git rebase --abort

# Preserve merge commits
git rebase --preserve-merges

# Rebase and sign commits
git rebase --gpg-sign
```

**WARNING**: Never rebase commits that have been pushed to shared branches!

### Cherry-picking

```bash
# Apply specific commit to current branch
git cherry-pick commit-hash

# Cherry-pick multiple commits
git cherry-pick commit1 commit2 commit3

# Cherry-pick range
git cherry-pick commit1..commit2

# Cherry-pick without committing
git cherry-pick -n commit-hash
git cherry-pick --no-commit commit-hash

# Continue after resolving conflicts
git cherry-pick --continue

# Abort cherry-pick
git cherry-pick --abort
```

### Tagging

```bash
# Create lightweight tag
git tag tag-name

# Create annotated tag
git tag -a tag-name -m "tag message"

# Tag specific commit
git tag tag-name commit-hash

# List tags
git tag
git tag -l
git tag --list

# List tags matching pattern
git tag -l "v1.*"

# Show tag info
git show tag-name

# Delete local tag
git tag -d tag-name

# Delete remote tag
git push origin --delete tag-name
git push origin :refs/tags/tag-name

# Push tag to remote
git push origin tag-name

# Push all tags
git push --tags
```

### Submodules

```bash
# Add submodule
git submodule add https://github.com/user/repo.git path/to/submodule

# Initialize submodules
git submodule init

# Update submodules
git submodule update

# Clone with submodules
git clone --recurse-submodules https://github.com/user/repo.git

# Update submodules to latest
git submodule update --remote

# Run command in all submodules
git submodule foreach 'git pull'

# Remove submodule
git submodule deinit path/to/submodule
git rm path/to/submodule
rm -rf .git/modules/path/to/submodule
```

### Reflog (Recovery)

```bash
# View reflog (history of HEAD)
git reflog

# View reflog for specific branch
git reflog show branch-name

# Recover lost commit
git checkout commit-hash
git branch recovered-branch

# Undo reset using reflog
git reset --hard HEAD@{1}

# View reflog with dates
git reflog --date=iso
```

### Worktrees

```bash
# Create new worktree
git worktree add path/to/worktree branch-name

# List worktrees
git worktree list

# Remove worktree
git worktree remove path/to/worktree

# Prune deleted worktrees
git worktree prune
```

---

## Quick Reference

### Most Common Commands

```bash
# Status and info
git status                    # Check status
git log --oneline -n 10      # Recent commits
git branch -v                 # List branches
git diff                      # View changes

# Staging and committing
git add .                     # Stage all
git commit -m "message"       # Commit
git commit --amend            # Amend last commit

# Branches
git checkout -b branch-name   # Create and switch
git checkout branch-name      # Switch branch
git branch -d branch-name     # Delete branch

# Remote operations
git fetch                     # Fetch updates
git pull                      # Pull from remote
git push                      # Push to remote
git push -u origin branch     # Push and set upstream

# Undoing
git restore file              # Discard changes
git restore --staged file     # Unstage
git revert commit-hash        # Revert commit
git reset --soft HEAD~1       # Undo commit, keep changes
git reset --hard HEAD~1       # Undo commit, discard changes (DANGEROUS)

# Viewing
git show commit-hash          # Show commit
git log --graph --oneline     # View history graph
git blame file                # Show who changed lines
```

### Command Aliases (Optional)

Add to `~/.gitconfig`:

```ini
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = restore --staged
    last = log -1 HEAD
    graph = log --graph --oneline --all
    amend = commit --amend --no-edit
```

---

## Safety Reminders

### Destructive Operations (Cannot be undone)

- `git reset --hard` - Discards all changes
- `git clean -fd` - Removes untracked files
- `git push --force` - Overwrites remote history
- `git branch -D` - Force deletes branch
- `git restore .` - Discards all local changes

---

**For workflow guidance, best practices, and commit conventions, see [GIT_WORKFLOW.md](GIT_WORKFLOW.md)**
