#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse arguments
WORKSPACE_NAME="${1:-}"

# Validate workspace name provided
if [ -z "$WORKSPACE_NAME" ]; then
    echo -e "${RED}Error: Workspace name is required${NC}"
    echo ""
    echo -e "Usage: ${YELLOW}$0 <workspace-name>${NC}"
    echo ""
    echo "Example:"
    echo -e "  ${YELLOW}$0 bravo${NC}"
    echo ""
    exit 1
fi

echo -e "${BLUE}=========================================="
echo "Workspace Removal"
echo -e "==========================================${NC}"
echo ""

WORKSPACE_DIR="${PROJECT_ROOT}/workspaces/${WORKSPACE_NAME}"

# Check if workspace exists
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo -e "${RED}Error: Workspace '${WORKSPACE_NAME}' does not exist${NC}"
    echo -e "  Location checked: ${WORKSPACE_DIR}"
    echo ""
    exit 1
fi

# Display workspace info
echo -e "${BLUE}Workspace to remove:${NC}"
echo -e "  Name: ${YELLOW}${WORKSPACE_NAME}${NC}"
echo -e "  Location: ${YELLOW}${WORKSPACE_DIR}${NC}"
echo ""

# Check for uncommitted changes in frappe-app-dartwing
APP_DIR="${WORKSPACE_DIR}/bench/apps/dartwing"
HAS_UNCOMMITTED_CHANGES=false

if [ -d "$APP_DIR/.git" ]; then
    echo -e "${BLUE}Checking for uncommitted changes...${NC}"
    cd "$APP_DIR"
    
    # Get current branch
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "  Branch: ${BLUE}${BRANCH}${NC}"
    
    # Check for uncommitted changes (staged and unstaged)
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        HAS_UNCOMMITTED_CHANGES=true
        echo -e "  ${RED}⚠ WARNING: Uncommitted changes detected!${NC}"
        echo ""
        echo -e "${YELLOW}Uncommitted changes:${NC}"
        git status --short
        echo ""
    else
        echo -e "  ${GREEN}✓ No uncommitted changes${NC}"
        
        # Check if in sync with remote
        git fetch --quiet 2>/dev/null || true
        LOCAL=$(git rev-parse @ 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
        
        if [ "$LOCAL" = "$REMOTE" ]; then
            echo -e "  ${GREEN}✓ In sync with remote${NC}"
        elif [ -z "$REMOTE" ]; then
            echo -e "  ${YELLOW}⚠ No upstream branch set${NC}"
        else
            echo -e "  ${YELLOW}⚠ Local commits not pushed to remote${NC}"
            HAS_UNCOMMITTED_CHANGES=true
        fi
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
fi

# Confirm deletion
if [ "$HAS_UNCOMMITTED_CHANGES" = true ]; then
    echo -e "${RED}==========================================${NC}"
    echo -e "${RED}CRITICAL WARNING${NC}"
    echo -e "${RED}==========================================${NC}"
    echo -e "${RED}This workspace has uncommitted or unpushed changes!${NC}"
    echo -e "${RED}Deleting now will result in PERMANENT DATA LOSS.${NC}"
    echo -e "${RED}==========================================${NC}"
    echo ""
fi

echo -e "${YELLOW}WARNING: This will permanently delete the entire workspace directory!${NC}"
echo -e "${RED}This action cannot be undone.${NC}"
echo ""
read -p "Are you sure you want to delete workspace '${WORKSPACE_NAME}'? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${BLUE}Deletion cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Removing workspace...${NC}"

# Remove the workspace directory
rm -rf "$WORKSPACE_DIR"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Workspace '${WORKSPACE_NAME}' successfully removed${NC}"
else
    echo -e "${RED}✗ Failed to remove workspace${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Workspace Removed!"
echo -e "==========================================${NC}"
echo ""
