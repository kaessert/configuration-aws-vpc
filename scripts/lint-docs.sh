#!/bin/bash
# Documentation Linter: Check for common VPC vs XVPC mistakes
#
# This script validates that documentation consistently uses the correct
# resource kinds and namespacing as defined in the XRD.
#
# Usage: ./scripts/lint-docs.sh
# Exit codes: 0 = pass, 1 = errors found

set -euo pipefail

ERRORS=0
WARNINGS=0

echo "================================================"
echo "  AWS VPC Configuration - Documentation Linter"
echo "================================================"
echo ""

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print errors
error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
    ERRORS=$((ERRORS + 1))
}

# Function to print warnings
warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

# Function to print success
success() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
}

echo "Running documentation checks..."
echo ""

# =============================================================================
# CHECK 1: No XVPC in user-facing documentation
# =============================================================================
echo "Check 1: Verifying no 'kind: XVPC' in user-facing docs..."

USER_FACING_DOCS=(
    "README.md"
    "CLAUDE.md"
    "TESTING.md"
    "examples/"
)

for doc in "${USER_FACING_DOCS[@]}"; do
    if [ -e "$doc" ]; then
        # Allow "DO NOT use `kind: XVPC`" warnings - these are intentional
        # Check for kind: XVPC but exclude lines that are warnings/errors about it
        MATCHES=$(grep -r "kind: XVPC" "$doc" 2>/dev/null | grep -v "DO NOT" | grep -v "not use" | grep -v "documentation error" || true)
        if [ -n "$MATCHES" ]; then
            error "Found 'kind: XVPC' in $doc - this project uses 'kind: VPC'"
            echo "  → Check: grep -n 'kind: XVPC' $doc"
        fi
    fi
done

if [ $ERRORS -eq 0 ]; then
    success "No 'kind: XVPC' found in user-facing docs"
fi
echo ""

# =============================================================================
# CHECK 2: Examples must include namespace field
# =============================================================================
echo "Check 2: Verifying all examples include namespace field..."

if [ -d "examples" ]; then
    # Find all YAML files with kind: VPC
    while IFS= read -r file; do
        # Check if this file has namespace field
        if ! grep -q "namespace:" "$file"; then
            error "Example missing namespace field: $file"
            echo "  → Add 'namespace: default' to metadata section"
        fi
    done < <(grep -l "kind: VPC" examples/*.yaml 2>/dev/null || true)

    if [ $ERRORS -eq 0 ]; then
        success "All examples include namespace field"
    fi
fi
echo ""

# =============================================================================
# CHECK 3: E2E tests must use namespaced VPC
# =============================================================================
echo "Check 3: Verifying E2E tests use namespaced VPC..."

if [ -d "tests" ]; then
    # Check E2E test files
    E2E_ERRORS=0
    for test_dir in tests/e2etest-*/; do
        if [ -f "$test_dir/main.k" ]; then
            # Check for kind: "VPC" (with or without XVPC)
            if grep -q 'kind: "XVPC"' "$test_dir/main.k"; then
                error "E2E test uses XVPC: $test_dir/main.k"
                E2E_ERRORS=$((E2E_ERRORS + 1))
            fi

            # Check for namespace field in manifests
            if grep -q 'kind: "VPC"' "$test_dir/main.k"; then
                # Look for namespace in the same manifest block
                if ! grep -A 10 'kind: "VPC"' "$test_dir/main.k" | grep -q 'namespace:'; then
                    error "E2E test missing namespace: $test_dir/main.k"
                    E2E_ERRORS=$((E2E_ERRORS + 1))
                fi
            fi

            # Check for namespace in ProviderConfig
            if grep -q 'kind: "ProviderConfig"' "$test_dir/main.k"; then
                if ! grep -A 10 'kind: "ProviderConfig"' "$test_dir/main.k" | grep -q 'namespace:'; then
                    error "E2E test ProviderConfig missing namespace: $test_dir/main.k"
                    E2E_ERRORS=$((E2E_ERRORS + 1))
                fi
            fi
        fi
    done

    if [ $E2E_ERRORS -eq 0 ]; then
        success "All E2E tests use namespaced VPC correctly"
    fi
fi
echo ""

# =============================================================================
# CHECK 4: ProviderConfig must use correct API version
# =============================================================================
echo "Check 4: Verifying ProviderConfig uses correct API version..."

WRONG_API=0
if [ -d "tests" ]; then
    for test_dir in tests/e2etest-*/; do
        if [ -f "$test_dir/main.k" ]; then
            # Check for wrong API version (without .m.)
            if grep -q 'apiVersion: "aws.upbound.io/v1beta1"' "$test_dir/main.k"; then
                error "E2E test uses wrong ProviderConfig API: $test_dir/main.k"
                echo "  → Use 'aws.m.upbound.io/v1beta1' (note the .m. suffix)"
                WRONG_API=$((WRONG_API + 1))
            fi
        fi
    done
fi

if [ $WRONG_API -eq 0 ]; then
    success "All ProviderConfigs use correct API version"
fi
echo ""

# =============================================================================
# CHECK 5: XRD matches architecture decision
# =============================================================================
echo "Check 5: Verifying XRD matches architecture decision..."

if [ -f "apis/vpc/definition.yaml" ]; then
    # Check XRD has correct kind
    if ! grep -q "kind: VPC" "apis/vpc/definition.yaml"; then
        error "XRD doesn't define 'kind: VPC' - check apis/vpc/definition.yaml"
    fi

    # Check XRD is namespaced
    if ! grep -q "scope: Namespaced" "apis/vpc/definition.yaml"; then
        error "XRD is not namespaced - check apis/vpc/definition.yaml"
    fi

    if [ $ERRORS -eq 0 ]; then
        success "XRD correctly defines namespaced VPC"
    fi
else
    warning "XRD not found at apis/vpc/definition.yaml"
fi
echo ""

# =============================================================================
# CHECK 6: Documentation consistency
# =============================================================================
echo "Check 6: Checking documentation consistency..."

# Check for XVPC references in KCL code examples (excluding warnings about NOT using XVPC)
if grep -r "XVPC" README.md CLAUDE.md TESTING.md 2>/dev/null | grep -v "e2etest-xvpc" | grep -v "test-xvpc" | grep -v "DO NOT use" | grep -v "not use" | grep -v "doesn't use" > /dev/null; then
    warning "Found XVPC references in documentation (check if these are intentional)"
    echo "  → Verify these are not showing XVPC as the kind to use"
fi

success "Documentation consistency check complete"
echo ""

# =============================================================================
# SUMMARY
# =============================================================================
echo "================================================"
echo "  Summary"
echo "================================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Documentation is consistent with XRD definition:"
    echo "  - kind: VPC (not XVPC)"
    echo "  - scope: Namespaced"
    echo "  - namespace: default required"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Review warnings above and fix if necessary."
    exit 0
else
    echo -e "${RED}❌ Failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Fix errors above before committing."
    echo ""
    echo "Quick fixes:"
    echo "  - Replace 'kind: XVPC' with 'kind: VPC'"
    echo "  - Add 'namespace: default' to all VPC resources"
    echo "  - Add 'namespace: default' to all ProviderConfigs"
    echo "  - Use 'aws.m.upbound.io/v1beta1' for ProviderConfig API"
    exit 1
fi
