# Upbound CLI (up) Guide

A comprehensive guide for using the Upbound CLI to manage Upbound projects, control planes, and Crossplane configurations.

## Overview

The Upbound `up` command-line tool enables developers to:
- Interact with Upbound control planes
- Simplify workflows with Upbound Crossplane (UXP)
- Build Crossplane packages for the Upbound Marketplace or other OCI-compliant registries
- Develop and test Crossplane configurations locally

## Installation

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

## Authentication

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

### Logout

```bash
up logout
```

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
```

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

## Control Plane Management

**📚 For comprehensive control plane management, see [upbound-cloud-management.md](./upbound-cloud-management.md)**

The new guide includes:
- How control planes relate to groups and spaces
- Creating control planes with all available options
- Monitoring control plane creation and health
- Deleting control planes safely
- Complete workflows and best practices

### Quick Reference

```bash
# Create Control Plane
up controlplane create <name> -g <group>

# List Control Planes
up controlplane list               # Current group
up controlplane list -A            # All groups
up controlplane list -g <group>    # Specific group

# Get Control Plane Details
up controlplane get <name> -g <group>
up controlplane get <name> --format json

# Delete Control Plane
up controlplane delete <name> -g <group>
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

## Space and Group Management

**📚 For comprehensive group and control plane management, see [upbound-cloud-management.md](./upbound-cloud-management.md)**

This new guide includes:
- Complete understanding of Organizations, Spaces, Groups, and Control Planes
- Detailed workflows for creating, listing, and deleting groups
- Detailed workflows for creating, listing, and deleting control planes
- Safety checks and best practices
- Common workflows and troubleshooting

### Quick Reference

```bash
# Groups (within current space)
up group list                      # List groups
up group create <name>             # Create group
up group get <name>                # Get group details
up group delete <name>             # Delete group

# Control Planes
up controlplane list               # List in current group
up controlplane list -A            # List across all groups
up controlplane create <name> -g <group>     # Create in specific group
up controlplane get <name> -g <group>        # Get details
up controlplane delete <name> -g <group>     # Delete
```

## Organization and Team Management

### Organizations

```bash
# List organizations
up organization list

# Get organization details
up organization get my-org

# Create organization
up organization create my-org
```

### Teams

```bash
# List teams
up team list

# Create team
up team create my-team

# Add members
up team add-member my-team user@example.com

# Remove members
up team remove-member my-team user@example.com
```

### Robots (Service Accounts)

```bash
# List robots
up robot list

# Create robot
up robot create my-robot

# Create robot token
up robot token create my-robot

# List robot tokens
up robot token list my-robot

# Delete robot token
up robot token delete <token-id>
```

## Repository Management

```bash
# List repositories
up repository list

# Create repository
up repository create my-repo

# Get repository details
up repository get my-repo
```

## Configuration and Composition Management

### XRD Management

```bash
# Generate XRD from Composite Resource (XR)
up xrd generate

# Generate XRD from Claim (XRC)
up xrd generate --from-claim
```

### Composition Management

```bash
# List compositions
up composition list

# Generate composition
up composition generate
```

### Function Management

```bash
# Generate a Function for a Composition
up function generate

# This creates KCL-based composition function scaffold
```

### Examples

```bash
# Manage example Claims (XRC) or Composite Resources (XR)
up example list
up example create
up example delete
```

## Dependency Management

```bash
# Add dependency to project
up dependency add <package>

# List dependencies
up dependency list

# Remove dependency
up dependency remove <package>

# Update dependencies
up dependency update
```

## Testing

```bash
# Run tests for project
up test run

# Run specific test
up test run <test-name>

# List tests
up test list
```

## Configuration

### Global Settings

```bash
# View global configuration
up config view

# Set configuration value
up config set <key> <value>

# Get configuration value
up config get <key>

# Unset configuration value
up config unset <key>
```

### Kubeconfig Context

```bash
# Select Upbound kubeconfig context
up ctx

# Use specific context
up ctx <context-name>

# List available contexts
up ctx list
```

## Output Formatting

Most commands support multiple output formats:

```bash
# Default human-readable output
up controlplane list

# JSON output
up controlplane list --format json

# YAML output
up controlplane list --format yaml

# Pretty print (if supported)
up controlplane list --pretty

# Quiet mode (suppress output)
up controlplane list --quiet
```

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
up controlplane create production-ctp --space production

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

## Debugging

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

## Advanced Configuration

### Custom Domain

```bash
# Use custom Upbound domain
up --domain my-upbound.example.com controlplane list

# Set in environment
export UP_DOMAIN=my-upbound.example.com
up controlplane list
```

### CA Bundle for Custom Certificates

```bash
# Use custom CA bundle
up --ca-bundle /path/to/ca-bundle.pem controlplane list

# Set in environment
export UP_CA_BUNDLE=/path/to/ca-bundle.pem
up controlplane list
```

### Skip TLS Verification (Insecure)

```bash
# Skip TLS verification (NOT RECOMMENDED for production)
up --insecure-skip-tls-verify controlplane list

# Set in environment
export UP_INSECURE_SKIP_TLS_VERIFY=true
```

### Custom Kubeconfig

```bash
# Use custom kubeconfig file
up --kubeconfig /path/to/kubeconfig project run

# Use specific context
up --kubecontext my-context project run
```

## Shell Completion

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

## Troubleshooting

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
up controlplane list --space my-space
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

### Getting Help

```bash
# General help
up --help

# Command-specific help
up project --help
up controlplane --help

# Subcommand help
up controlplane create --help

# View version
up version

# View license information
up license
```

## Environment Variables

Common environment variables for `up`:

- `UP_DOMAIN`: Root Upbound domain
- `UP_PROFILE`: Profile to use
- `UP_ORGANIZATION`: Organization to use
- `UP_ACCOUNT`: (Deprecated) Use UP_ORGANIZATION instead
- `UP_CA_BUNDLE`: Path to CA bundle file
- `UP_INSECURE_SKIP_TLS_VERIFY`: Skip TLS verification (insecure)
- `UP_DEBUG`: Enable debug logging
- `PRETTY`: Pretty print output

## Best Practices

1. **Use Profiles**: Create separate profiles for dev, staging, and production
2. **Test Locally**: Always run `up project run` before pushing to production
3. **Version Control**: Commit upbound.yaml and all configuration files
4. **CI/CD Integration**: Use `up login --username --password` for automated pipelines
5. **Dry Run**: Use `--dry-run` flag to preview destructive operations
6. **Quiet Mode**: Use `--quiet` in scripts to suppress unnecessary output
7. **Format Output**: Use `--format json` or `--format yaml` for scripting
8. **Security**: Never commit tokens or credentials; use robots for automation

## Quick Reference

```bash
# Authentication
up login                         # Login to Upbound
up logout                        # Logout

# Projects
up project init <name>           # Initialize project
up project build                 # Build project
up project push                  # Push to registry
up project run                   # Run locally
up project stop                  # Stop local run

# Control Planes
up controlplane create <name>    # Create control plane
up controlplane list             # List control planes
up controlplane get <name>       # Get details
up controlplane delete <name>    # Delete control plane

# Resources
up controlplane provider install <pkg>      # Install provider
up controlplane configuration install <pkg> # Install configuration
up controlplane function list               # List functions

# Configuration
up profile use <profile>         # Switch profile
up config view                   # View configuration
up ctx                          # Select kubeconfig context

# Output
--format json                    # JSON output
--format yaml                    # YAML output
--pretty                        # Pretty print
--quiet                         # Suppress output
--dry-run                       # Preview only
```

## Additional Resources

- [Upbound Documentation](https://docs.upbound.io/)
- [CLI Reference](https://docs.upbound.io/manuals/cli/)
- [Crossplane Documentation](https://docs.crossplane.io/)
- [Upbound Marketplace](https://marketplace.upbound.io/)
- [GitHub Repository](https://github.com/upbound/up)

---

**Note**: This guide is based on up CLI v0.42.0. Commands and options may vary in different versions. Always check `up --help` for the most current information.
