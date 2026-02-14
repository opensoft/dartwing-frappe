#!/bin/bash
set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="del-workspace.sh"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Workspace Deletion Wrapper${NC}"
echo -e "${BLUE}Version: ${SCRIPT_VERSION}${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Load common utilities if available
if [ -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    source "${SCRIPT_DIR}/lib/common.sh"
fi

# Function to detect project type using AI or heuristics
detect_project_type() {
    echo -e "${BLUE}Detecting project type...${NC}" >&2
    
    # Check for Frappe indicators
    local frappe_indicators=0
    
    # Check for Frappe-specific files/folders
    [ -f "${PROJECT_ROOT}/setup.sh" ] && ((frappe_indicators++))
    [ -d "${PROJECT_ROOT}/scripts" ] && ((frappe_indicators++))
    [ -d "${PROJECT_ROOT}/devcontainer.example" ] && ((frappe_indicators++))
    [ -f "${PROJECT_ROOT}/scripts/init-bench.sh" ] && ((frappe_indicators+=2))
    
    # Check for documentation mentioning Frappe
    if [ -f "${PROJECT_ROOT}/README.md" ]; then
        grep -qi "frappe" "${PROJECT_ROOT}/README.md" && ((frappe_indicators+=2))
    fi
    
    if [ -d "${PROJECT_ROOT}/.warp" ]; then
        grep -qi "frappe" "${PROJECT_ROOT}/.warp/"*.md 2>/dev/null && ((frappe_indicators+=2))
    fi
    
    # Check for bench or frappe-bench directories
    [ -d "${PROJECT_ROOT}/workspaces/frappe-bench" ] && ((frappe_indicators+=3))
    [ -d "${PROJECT_ROOT}/bench" ] && ((frappe_indicators+=2))
    
    # Determine project type based on indicators
    if [ $frappe_indicators -ge 3 ]; then
        echo -e "${GREEN}✓ Detected: Frappe project (confidence: $frappe_indicators indicators)${NC}" >&2
        echo "frappe"
        return 0
    fi
    
    # If we can't detect, assume Frappe for now
    echo -e "${YELLOW}⚠ Could not automatically detect project type, assuming Frappe${NC}" >&2
    echo "frappe"
}

# Detect what type of project we're in
PROJECT_TYPE=$(detect_project_type)
echo ""

if [ "$PROJECT_TYPE" != "frappe" ]; then
    echo -e "${RED}Error: Currently only Frappe workspaces are supported${NC}"
    echo -e "${YELLOW}Detected type: ${PROJECT_TYPE}${NC}"
    exit 1
fi

# Delegate to the Frappe-specific deletion script
echo -e "${BLUE}Delegating to Frappe workspace deletion...${NC}"
echo ""

exec "${SCRIPT_DIR}/delete-frappe-workspace.sh" "$@"
