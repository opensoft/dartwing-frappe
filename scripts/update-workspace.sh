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
TARGET="${1:--all}"

echo -e "${BLUE}=========================================="
echo "Workspace Updater"
echo -e "==========================================${NC}"
echo ""

# Function to update a single workspace
update_single_workspace() {
    local workspace_name="$1"
    local workspace_dir="${PROJECT_ROOT}/workspaces/${workspace_name}"
    
    # Validate workspace exists
    if [ ! -d "$workspace_dir" ]; then
        echo -e "${RED}  ✗ Workspace directory ${workspace_dir} not found!${NC}"
        return 1
    fi
    
    # Validate .devcontainer exists (it should, but check anyway)
    if [ ! -d "${workspace_dir}/.devcontainer" ]; then
        echo -e "${RED}  ✗ .devcontainer directory not found in ${workspace_dir}!${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating workspace: ${YELLOW}${workspace_name}${NC}"
    
    # Step 1: Backup current .env if it exists (preserve custom settings)
    if [ -f "${workspace_dir}/.devcontainer/.env" ]; then
        cp "${workspace_dir}/.devcontainer/.env" "${workspace_dir}/.devcontainer/.env.backup"
        echo -e "${GREEN}  ✓ .env backed up to .env.backup${NC}"
    fi
    
    # Step 2: Copy updated devcontainer files from example (preserves .env and .env.backup)
    echo -e "${BLUE}  [1/3] Updating devcontainer configuration...${NC}"
    
    # Copy all files except .env (which we want to preserve)
    for file in "${PROJECT_ROOT}/devcontainer.example"/*; do
        filename=$(basename "$file")
        # Skip .env files as we preserve those
        if [[ "$filename" != ".env" ]]; then
            if [ -d "$file" ]; then
                # For directories, remove old and copy new
                rm -rf "${workspace_dir}/.devcontainer/${filename}"
                cp -r "$file" "${workspace_dir}/.devcontainer/${filename}"
            else
                # For files, just copy
                cp "$file" "${workspace_dir}/.devcontainer/${filename}"
            fi
        fi
    done
    echo -e "${GREEN}  ✓ Devcontainer files updated${NC}"
    
    # Step 3: Preserve and reapply .env settings
    echo -e "${BLUE}  [2/3] Preserving workspace environment configuration...${NC}"
    
    if [ -f "${workspace_dir}/.devcontainer/.env.backup" ]; then
        # Extract workspace name from existing .env to validate it
        existing_codename=$(grep "^CODENAME=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_container=$(grep "^CONTAINER_NAME=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_project=$(grep "^COMPOSE_PROJECT_NAME=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_port=$(grep "^HOST_PORT=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_user=$(grep "^USER=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_uid=$(grep "^UID=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_gid=$(grep "^GID=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_db_name=$(grep "^DB_NAME=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        existing_site=$(grep "^SITE_NAME=" "${workspace_dir}/.devcontainer/.env.backup" | cut -d= -f2)
        
        # Recreate .env with existing settings
        cat > "${workspace_dir}/.devcontainer/.env" << EOF
# Workspace: ${existing_codename}
CODENAME=${existing_codename}
CONTAINER_NAME=${existing_container}
COMPOSE_PROJECT_NAME=${existing_project}
HOST_PORT=${existing_port}

# User configuration
USER=${existing_user}
UID=${existing_uid}
GID=${existing_gid}

# Database configuration (uses existing frappe-mariadb container)
DB_HOST=frappe-mariadb
DB_PORT=3306
DB_PASSWORD=frappe
DB_NAME=${existing_db_name}

# Redis configuration (uses existing frappe redis containers)
REDIS_CACHE=frappe-redis-cache:6379
REDIS_QUEUE=frappe-redis-queue:6379
REDIS_SOCKETIO=frappe-redis-socketio:6379

# Frappe site configuration
SITE_NAME=${existing_site}
ADMIN_PASSWORD=admin

# App configuration
APP_BRANCH=main

# Bench configuration
FRAPPE_BENCH_PATH=/workspace/bench
EOF
        echo -e "${GREEN}  ✓ Environment configuration preserved${NC}"
        
        # Clean up backup
        rm "${workspace_dir}/.devcontainer/.env.backup"
    fi
    
    # Step 4: Update devcontainer.json name with workspace name
    echo -e "${BLUE}  [3/3] Customizing devcontainer settings...${NC}"
    if [ -f "${workspace_dir}/.devcontainer/devcontainer.json" ]; then
        sed -i "s/WORKSPACE_NAME/${workspace_name}/g" "${workspace_dir}/.devcontainer/devcontainer.json"
        echo -e "${GREEN}  ✓ Devcontainer name updated${NC}"
    fi
    
    echo -e "${GREEN}  ✓ Workspace ${workspace_name} updated successfully${NC}"
    echo ""
    return 0
}

# Main logic
if [ "$TARGET" = "-all" ]; then
    # Update all workspaces
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Target: ${YELLOW}all workspaces${NC}"
    echo ""
    
    workspaces_dir="${PROJECT_ROOT}/workspaces"
    
    if [ ! -d "$workspaces_dir" ] || [ -z "$(ls -A "$workspaces_dir" 2>/dev/null)" ]; then
        echo -e "${RED}No workspaces found in ${workspaces_dir}!${NC}"
        exit 1
    fi
    
    failed_count=0
    success_count=0
    
    for workspace_dir in "${workspaces_dir}"/*; do
        if [ -d "$workspace_dir" ]; then
            workspace_name=$(basename "$workspace_dir")
            if update_single_workspace "$workspace_name"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
        fi
    done
    
    echo -e "${BLUE}=========================================="
    echo "Update Complete!"
    echo -e "==========================================${NC}"
    echo ""
    echo -e "Results:"
    echo -e "  Successful: ${GREEN}${success_count}${NC}"
    if [ $failed_count -gt 0 ]; then
        echo -e "  Failed: ${RED}${failed_count}${NC}"
        exit 1
    fi
else
    # Update specific workspace
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Target: ${YELLOW}${TARGET}${NC}"
    echo ""
    
    if update_single_workspace "$TARGET"; then
        echo -e "${BLUE}=========================================="
        echo "Workspace Updated!"
        echo -e "==========================================${NC}"
        echo ""
        echo -e "Workspace Details:"
        echo -e "  Name: ${BLUE}${TARGET}${NC}"
        echo -e "  Location: ${BLUE}${PROJECT_ROOT}/workspaces/${TARGET}${NC}"
        echo ""
        echo -e "Next Steps:"
        echo -e "  1. Rebuild the container: ${YELLOW}docker-compose rebuild${NC}"
        echo -e "  2. Reopen in container in VSCode"
        echo ""
    else
        exit 1
    fi
fi
