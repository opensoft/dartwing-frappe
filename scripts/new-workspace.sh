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

# NATO phonetic alphabet for workspace naming
NATO_ALPHABET=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu)

# Function to get next workspace name
get_next_workspace_name() {
    local project_root="$1"
    local workspaces_dir="${project_root}/workspaces"
    
    # If no workspaces exist, return first name
    if [ ! -d "$workspaces_dir" ] || [ -z "$(ls -A "$workspaces_dir" 2>/dev/null)" ]; then
        echo "${NATO_ALPHABET[0]}"
        return
    fi
    
    # Find all NATO phonetic workspace names
    local existing_workspaces=()
    for dir in "${workspaces_dir}"/*; do
        if [ -d "$dir" ]; then
            local basename=$(basename "$dir")
            # Check if it's a NATO phonetic name
            for nato_name in "${NATO_ALPHABET[@]}"; do
                if [ "$basename" = "$nato_name" ]; then
                    existing_workspaces+=("$basename")
                    break
                fi
            done
        fi
    done
    
    # Find the last NATO name in sequence
    local last_index=-1
    for i in "${!NATO_ALPHABET[@]}"; do
        local nato_name="${NATO_ALPHABET[$i]}"
        for existing in "${existing_workspaces[@]}"; do
            if [ "$existing" = "$nato_name" ]; then
                last_index=$i
            fi
        done
    done
    
    # Return next name in sequence
    local next_index=$((last_index + 1))
    if [ $next_index -lt ${#NATO_ALPHABET[@]} ]; then
        echo "${NATO_ALPHABET[$next_index]}"
    else
        echo -e "${RED}Error: All NATO phonetic names exhausted!${NC}" >&2
        return 1
    fi
}

# Determine project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse arguments
WORKSPACE_NAME="${1:-}"

# If no workspace name provided, auto-detect next one
if [ -z "$WORKSPACE_NAME" ]; then
    WORKSPACE_NAME=$(get_next_workspace_name "$PROJECT_ROOT")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo -e "${BLUE}No workspace name provided, auto-detected next: ${YELLOW}${WORKSPACE_NAME}${NC}"
    echo ""
fi

echo -e "${BLUE}=========================================="
echo "New Workspace Creator"
echo -e "==========================================${NC}"
echo ""

NEW_DIR="${PROJECT_ROOT}/workspaces/${WORKSPACE_NAME}"

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Workspace name: ${WORKSPACE_NAME}"
echo -e "  New directory: ${NEW_DIR}"
echo ""

# Step 1: Create new workspace subdirectory
echo -e "${BLUE}[1/4] Creating new workspace directory...${NC}"
if [ -d "$NEW_DIR" ]; then
    echo -e "${RED}  ✗ Directory ${NEW_DIR} already exists!${NC}"
    exit 1
fi

mkdir -p "${NEW_DIR}/bench/apps"
mkdir -p "${NEW_DIR}/scripts"
echo -e "${GREEN}  ✓ Workspace directory created${NC}"
echo ""

# Step 2: Copy devcontainer template
echo -e "${BLUE}[2/4] Setting up devcontainer configuration...${NC}"
if [ ! -d "${PROJECT_ROOT}/devcontainer.example" ]; then
    echo -e "${RED}  ✗ devcontainer.example folder not found!${NC}"
    exit 1
fi

cp -r "${PROJECT_ROOT}/devcontainer.example" "${NEW_DIR}/.devcontainer"
# Link workspace scripts to shared versions in repo (mounted at /repo in container)
ln -s "/repo/scripts/init-bench.sh" "${NEW_DIR}/scripts/init-bench.sh"
ln -s "/repo/scripts/setup-workspace.sh" "${NEW_DIR}/scripts/setup-workspace.sh"
echo -e "${GREEN}  ✓ Devcontainer template copied${NC}"
echo -e "${GREEN}  ✓ Init bench script linked${NC}"
echo -e "${GREEN}  ✓ Setup workspace script linked${NC}"

# Calculate unique port based on NATO alphabet index for sequential assignment
BASE_PORT=8201
# Find the index of workspace name in NATO alphabet
NATO_INDEX=-1
for i in "${!NATO_ALPHABET[@]}"; do
    if [ "${NATO_ALPHABET[$i]}" = "$WORKSPACE_NAME" ]; then
        NATO_INDEX=$i
        break
    fi
done

if [ $NATO_INDEX -eq -1 ]; then
    # Not a NATO name, fall back to hash-based port
    echo -e "${YELLOW}  → Custom workspace name, using hash-based port${NC}"
    PORT_OFFSET=$(echo -n "$WORKSPACE_NAME" | cksum | cut -d' ' -f1)
    HOST_PORT=$((BASE_PORT + (PORT_OFFSET % 50)))
else
    # Sequential port based on NATO index (alpha=8201, bravo=8202, etc.)
    HOST_PORT=$((BASE_PORT + NATO_INDEX))
fi

# Update .devcontainer/.env with workspace-specific settings
cat > "${NEW_DIR}/.devcontainer/.env" << EOF
# Workspace: ${WORKSPACE_NAME}
CODENAME=${WORKSPACE_NAME}
CONTAINER_NAME=dartwing-frappe-${WORKSPACE_NAME}
COMPOSE_PROJECT_NAME=dartwing-frappe-${WORKSPACE_NAME}
HOST_PORT=${HOST_PORT}

# User configuration
USER=${USER}
UID=${UID}
GID=${GID}

# Database configuration (uses existing frappe-mariadb container)
DB_HOST=frappe-mariadb
DB_PORT=3306
DB_PASSWORD=frappe
DB_NAME=dartwing_${WORKSPACE_NAME}

# Redis configuration (uses existing frappe redis containers)
REDIS_CACHE=frappe-redis-cache:6379
REDIS_QUEUE=frappe-redis-queue:6379
REDIS_SOCKETIO=frappe-redis-socketio:6379

# Frappe site configuration
SITE_NAME=${WORKSPACE_NAME}.localhost
ADMIN_PASSWORD=admin

# App configuration
APP_BRANCH=main

# Bench configuration
FRAPPE_BENCH_PATH=/workspace/bench
EOF
echo -e "${GREEN}  ✓ Devcontainer environment configured${NC}"
echo -e "${YELLOW}  → Container: dartwing-frappe-${WORKSPACE_NAME}${NC}"
echo -e "${YELLOW}  → Port: ${HOST_PORT}${NC}"
echo ""

# Step 3: Update devcontainer.json name
echo -e "${BLUE}[3/4] Customizing devcontainer settings...${NC}"
sed -i "s/WORKSPACE_NAME/${WORKSPACE_NAME}/g" "${NEW_DIR}/.devcontainer/devcontainer.json"
echo -e "${GREEN}  ✓ Devcontainer name updated${NC}"
echo ""

# Step 4: Clone frappe-app-dartwing
echo -e "${BLUE}[4/4] Cloning frappe-app-dartwing...${NC}"
if [ ! -d "${NEW_DIR}/bench/apps/dartwing" ]; then
    echo -e "${YELLOW}  → Cloning from GitHub...${NC}"
    git clone "$APP_REPO" "${NEW_DIR}/bench/apps/dartwing"
    echo -e "${GREEN}  ✓ dartwing app cloned${NC}"
else
    echo -e "${YELLOW}  → dartwing app already exists, skipping${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "New Workspace Created!"
echo -e "==========================================${NC}"
echo ""
echo -e "Workspace Details:"
echo -e "  Name: ${BLUE}${WORKSPACE_NAME}${NC}"
echo -e "  Location: ${BLUE}${NEW_DIR}${NC}"
echo -e "  Bench: ${BLUE}${NEW_DIR}/bench${NC}"
echo -e "  Container: ${BLUE}dartwing-frappe-${WORKSPACE_NAME}${NC}"
echo -e "  Port: ${BLUE}${HOST_PORT}${NC}"
echo ""
echo -e "Next Steps:"
echo -e "  1. ${YELLOW}cd ${NEW_DIR}${NC}"
echo -e "  2. ${YELLOW}code .${NC} (open workspace in VSCode)"
echo -e "  3. Click ${YELLOW}'Reopen in Container'${NC} when prompted"
echo -e "  4. Access at: ${YELLOW}http://localhost:${HOST_PORT}${NC}"
echo ""
