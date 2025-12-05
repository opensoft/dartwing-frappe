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

# Step 1: Create .env file from example
echo -e "${BLUE}[1/3] Creating .env file...${NC}"
if [ ! -f ".devcontainer/.env" ]; then
    if [ -f ".devcontainer/.env.example" ]; then
        cp .devcontainer/.env.example .devcontainer/.env
        echo -e "${GREEN}  ✓ .env file created from .env.example${NC}"
    else
        echo -e "${RED}  ✗ .env.example not found!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}  → .env file already exists, skipping${NC}"
fi
echo ""

# Step 2: Create folder structure
echo -e "${BLUE}[2/3] Creating folder structure...${NC}"
mkdir -p development/frappe-bench/apps
echo -e "${GREEN}  ✓ Created development/frappe-bench/apps/${NC}"
echo ""

# Step 3: Clone frappe-app-dartwing
echo -e "${BLUE}[3/3] Cloning frappe-app-dartwing...${NC}"
if [ ! -d "development/frappe-bench/apps/frappe-app-dartwing" ]; then
    echo -e "${YELLOW}  → Cloning from GitHub...${NC}"
    git clone git@github.com:opensoft/frappe-app-dartwing.git development/frappe-bench/apps/frappe-app-dartwing
    echo -e "${GREEN}  ✓ frappe-app-dartwing cloned${NC}"
else
    echo -e "${YELLOW}  → frappe-app-dartwing already exists, skipping${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "Next Steps:"
echo -e "  1. ${YELLOW}Open this folder in VS Code${NC}"
echo -e "  2. ${YELLOW}Click 'Reopen in Container' when prompted${NC}"
echo -e "  3. ${YELLOW}Wait for automatic bench initialization${NC}"
echo ""
