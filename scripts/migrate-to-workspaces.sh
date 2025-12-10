#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Migrate: development → workspaces"
echo -e "==========================================${NC}"
echo ""

# Check if development folder exists
if [ ! -d "development" ]; then
    echo -e "${YELLOW}No 'development' folder found. Nothing to migrate.${NC}"
    exit 0
fi

# Check if workspaces folder already exists
if [ -d "workspaces" ]; then
    echo -e "${RED}Error: 'workspaces' folder already exists!${NC}"
    echo -e "${YELLOW}Please manually resolve this before running migration.${NC}"
    exit 1
fi

echo -e "${BLUE}Found 'development' folder. Preparing to rename...${NC}"
echo ""

# Display what will be renamed
echo -e "${YELLOW}This will rename:${NC}"
echo -e "  ${BLUE}development/${NC} → ${GREEN}workspaces/${NC}"
echo ""

# Confirm with user
read -p "Continue with migration? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Migration cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}[1/3] Renaming folder...${NC}"
mv development workspaces
echo -e "${GREEN}  ✓ Renamed development → workspaces${NC}"
echo ""

echo -e "${BLUE}[2/3] Updating .env file (if exists)...${NC}"
if [ -f ".devcontainer/.env" ]; then
    sed -i 's|development/frappe-bench|workspaces/frappe-bench|g; s|/workspace/development/|/workspace/workspaces/|g' .devcontainer/.env
    echo -e "${GREEN}  ✓ Updated .devcontainer/.env${NC}"
else
    echo -e "${YELLOW}  → No .env file found, skipping${NC}"
fi
echo ""

echo -e "${BLUE}[3/3] Verifying migration...${NC}"
if [ -d "workspaces" ]; then
    echo -e "${GREEN}  ✓ workspaces folder exists${NC}"
    
    if [ -d "workspaces/frappe-bench" ]; then
        echo -e "${GREEN}  ✓ workspaces/frappe-bench exists${NC}"
    fi
    
    if [ -f "workspaces/.setup_complete" ]; then
        echo -e "${GREEN}  ✓ Setup marker preserved${NC}"
    fi
else
    echo -e "${RED}  ✗ Migration failed!${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}=========================================="
echo "Migration Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} If you have a container running, you should:"
echo -e "  1. Stop the current container"
echo -e "  2. Rebuild the container"
echo -e "  3. The container will now use the 'workspaces' folder"
echo ""
