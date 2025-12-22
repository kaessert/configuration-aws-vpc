# Upbound Platform Reference

Comprehensive guide for the Upbound CLI (`up`) and Upbound Cloud platform, covering CLI commands, authentication, control plane management, and resource hierarchy.

## Table of Contents

- [Platform Architecture](#platform-architecture)
- [Authentication & Setup](#authentication--setup)
- [Project Management](#project-management)
- [Group Management](#group-management)
- [Control Plane Management](#control-plane-management)
- [Context Management](#context-management)
- [Common Workflows](#common-workflows)
- [Safety & Best Practices](#safety--best-practices)
- [Debugging & Troubleshooting](#debugging--troubleshooting)
- [Quick Reference](#quick-reference)

---

## Platform Architecture

### Understanding the Upbound Cloud Hierarchy

Upbound Cloud uses a hierarchical structure to organize resources:

```
Organization (solutions)
└── Space (upbound-aws-us-east-1)
    ├── Group (default)
    │   ├── Control Plane (my-app-ctp)
    │   └── Control Plane (another-ctp)
    ├── Group (upbox)
    │   └── Control Plane (test-ctp)
    └── Group (claude-testing)
        └── Control Plane (e2e-test-ctp)
```

### 1. Organization

- **What it is**: Top-level entity in Upbound Cloud
- **Purpose**: Contains all your spaces, teams, and resources
- **Example**: `solutions`
- **Scope**: Billing, user management, global settings
- **How to identify**: `up profile current` shows `"organization": "solutions"`

### 2. Space

- **What it is**: Physical deployment location for control planes
- **Purpose**: Represents where your Crossplane infrastructure actually runs
- **Example**: `upbound-aws-us-east-1` (managed space in AWS US East 1)
- **Scope**: Regional deployment, network isolation, physical resources
- **How to identify**: `up ctx .` shows `solutions/upbound-aws-us-east-1`
- **Note**: For managed Upbound Cloud, spaces are pre-created by Upbound

### 3. Group (Control Plane Group)

- **What it is**: Logical grouping of control planes within a space
- **Purpose**: Organize control planes by environment, team, or purpose
- **Examples**: `default`, `upbox`, `claude-testing`, `production`, `staging`
- **Scope**: Organizational unit, access control, logical separation
- **How to identify**: `up group list` shows all groups in current space
- **Protected**: Groups can be marked as protected to prevent accidental deletion

### 4. Control Plane

- **What it is**: Actual Crossplane cluster instance
- **Purpose**: Runs Crossplane, providers, and manages cloud resources
- **Examples**: `my-vpc-ctp`, `e2etest-xvpc-basic`
- **Scope**: Contains packages (providers, configurations, functions), manages resources
- **How to identify**: `up controlplane list` shows control planes in current group

---

## Authentication & Setup

### Installation

The CLI supports multiple installation methods:

```bash
# Shell script (recommended) - auto-detects OS/architecture
curl -sL "https://cli.upbound.io" | sh

# Homebrew (macOS and Linux)
brew install upbound/tap/up

# Verify installation
up version
```

Current stable release: v0.42.0

### Login to Upbound

```bash
# Interactive login (launches web browser)
up login

# Automated login for scripts
up login --username YOUR_USERNAME --password YOUR_PASSWORD

# Login with specific organization
up login --organization YOUR_ORG

# Check current profile
up profile current

# List all profiles
up profile list
```

### Organization

**Organization**: solutions

**Current Profile**: solutions (cloud)

### Logout

```bash
up logout
```

### CRITICAL: Profile Safety Check

**ALWAYS verify you're on the correct profile before ANY operation!**

```bash
# Check current profile (MANDATORY before any command)
up profile current

# Expected output for this project:
# {
#   "name": "solutions",
#   "profile": {
#     "organization": "solutions",
#     ...
#   }
# }

# If NOT on "solutions" profile: STOP IMMEDIATELY
# Switch to correct profile:
up profile use solutions
```

**WARNING**: Running commands on the wrong profile can:
- Create resources in the wrong organization (billing impact)
- Delete resources in the wrong environment (data loss)
- Affect production systems unintentionally

**RULE**: If `up profile current` doesn't show `"organization": "solutions"`, **STOP ALL OPERATIONS**.

### Managing Profiles

```bash
# Create a new profile
up profile create my-profile

# Switch between profiles
up profile use my-profile

# Set default organization
up profile set-default-organization my-org

# View profile configuration
up profile view

# List all profiles
up profile list
```

### Quick Context Check

**Always verify your current context** before running commands. See [Profile Safety Check](#critical-profile-safety-check) for mandatory verification steps.

```bash
# Quick context summary
up ctx .
up group list
up controlplane list -A
```

---

## Project Management

### Initialize a New Project

```bash
# Initialize a new Upbound project
up project init my-project

# Initialize in current directory
up project init .

# This creates:
# - upbound.yaml (project manifest)
# - apis/ (XRD definitions)
# - examples/ (example claims)
```

### Build a Project

```bash
# Build project into Crossplane packages
up project build

# Build with specific output directory
up project build --output ./build

# Build creates OCI-compliant package images
```

### Push to Registry

```bash
# Push project packages to Upbound Marketplace
up project push

# Push to specific registry
up project push --registry my-registry.upbound.io

# Push with specific tag
up project push --tag v1.0.0
```

### Run Project Locally

```bash
# Run project on a development control plane
up project run

# This:
# - Creates a local development control plane
# - Installs your project
# - Allows testing without deploying to production

# Stop the development control plane
up project stop
```

### Simulate Against Existing Control Plane

```bash
# Run project as simulation against existing control plane
up project simulate

# Manage simulations
up project simulation list
up project simulation delete <simulation-id>
```

### Upgrade Project

```bash
# Upgrade project to newer API version
up project upgrade
```

### AI Tooling

```bash
# Generate AI tooling for project
up project ai
```

### Dependency Management

```bash
# Add dependency to project
up dependency add <package>

# Examples
up dependency add xpkg.upbound.io/upbound/provider-aws-ec2:v2.3.0

# List dependencies
up dependency list

# Remove dependency
up dependency remove <package>

# Update dependencies
up dependency update

# Update dependency cache (CRITICAL after adding dependencies)
up dep update-cache
```

### Testing

```bash
# Run tests for project
up test run

# Run specific test
up test run <test-name>

# Run E2E tests (requires control plane group)
up test run <test-name> --e2e --control-plane-group=<group-name>

# List tests
up test list
```

### Function Management

```bash
# Generate a Function for a Composition
up function generate <function-name> <composition-path> --language kcl

# Example
up function generate vpc apis/vpc/composition.yaml --language kcl

# This creates KCL-based composition function scaffold
```

### XRD and Composition Management

```bash
# Generate XRD from Composite Resource (XR)
up xrd generate

# Generate XRD from Claim (XRC)
up xrd generate --from-claim

# List compositions
up composition list

# Generate composition
up composition generate
```

### Examples

```bash
# Manage example Claims (XRC) or Composite Resources (XR)
up example list
up example create
up example delete
```

---

## Group Management

Groups are logical containers for control planes within a space. They help organize control planes by environment, team, or purpose.

### List Groups

```bash
# List all groups in the current space
up group list

# Output format:
# NAME            PROTECTED
# default         false
# upbox           false
# claude-testing  false
# production      true
```

The output shows:
- **NAME**: Group name
- **PROTECTED**: Whether the group is protected from deletion

### Create a Group

```bash
# STEP 1: Verify profile (see Profile Safety Check above)
up profile current  # Must show: "organization": "solutions"

# STEP 2: Create a new group in the current space
up group create <group-name>

# Examples:
up group create development
up group create staging
up group create production
up group create team-a
up group create claude-testing
```

**Important Notes:**
- Group names must be unique within the space
- Groups are created in the current space (check with `up ctx .`)
- No additional flags required - groups are simple containers
- Newly created groups are not protected by default

### Get Group Details

```bash
# Get information about a specific group
up group get <group-name>

# Example:
up group get production

# Get output in JSON format
up group get production --format json

# Get output in YAML format
up group get production --format yaml
```

### Delete a Group

**CRITICAL WARNING**: Deleting a group will delete ALL control planes within it!

```bash
# Delete a group (must be empty or use --force)
up group delete <group-name>

# Example:
up group delete old-group

# Force delete (deletes group even if it contains control planes)
up group delete old-group --force
```

**Important Notes:**
- Protected groups cannot be deleted (remove protection first)
- **Deleting a group deletes ALL control planes inside it**
- Always verify group contents before deletion: `up controlplane list -g <group-name>`
- Use `--force` flag to delete non-empty groups (DANGEROUS)
- Cannot be undone - backup resources first!

### Group Best Practices

1. **Use descriptive names**: `production`, `staging`, `development`, not `group1`, `group2`
2. **Protect critical groups**: Mark production groups as protected
3. **Organize by environment**: Separate dev, staging, and production control planes
4. **Organize by team**: Create groups for different teams if needed
5. **Use for E2E tests**: Create dedicated groups like `claude-testing` for automated tests
6. **Clean up regularly**: Delete unused groups to keep things organized

---

## Control Plane Management

Control planes are actual Crossplane cluster instances that run within groups.

### List Control Planes

```bash
# List control planes in the current group (from context)
up controlplane list

# List control planes in a specific group
up controlplane list -g <group-name>
up controlplane list --group <group-name>

# List control planes across ALL groups in the space
up controlplane list -A
up controlplane list --all-groups

# Examples:
up controlplane list                    # Current group only
up controlplane list -g production      # Production group
up controlplane list -g claude-testing  # Testing group
up controlplane list -A                 # All groups

# Output format:
# GROUP   NAME                    CROSSPLANE    READY   HEALTHY   MESSAGE     AGE
# upbox   my-vpc-ctp              1.20.4-up.1   True    True      Available   2h
# upbox   test-ctp                1.20.4-up.1   True    True      Available   1h
```

The output shows:
- **GROUP**: Which group the control plane belongs to
- **NAME**: Control plane name
- **CROSSPLANE**: Crossplane version running
- **READY**: Whether the control plane is ready to use
- **HEALTHY**: Health status
- **MESSAGE**: Current status message
- **AGE**: How long the control plane has existed

### Create a Control Plane

```bash
# STEP 1: Verify profile (see Profile Safety Check above)
up profile current  # Must show: "organization": "solutions"

# STEP 2: Create a control plane in a specific group
up controlplane create <name> -g <group-name>
up controlplane create <name> --group <group-name>

# Create in current group (from context)
up controlplane create <name>

# Examples:
up controlplane create my-vpc-ctp -g production
up controlplane create dev-ctp -g development
up controlplane create test-ctp -g claude-testing

# With additional options:
up controlplane create my-ctp -g production \
  --crossplane-version 1.20.4-up.1 \
  --crossplane-channel Stable
```

**Available Options:**

- **`-g, --group=<group>`**: Group to create control plane in (defaults to current context)
- **`--crossplane-version=<version>`**: Specific Crossplane version (e.g., `1.20.4-up.1`)
- **`--crossplane-channel=<channel>`**: Auto-upgrade channel
  - `None`: No automatic upgrades
  - `Patch`: Auto-upgrade to patch versions (e.g., 1.20.4 → 1.20.5)
  - `Stable`: Auto-upgrade to stable releases (default, recommended)
  - `Rapid`: Latest releases including pre-release versions
- **`--secret-name=<name>`**: Custom name for kubeconfig secret (defaults to `kubeconfig-<ctp-name>`)

**Important Notes:**
- Control plane names must be unique within the group
- Creation takes 5-10 minutes for the control plane to become Ready
- Default channel is `Stable` (recommended for most use cases)
- If `--group` is not specified, uses the group from current context
- After creation, use `up controlplane get <name>` to monitor status

### Get Control Plane Details

```bash
# Get details about a specific control plane
up controlplane get <name>

# Get from specific group
up controlplane get <name> -g <group-name>

# Examples:
up controlplane get my-vpc-ctp
up controlplane get test-ctp -g claude-testing

# Get output in JSON format
up controlplane get my-ctp --format json

# Get output in YAML format
up controlplane get my-ctp --format yaml
```

### Delete a Control Plane

**WARNING**: Deleting a control plane is destructive and cannot be undone!

```bash
# Delete a control plane
up controlplane delete <name>

# Delete from specific group
up controlplane delete <name> -g <group-name>

# Examples:
up controlplane delete old-ctp
up controlplane delete test-ctp -g claude-testing
```

**Important Notes:**
- **Deletion is immediate and cannot be undone**
- All managed resources (AWS resources, etc.) will be deleted based on deletion policies
- Packages, configurations, and functions in the control plane are removed
- Kubeconfig secrets associated with the control plane are deleted
- If `--group` is not specified, uses the group from current context
- **Best Practice**: Always verify what's in the control plane before deletion:
  ```bash
  # Check what resources exist
  kubectl get managed
  kubectl get composite
  kubectl get claim
  ```

### Connect App Cluster

```bash
# Connect an App Cluster using MCP Connector
up controlplane connector

# Connect using API Connector
up controlplane api-connector
```

### Manage Control Plane Resources

```bash
# Manage Configurations
up controlplane configuration list
up controlplane configuration install <package>

# Manage Providers
up controlplane provider list
up controlplane provider install <provider>

# Manage Functions
up controlplane function list
up controlplane function install <function>

# Manage pull secrets
up controlplane pull-secret create my-secret \
  --docker-server registry.upbound.io \
  --docker-username myuser \
  --docker-password mypassword
```

### Control Plane Best Practices

1. **Use descriptive names**: `vpc-production-ctp`, `app-staging-ctp`, not `ctp1`, `ctp2`
2. **Choose stable channel**: Use `--crossplane-channel Stable` for production
3. **Monitor creation**: Watch status with `up controlplane get <name>` until Ready
4. **Group by environment**: Keep dev, staging, prod in separate groups
5. **Clean up test control planes**: Delete E2E test control planes after use
6. **Document purpose**: Use consistent naming conventions to indicate purpose
7. **Backup before deletion**: Export important resources before deleting

---


## Context Management

Understanding and managing your context is crucial for working with Upbound Cloud.

### Check Current Context

```bash
# Show current context
up ctx .
# Output: Kubeconfig context "upbound": Upbound solutions/upbound-aws-us-east-1

# Show current profile (more details)
up profile current
# Output (JSON):
# {
#   "name": "solutions",
#   "profile": {
#     "organization": "solutions",
#     "currentKubeContext": "solutions/upbound-aws-us-east-1"
#   }
# }
```

### Navigate Context

The context follows a hierarchical path: `organization/space/group/controlplane`

```bash
# Move to parent level
up ctx ..

# Move to previous context
up ctx -

# Stay at current context (just display)
up ctx .

# Move to specific control plane
up ctx solutions/upbound-aws-us-east-1/production/vpc-ctp

# Move to specific group (for group operations)
up ctx solutions/upbound-aws-us-east-1/production
```

**Context Levels:**
- **Organization**: `solutions`
- **Space**: `solutions/upbound-aws-us-east-1`
- **Group**: `solutions/upbound-aws-us-east-1/production`
- **Control Plane**: `solutions/upbound-aws-us-east-1/production/vpc-ctp`

### Kubeconfig Context

```bash
# Select Upbound kubeconfig context
up ctx

# Use specific context
up ctx <context-name>

# List available contexts
up ctx list
```

### Context Best Practices

1. **Always check context first**: Run `up ctx .` before operations
2. **Explicit group specification**: Use `-g <group>` flag to be explicit
3. **Verify before deletion**: Check context and list resources before deleting
4. **Use full paths in scripts**: Don't rely on relative context in automation
5. **Return to root**: Use `up ctx solutions/upbound-aws-us-east-1` to reset

---

## Common Workflows

### Workflow 1: Creating a New Project

```bash
# 1. Login to Upbound
up login

# 2. Initialize project
up project init my-vpc-config
cd my-vpc-config

# 3. Define your XRDs, Compositions, and Functions
# (Edit files in apis/, compositions/, functions/)

# 4. Test locally
up project run

# 5. Build and push
up project build
up project push
```

### Workflow 2: Deploying to Control Plane

```bash
# 1. Create control plane
up controlplane create production-ctp -g production

# 2. Install providers
up controlplane provider install xpkg.upbound.io/upbound/provider-aws

# 3. Install your configuration
up controlplane configuration install \
  xpkg.upbound.io/myorg/configuration-aws-vpc:v1.0.0

# 4. Verify installation
up controlplane configuration list
```

### Workflow 3: Local Development Loop

```bash
# 1. Make changes to your project
# (Edit XRDs, Compositions, Functions)

# 2. Run locally to test
up project stop  # Stop previous run if any
up project run

# 3. Test with example claims
kubectl apply -f examples/vpc-example.yaml

# 4. Debug and iterate
kubectl get composite
kubectl describe vpc my-vpc

# 5. When satisfied, build and push
up project stop
up project build
up project push
```

### Workflow 4: Managing Multiple Environments

```bash
# 1. Create profiles for each environment
up profile create dev --organization myorg-dev
up profile create staging --organization myorg-staging
up profile create prod --organization myorg-prod

# 2. Switch between environments
up profile use dev
up controlplane list

up profile use staging
up controlplane list

up profile use prod
up controlplane list
```

### Workflow 5: Create a New Environment

```bash
# 1. Check current context
up ctx .
# Output: Kubeconfig context "upbound": Upbound solutions/upbound-aws-us-east-1

# 2. Create a group for the environment
up group create production

# 3. Create control planes in the group
up controlplane create vpc-ctp -g production
up controlplane create app-ctp -g production

# 4. Monitor creation (wait for Ready)
up controlplane get vpc-ctp -g production
up controlplane get app-ctp -g production

# 5. List all control planes to verify
up controlplane list -g production
```

### Workflow 6: Run E2E Tests with Dedicated Group

```bash
# 1. Create a group for testing (one-time setup)
up group create claude-testing

# 2. Run E2E test (creates temporary control plane)
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing

# 3. If test fails and you need to debug, keep the control plane:
up test run tests/e2etest-xvpc-basic --e2e \
  --control-plane-group=claude-testing \
  --skip-delete

# 4. Debug the control plane
up controlplane list -g claude-testing
up controlplane get <test-ctp-name> -g claude-testing

# 5. Clean up when done
up controlplane delete <test-ctp-name> -g claude-testing
```

### Workflow 7: Clean Up Old Resources

```bash
# 1. List all control planes to find old ones
up controlplane list -A

# 2. Check what's in a control plane before deletion
# (Set context to the control plane first)
up ctx solutions/upbound-aws-us-east-1/<group>/<controlplane>
kubectl get managed
kubectl get composite

# 3. Delete the control plane
up controlplane delete old-ctp -g old-group

# 4. If the group is now empty, delete it too
up group delete old-group
```

### Workflow 8: Multi-Environment Setup

```bash
# 1. Create groups for each environment
up group create development
up group create staging
up group create production

# 2. Create control planes in each environment
# Development
up controlplane create dev-vpc-ctp -g development
up controlplane create dev-app-ctp -g development

# Staging
up controlplane create staging-vpc-ctp -g staging
up controlplane create staging-app-ctp -g staging

# Production (with specific version and settings)
up controlplane create prod-vpc-ctp -g production \
  --crossplane-version 1.20.4-up.1 \
  --crossplane-channel Patch  # Only patch upgrades for production

up controlplane create prod-app-ctp -g production \
  --crossplane-version 1.20.4-up.1 \
  --crossplane-channel Patch

# 3. Verify all control planes
up controlplane list -A

# 4. Mark production group as protected (if available)
# Note: Protection might require console or API access
```

### Workflow 9: Monitor E2E Test

```bash
# 1. Run E2E test from CLI
up test run tests/e2etest-xvpc-basic --e2e --control-plane-group=claude-testing

# 2. Monitor with kubectl (in separate terminal)
kubectl get managed -w
kubectl get vpc,subnet,internetgateway,routetable -w

# 3. Check package status
kubectl get pkgrev
up ctp package list

# 4. View events
kubectl get events --sort-by='.lastTimestamp'

# 5. Check XR status
kubectl get vpc -o yaml
kubectl describe vpc <vpc-name>

# 6. Wait for all resources to reach Ready/Synced

# 7. Verify in AWS Console (optional)
# Open AWS Console → VPC Dashboard
# Verify VPC, subnets, IGW, route tables exist

# 8. Test completes and cleans up
# Control plane is automatically deleted
```

---

## Safety & Best Practices

### Profile Safety Rules

See [Profile Safety Check](#critical-profile-safety-check) for mandatory verification steps before ANY operation.

**Additional best practices**:
- Use explicit flags: Specify `-g <group>` to avoid context mistakes
- Document profile usage: Keep track of which profile is for what

### Safety Checklist Before Deletion

Before deleting groups or control planes, verify:

- [ ] **CRITICAL**: Check profile: `up profile current` (must be "solutions")
- [ ] Check current context: `up ctx .`
- [ ] List group contents: `up controlplane list -g <group>`
- [ ] Verify control plane resources: `kubectl get managed`, `kubectl get composite`
- [ ] Backup important resources: Export YAML configurations
- [ ] Check deletion policies: Ensure cleanup behavior is expected
- [ ] Notify team members: If shared environment
- [ ] Document deletion reason: For audit trail
- [ ] Verify correct target: Triple-check names and groups
- [ ] Have rollback plan: Know how to recreate if needed

### Best Practices Summary

1. **Always verify context**: Run `up ctx .` before any operation
2. **Use explicit groups**: Specify `-g <group>` to avoid accidents
3. **Descriptive naming**: Use clear, consistent naming conventions
4. **Organize logically**: Group by environment, team, or purpose
5. **Clean up regularly**: Delete unused groups and control planes
6. **Monitor E2E tests**: Use dedicated groups like `claude-testing`
7. **Backup before deletion**: Export resources before destructive operations
8. **Use stable channels**: Choose `Stable` for production control planes
9. **Protect production**: Mark critical groups as protected
10. **Document changes**: Keep track of why groups/control planes were created/deleted
11. **Test locally first**: Always run `up project run` before pushing to production
12. **Version control**: Commit upbound.yaml and all configuration files
13. **CI/CD integration**: Use `up login --username --password` for automated pipelines
14. **Dry run**: Use `--dry-run` flag to preview destructive operations
15. **Security**: Never commit tokens or credentials; use robots for automation

---

## Debugging & Troubleshooting

### Enable Debug Logging

```bash
# Run with debug logging
up --debug project run

# Increase verbosity (repeat for more detail)
up -d -d controlplane list

# WARNING: Debug output may contain sensitive data like tokens
```

### Dry Run

```bash
# Preview actions without executing
up --dry-run project push

# Test commands safely
up --dry-run controlplane delete my-ctp
```

### Common Issues

**Issue: Authentication failures**
```bash
# Solution: Re-login
up logout
up login
```

**Issue: Control plane not found**
```bash
# Solution: Check space and organization
up profile current
up controlplane list -A
```

**Issue: "group not found"**
```bash
# Solution: Check current context and list groups
up ctx .
up group list
```

**Issue: "control plane not found"**
```bash
# Solution: Check which group the control plane is in
up controlplane list -A

# Then specify the correct group
up controlplane get my-ctp -g correct-group
```

**Issue: "cannot delete group: not empty"**
```bash
# Solution: Delete all control planes first
up controlplane list -g old-group
up controlplane delete ctp1 -g old-group
up controlplane delete ctp2 -g old-group

# Or force delete (DANGEROUS)
up group delete old-group --force
```

**Issue: "control plane stuck in creating state"**
```bash
# Solution: Check control plane status and events
up controlplane get my-ctp -g my-group --format json

# If stuck for > 15 minutes, contact Upbound support or delete and recreate
up controlplane delete my-ctp -g my-group
up controlplane create my-ctp -g my-group
```

**Issue: Package push fails**
```bash
# Solution: Check credentials and registry
up repository list
up login  # Re-authenticate
```

**Issue: Project run fails**
```bash
# Solution: Check for existing runs and clean up
up project stop
up project run --clean
```

### Monitoring Control Plane Creation

```bash
# Watch control plane status (poll every 10 seconds)
watch -n 10 'up controlplane get my-ctp -g production'

# Or use a while loop
while true; do
  STATUS=$(up controlplane get my-ctp --format json | jq -r '.status.ready')
  echo "Ready: $STATUS"
  [ "$STATUS" = "True" ] && break
  sleep 10
done
```

### Output Formatting for Debugging

```bash
# Default human-readable format
up group list
up controlplane list

# JSON format (for scripts, jq processing)
up group list --format json
up controlplane list --format json

# YAML format (for configuration management)
up group get production --format yaml
up controlplane get my-ctp --format yaml

# Quiet mode (suppress output, useful for CI/CD)
up group create test-group --quiet
up controlplane delete old-ctp --quiet

# Pretty print (if supported)
up controlplane list --pretty
```

**Scripting Examples:**

```bash
# Get all control plane names in a group
up controlplane list -g production --format json | jq -r '.[].name'

# Check if a control plane is ready
READY=$(up controlplane get my-ctp --format json | jq -r '.status.ready')
if [ "$READY" = "True" ]; then
  echo "Control plane is ready"
fi

# Count control planes in a group
up controlplane list -g production --format json | jq '. | length'
```

### Getting Help

```bash
# General help
up --help

# Command-specific help
up project --help
up controlplane --help
up group --help

# Subcommand help
up controlplane create --help
up group delete --help

# View version
up version

# View license information
up license
```

---

## Quick Reference

### Authentication

```bash
up login                         # Login to Upbound
up logout                        # Logout
up profile current               # Check current profile (MANDATORY)
up profile use <profile>         # Switch profile
up profile list                  # List all profiles
```

### Projects

```bash
up project init <name>           # Initialize project
up project build                 # Build project
up project push                  # Push to registry
up project run                   # Run locally
up project stop                  # Stop local run
up dependency add <package>      # Add dependency
up dep update-cache              # Update dependency cache
```

### Groups

```bash
up group list                    # List groups
up group create <name>           # Create group
up group get <name>              # Get group details
up group delete <name>           # Delete group
up group delete <name> --force   # Force delete (deletes all control planes)
```

### Control Planes

```bash
up controlplane list             # List in current group
up controlplane list -A          # List all groups
up controlplane list -g <group>  # List in specific group
up controlplane create <name> -g <group>           # Create
up controlplane get <name> -g <group>              # Get details
up controlplane delete <name> -g <group>           # Delete
```

### Resources

```bash
up controlplane provider install <pkg>      # Install provider
up controlplane configuration install <pkg> # Install configuration
up controlplane function list               # List functions
```

### Context

```bash
up ctx .                          # Show current context
up ctx ..                         # Move to parent
up ctx -                          # Previous context
```

### Testing

```bash
up test run <test-name>                              # Run test
up test run <test-name> --e2e --control-plane-group=<group>  # Run E2E test
up test list                                         # List tests
```

### Output Formatting

```bash
--format json                    # JSON output
--format yaml                    # YAML output
--pretty                        # Pretty print
--quiet                         # Suppress output
--dry-run                       # Preview only
--debug                         # Debug logging
```

### Environment Variables

```bash
export UP_ORGANIZATION=solutions  # Set default organization
export UP_PROFILE=my-profile      # Set default profile
export UP_DEBUG=true              # Enable debug logging
export UP_DOMAIN=https://...      # Use custom domain
export UP_CA_BUNDLE=/path/to/ca   # Use custom CA bundle
```

### Organization and Team Management

```bash
# Organizations
up organization list             # List organizations
up organization get my-org       # Get organization details
up organization create my-org    # Create organization

# Teams
up team list                     # List teams
up team create my-team           # Create team
up team add-member my-team user@example.com      # Add member
up team remove-member my-team user@example.com   # Remove member

# Robots (Service Accounts)
up robot list                    # List robots
up robot create my-robot         # Create robot
up robot token create my-robot   # Create robot token
up robot token list my-robot     # List robot tokens
up robot token delete <token-id> # Delete robot token
```

### Repository Management

```bash
up repository list               # List repositories
up repository create my-repo     # Create repository
up repository get my-repo        # Get repository details
```

### Advanced Configuration

```bash
# Custom Domain
up --domain my-upbound.example.com controlplane list
export UP_DOMAIN=my-upbound.example.com

# CA Bundle for Custom Certificates
up --ca-bundle /path/to/ca-bundle.pem controlplane list
export UP_CA_BUNDLE=/path/to/ca-bundle.pem

# Skip TLS Verification (Insecure)
up --insecure-skip-tls-verify controlplane list
export UP_INSECURE_SKIP_TLS_VERIFY=true

# Custom Kubeconfig
up --kubeconfig /path/to/kubeconfig project run
up --kubecontext my-context project run
```

### Shell Completion

```bash
# Generate completions for bash
up completion bash > /etc/bash_completion.d/up

# Generate completions for zsh
up completion zsh > "${fpath[1]}/_up"

# Generate completions for fish
up completion fish > ~/.config/fish/completions/up.fish

# Generate completions for PowerShell
up completion powershell > up.ps1
```

---

## Additional Resources

- [Upbound Documentation](https://docs.upbound.io/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [Upbound Marketplace](https://marketplace.upbound.io/)
- [up CLI GitHub](https://github.com/upbound/up)
- [CLI Reference](https://docs.upbound.io/manuals/cli/)

---

**Note**: This guide consolidates CLI information from multiple sources and is based on up CLI v0.42.0. Commands and options may vary in different versions. Always check `up --help` for the most current information.
