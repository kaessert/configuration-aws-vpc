# Upbound Cloud Management Guide

A comprehensive guide for managing Upbound Cloud resources: organizations, spaces, groups, and control planes.

## Understanding the Upbound Cloud Hierarchy

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

## 🚨 CRITICAL: Profile Safety Check

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

**⚠️ WARNING**: Running commands on the wrong profile can:
- Create resources in the wrong organization (billing impact)
- Delete resources in the wrong environment (data loss)
- Affect production systems unintentionally

**RULE**: If `up profile current` doesn't show `"organization": "solutions"`, **STOP ALL OPERATIONS**.

## Quick Context Check

Always verify your current context before running commands:

```bash
# 1. FIRST: Verify profile (MANDATORY)
up profile current
# Must show: "organization": "solutions"

# 2. Show current context (organization/space)
up ctx .
# Output: Kubeconfig context "upbound": Upbound solutions/upbound-aws-us-east-1

# 3. Show detailed profile information
up profile current --format json
# Output shows:
# - organization: solutions
# - currentKubeContext: solutions/upbound-aws-us-east-1

# List groups in current space
up group list
# Output shows all groups: default, upbox, claude-testing, etc.

# List control planes in current group
up controlplane list

# List control planes across ALL groups
up controlplane list -A
```

## Working with Groups

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
# STEP 1: ALWAYS verify profile first (MANDATORY)
up profile current
# Must show: "organization": "solutions"

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

## Working with Control Planes

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
# STEP 1: ALWAYS verify profile first (MANDATORY)
up profile current
# Must show: "organization": "solutions"

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

### Control Plane Best Practices

1. **Use descriptive names**: `vpc-production-ctp`, `app-staging-ctp`, not `ctp1`, `ctp2`
2. **Choose stable channel**: Use `--crossplane-channel Stable` for production
3. **Monitor creation**: Watch status with `up controlplane get <name>` until Ready
4. **Group by environment**: Keep dev, staging, prod in separate groups
5. **Clean up test control planes**: Delete E2E test control planes after use
6. **Document purpose**: Use consistent naming conventions to indicate purpose
7. **Backup before deletion**: Export important resources before deleting

## Common Workflows

### Workflow 1: Create a New Environment

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

### Workflow 2: Run E2E Tests with Dedicated Group

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

### Workflow 3: Clean Up Old Resources

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

### Workflow 4: Migrate Between Groups

```bash
# 1. List current control planes
up controlplane list -A

# 2. Create new group
up group create new-environment

# 3. Create new control planes in new group
up controlplane create app-ctp -g new-environment

# 4. Migrate resources (export from old, import to new)
# Set context to old control plane
up ctx solutions/upbound-aws-us-east-1/old-group/old-ctp
kubectl get composite -o yaml > backup.yaml

# Set context to new control plane
up ctx solutions/upbound-aws-us-east-1/new-environment/app-ctp
kubectl apply -f backup.yaml

# 5. Verify migration
kubectl get composite

# 6. Delete old control plane when satisfied
up controlplane delete old-ctp -g old-group
```

### Workflow 5: Multi-Environment Setup

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

### Context Best Practices

1. **Always check context first**: Run `up ctx .` before operations
2. **Explicit group specification**: Use `-g <group>` flag to be explicit
3. **Verify before deletion**: Check context and list resources before deleting
4. **Use full paths in scripts**: Don't rely on relative context in automation
5. **Return to root**: Use `up ctx solutions/upbound-aws-us-east-1` to reset

## Output Formatting

All commands support multiple output formats for scripting and automation.

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

## Debugging and Troubleshooting

### Enable Debug Logging

```bash
# Run with debug logging
up --debug group list
up -d controlplane list

# Increase verbosity (repeat for more detail)
up -d -d controlplane create my-ctp

# WARNING: Debug output may contain sensitive data like tokens
```

### Common Issues

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

## Safety Checklist

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

## Environment Variables

Control behavior with environment variables:

```bash
# Set default organization
export UP_ORGANIZATION=solutions

# Set default profile
export UP_PROFILE=my-profile

# Enable debug logging
export UP_DEBUG=true

# Use custom domain
export UP_DOMAIN=https://my-upbound.example.com

# Use custom CA bundle
export UP_CA_BUNDLE=/path/to/ca-bundle.pem
```

## Quick Reference

```bash
# Groups
up group list                      # List groups
up group create <name>             # Create group
up group get <name>                # Get group details
up group delete <name>             # Delete group
up group delete <name> --force     # Force delete (deletes all control planes)

# Control Planes
up controlplane list               # List in current group
up controlplane list -A            # List all groups
up controlplane list -g <group>    # List in specific group
up controlplane create <name> -g <group>           # Create
up controlplane get <name> -g <group>              # Get details
up controlplane delete <name> -g <group>           # Delete

# Context
up ctx .                          # Show current context
up ctx ..                         # Move to parent
up ctx -                          # Previous context
up profile current                # Show profile details

# Output Formatting
--format json                     # JSON output
--format yaml                     # YAML output
--quiet                          # Suppress output
--debug                          # Debug logging
```

## Best Practices Summary

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

## Additional Resources

- [Upbound Documentation](https://docs.upbound.io/)
- [Upbound Cloud Console](https://console.upbound.io/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [up CLI Guide](./up-cli-guide.md)

---

**Note**: This guide reflects the current up CLI behavior. Always check `up --help`, `up group --help`, and `up controlplane --help` for the most current information.
