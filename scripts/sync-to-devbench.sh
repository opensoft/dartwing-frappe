#!/bin/bash
# Synchronize workspace scripts to frappeBench devBench repository
# This keeps both repositories in sync for users who only clone one

set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="sync-to-devbench.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Log functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

die() {
    log_error "$*"
    exit 1
}

# Determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DARTWING_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVBENCH_REPO="${DARTWING_REPO%/projects/*}/workBenches/devBenches/frappeBench"

echo ""
echo -e "${BLUE}=========================================="
echo "Workspace Scripts Synchronizer (v${SCRIPT_VERSION})"
echo -e "==========================================${NC}"
echo ""

log_info "Configuration:"
log_info "  Source: ${DARTWING_REPO}/scripts"
log_info "  Target: ${DEVBENCH_REPO}/scripts"
echo ""

# Validate source exists
if [ ! -d "${DARTWING_REPO}/scripts" ]; then
    die "Source scripts directory not found: ${DARTWING_REPO}/scripts"
fi

# Validate target exists
if [ ! -d "$DEVBENCH_REPO" ]; then
    die "Target devBench repository not found: ${DEVBENCH_REPO}"
fi

# Define files to sync
declare -a MAIN_SCRIPTS=("new-workspace.sh" "update-workspace.sh" "delete-workspace.sh")
declare -a LIB_SCRIPTS=("common.sh" "git-project.sh" "ai-provider.sh" "ai-assistant.sh")

# Function to check if files are identical
files_identical() {
    local src="$1"
    local dst="$2"
    
    if [ ! -f "$dst" ]; then
        return 1
    fi
    
    if cmp -s "$src" "$dst"; then
        return 0
    else
        return 1
    fi
}

# Function to get version from script
get_script_version() {
    local file="$1"
    grep -E "SCRIPT_VERSION|Version:" "$file" 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown"
}

# Sync main scripts
log_info "Syncing main scripts..."
local_changes=0

for script in "${MAIN_SCRIPTS[@]}"; do
    src="${DARTWING_REPO}/scripts/${script}"
    dst="${DEVBENCH_REPO}/scripts/${script}"
    
    if [ ! -f "$src" ]; then
        log_warn "Source not found: $script"
        continue
    fi
    
    if files_identical "$src" "$dst"; then
        log_success "  ✓ $script (in sync)"
    else
        version=$(get_script_version "$src")
        log_warn "  ⟳ $script (v${version} - needs sync)"
        cp "$src" "$dst"
        ((local_changes++))
    fi
done

# Sync library scripts
log_info "Syncing library scripts..."

for script in "${LIB_SCRIPTS[@]}"; do
    src="${DARTWING_REPO}/scripts/lib/${script}"
    dst="${DEVBENCH_REPO}/scripts/lib/${script}"
    
    if [ ! -f "$src" ]; then
        log_warn "Source not found: lib/$script"
        continue
    fi
    
    if files_identical "$src" "$dst"; then
        log_success "  ✓ $script (in sync)"
    else
        version=$(get_script_version "$src")
        log_warn "  ⟳ $script (v${version} - needs sync)"
        cp "$src" "$dst"
        ((local_changes++))
    fi
done

echo ""

if [ $local_changes -eq 0 ]; then
    log_success "All scripts are in sync!"
    echo ""
    exit 0
fi

echo ""
log_warn "Updated $local_changes files"
echo ""

# Ask to commit and push
echo -ne "${YELLOW}Commit and push to frappeBench repo? [y/N]: ${NC}"
read -r response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    log_info "Sync complete, skipping git operations"
    exit 0
fi

# Commit in devBench repo
cd "$DEVBENCH_REPO"
git add scripts/
git commit -m "Sync workspace scripts from dartwing-frappe

- Updated $(echo "${MAIN_SCRIPTS[@]}" | tr ' ' ',')
- Updated lib/$(echo "${LIB_SCRIPTS[@]}" | tr ' ' ',')"

log_success "Committed to frappeBench"

# Push if possible
if git push 2>/dev/null; then
    log_success "Pushed to remote"
else
    log_warn "Failed to push (may not have remote or may require authentication)"
fi

echo ""
log_success "Synchronization complete!"
echo ""
