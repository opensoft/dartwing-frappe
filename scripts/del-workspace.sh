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

# Confirm deletion
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
