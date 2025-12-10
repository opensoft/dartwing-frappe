#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Dartwing Frappe - Initial Setup"
echo -e "==========================================${NC}"
echo ""
echo -e "This script will create the default 'alpha' workspace"
echo -e "with its own devcontainer configuration."
echo ""

# Get script directory (script is now in project root)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts"

# Step 1: Check prerequisites
echo -e "${BLUE}[1/3] Checking prerequisites...${NC}"

# Check if devcontainer.example exists
if [ ! -d "${PROJECT_ROOT}/devcontainer.example" ]; then
    echo -e "${RED}  ✗ devcontainer.example folder not found!${NC}"
    echo -e "${YELLOW}  This template is needed to create workspaces.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ devcontainer.example found${NC}"

# Check if new-workspace.sh exists
if [ ! -f "${SCRIPT_DIR}/new-workspace.sh" ]; then
    echo -e "${RED}  ✗ new-workspace.sh script not found!${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ new-workspace.sh found${NC}"
echo ""

# Step 2: Ensure workspaces folder exists
echo -e "${BLUE}[2/3] Checking workspaces directory...${NC}"
if [ ! -d "${PROJECT_ROOT}/workspaces" ]; then
    mkdir -p "${PROJECT_ROOT}/workspaces"
    echo -e "${GREEN}  ✓ Created workspaces directory${NC}"
else
    echo -e "${YELLOW}  → workspaces directory already exists${NC}"
fi
echo ""

# Step 3: Create alpha workspace if it doesn't exist
echo -e "${BLUE}[3/3] Checking alpha workspace...${NC}"
if [ ! -d "${PROJECT_ROOT}/workspaces/alpha" ] || [ ! -d "${PROJECT_ROOT}/workspaces/alpha/.devcontainer" ]; then
    if [ -d "${PROJECT_ROOT}/workspaces/alpha" ]; then
        echo -e "${YELLOW}  → Incomplete alpha workspace found, recreating...${NC}"
        rm -rf "${PROJECT_ROOT}/workspaces/alpha"
    fi
    
    echo -e "${YELLOW}  → Creating alpha workspace...${NC}"
    cd "${PROJECT_ROOT}"
    "${SCRIPT_DIR}/new-workspace.sh" alpha
    echo -e "${GREEN}  ✓ Alpha workspace created${NC}"
else
    echo -e "${YELLOW}  → Alpha workspace already exists${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "Workspace created at: ${BLUE}workspaces/alpha${NC}"
echo ""
echo -e "Next Steps:"
echo -e "  1. ${YELLOW}cd workspaces/alpha${NC}"
echo -e "  2. ${YELLOW}code .${NC} (open workspace in VSCode)"
echo -e "  3. Click ${YELLOW}'Reopen in Container'${NC} when prompted"
echo -e "  4. Wait for automatic bench initialization"
echo ""
echo -e "To create additional workspaces:"
echo -e "  ${YELLOW}./scripts/new-workspace.sh bravo${NC}"
echo -e "  ${YELLOW}./scripts/new-workspace.sh charlie${NC}"
echo ""
