#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
FRAPPE_REPO="git@github.com:opensoft/dartwing-frappe.git"
APP_REPO="git@github.com:opensoft/frappe-app-dartwing.git"

# Parse arguments
BRANCH_NAME="${1:-}"

if [ -z "$BRANCH_NAME" ]; then
    echo -e "${RED}Error: Branch name required${NC}"
    echo -e "Usage: $0 <branch-name>"
    echo -e "Example: $0 alpha"
    exit 1
fi

echo -e "${BLUE}=========================================="
echo "New Branch Workspace Creator"
echo -e "==========================================${NC}"
echo ""

# Get parent directory (dartwing/)
PARENT_DIR=$(dirname "$(pwd)")
NEW_DIR="${PARENT_DIR}/${BRANCH_NAME}-frappe"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Branch name: ${BRANCH_NAME}"
echo -e "  New directory: ${NEW_DIR}"
echo ""

# Step 1: Create new folder
echo -e "${BLUE}[1/5] Creating new workspace directory...${NC}"
if [ -d "$NEW_DIR" ]; then
    echo -e "${RED}  ✗ Directory ${NEW_DIR} already exists!${NC}"
    exit 1
fi

mkdir -p "$NEW_DIR"
echo -e "${GREEN}  ✓ Directory created${NC}"
echo ""

# Step 2: Clone dartwing-frappe
echo -e "${BLUE}[2/5] Cloning dartwing-frappe repository...${NC}"
git clone "$FRAPPE_REPO" "$NEW_DIR"
echo -e "${GREEN}  ✓ Repository cloned${NC}"
echo ""

# Step 3: Create .env file from example
echo -e "${BLUE}[3/5] Creating .env file...${NC}"
cd "$NEW_DIR"
if [ -f ".devcontainer/.env.example" ]; then
    cp .devcontainer/.env.example .devcontainer/.env
    
    # Update CODENAME in .env
    sed -i "s/^CODENAME=.*/CODENAME=${BRANCH_NAME}/" .devcontainer/.env
    
    echo -e "${GREEN}  ✓ .env file created and configured${NC}"
else
    echo -e "${RED}  ✗ .env.example not found!${NC}"
    exit 1
fi
echo ""

# Step 4: Create folder structure and ensure it exists
echo -e "${BLUE}[4/5] Creating folder structure...${NC}"
mkdir -p development/frappe-bench/apps
echo -e "${GREEN}  ✓ Created development/frappe-bench/apps/${NC}"
echo ""

# Step 5: Clone frappe-app-dartwing
echo -e "${BLUE}[5/5] Cloning frappe-app-dartwing...${NC}"
if [ ! -d "development/frappe-bench/apps/frappe-app-dartwing" ]; then
    echo -e "${YELLOW}  → Cloning from GitHub...${NC}"
    git clone "$APP_REPO" development/frappe-bench/apps/frappe-app-dartwing
    echo -e "${GREEN}  ✓ frappe-app-dartwing cloned${NC}"
else
    echo -e "${YELLOW}  → frappe-app-dartwing already exists, skipping${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "New Branch Workspace Created!"
echo -e "==========================================${NC}"
echo ""
echo -e "Workspace Details:"
echo -e "  Name: ${BLUE}${BRANCH_NAME}-frappe${NC}"
echo -e "  Location: ${BLUE}${NEW_DIR}${NC}"
echo ""
echo -e "Next Steps:"
echo -e "  1. ${YELLOW}cd ${NEW_DIR}${NC}"
echo -e "  2. ${YELLOW}code .${NC} (or open in VS Code)"
echo -e "  3. ${YELLOW}Click 'Reopen in Container' when prompted${NC}"
echo -e "  4. ${YELLOW}Wait for automatic bench initialization${NC}"
echo ""
