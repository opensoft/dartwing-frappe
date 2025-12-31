#!/bin/bash
set -e

# Script metadata
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="new-workspace.sh"

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
echo -e "${BLUE}Intelligent Workspace Creator${NC}"
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
    
    # Try to use Warp AI to detect if running within Warp
    # This would be called automatically by Warp's AI when the script runs
    local ai_suggestion=""
    
    # Determine project type based on indicators
    if [ $frappe_indicators -ge 3 ]; then
        echo -e "${GREEN}✓ Detected: Frappe project (confidence: $frappe_indicators indicators)${NC}" >&2
        echo "frappe"
        return 0
    fi
    
    # If we can't detect, ask the user
    echo -e "${YELLOW}⚠ Could not automatically detect project type${NC}" >&2
    echo -e "${YELLOW}Please specify what type of workspace to create:${NC}" >&2
    echo -e "  1) Frappe" >&2
    echo -e "  2) Flutter" >&2
    echo -e "  3) Django" >&2
    echo -e "  4) Other" >&2
    read -p "Select type (1-4): " choice
    
    case $choice in
        1) echo "frappe" ;;
        2) echo "flutter" ;;
        3) echo "django" ;;
        *) echo "unknown" ;;
    esac
}

# Detect what type of project we're in
PROJECT_TYPE=$(detect_project_type)
echo ""

if [ "$PROJECT_TYPE" != "frappe" ]; then
    echo -e "${RED}Error: Currently only Frappe workspaces are supported${NC}"
    echo -e "${YELLOW}Detected type: ${PROJECT_TYPE}${NC}"
    exit 1
fi

# Function to detect next available NATO codename
get_next_codename() {
    local nato_alphabet=("alpha" "bravo" "charlie" "delta" "echo" "foxtrot" "golf" "hotel" "india" "juliet" "kilo" "lima" "mike" "november" "oscar" "papa" "quebec" "romeo" "sierra" "tango" "uniform" "victor" "whiskey" "xray" "yankee" "zulu")
    
    # Get existing workspace names
    local existing=()
    if [ -d "${PROJECT_ROOT}/workspaces" ]; then
        for dir in "${PROJECT_ROOT}/workspaces"/*; do
            if [ -d "$dir" ] && [ "$(basename "$dir")" != ".backups" ]; then
                existing+=("$(basename "$dir")")
            fi
        done
    fi
    
    # Find first unused codename
    for name in "${nato_alphabet[@]}"; do
        if [[ ! " ${existing[@]} " =~ " ${name} " ]]; then
            echo "$name"
            return 0
        fi
    done
    
    # All NATO names used, generate numbered name
    local counter=1
    while true; do
        local name="workspace${counter}"
        if [[ ! " ${existing[@]} " =~ " ${name} " ]]; then
            echo "$name"
            return 0
        fi
        ((counter++))
    done
}

# Function to get next available port
get_next_port() {
    local base_port=8001
    local max_port=8100
    
    # Get existing ports
    local existing_ports=()
    if [ -d "${PROJECT_ROOT}/workspaces" ]; then
        for env_file in "${PROJECT_ROOT}/workspaces"/*/.env; do
            if [ -f "$env_file" ]; then
                local port=$(grep '^HOST_PORT=' "$env_file" | cut -d'=' -f2)
                if [ -n "$port" ]; then
                    existing_ports+=("$port")
                fi
            fi
        done
    fi
    
    # Find first available port
    for ((port=base_port; port<=max_port; port++)); do
        if [[ ! " ${existing_ports[@]} " =~ " ${port} " ]]; then
            echo "$port"
            return 0
        fi
    done
    
    echo "$base_port"
}

# Parse arguments
WORKSPACE_NAME="$1"

# If no workspace name provided, auto-detect next available
if [ -z "$WORKSPACE_NAME" ]; then
    WORKSPACE_NAME=$(get_next_codename)
    echo -e "${YELLOW}No workspace name provided${NC}"
    echo -e "${BLUE}Auto-detected next available: ${WORKSPACE_NAME}${NC}"
    echo ""
fi

# Validate workspace name
if [[ ! "$WORKSPACE_NAME" =~ ^[a-z0-9_-]+$ ]]; then
    echo -e "${RED}Error: Workspace name must contain only lowercase letters, numbers, hyphens, and underscores${NC}"
    exit 1
fi

# Check if workspace already exists
WORKSPACE_DIR="${PROJECT_ROOT}/workspaces/${WORKSPACE_NAME}"
if [ -d "$WORKSPACE_DIR" ]; then
    echo -e "${RED}Error: Workspace '${WORKSPACE_NAME}' already exists${NC}"
    exit 1
fi

# Get next available port
HOST_PORT=$(get_next_port)

echo -e "${BLUE}Creating Frappe workspace: ${WORKSPACE_NAME}${NC}"
echo -e "${BLUE}  Port: ${HOST_PORT}${NC}"
echo -e "${BLUE}  Site: ${WORKSPACE_NAME}.localhost${NC}"
echo -e "${BLUE}  Database: dartwing_${WORKSPACE_NAME}${NC}"
echo ""

# Create workspace directory structure
echo -e "${BLUE}[1/5] Creating directory structure...${NC}"
mkdir -p "${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_DIR}/.devcontainer"
mkdir -p "${WORKSPACE_DIR}/bench/apps"
echo -e "${GREEN}  ✓ Directories created${NC}"
echo ""

# Copy devcontainer template
echo -e "${BLUE}[2/5] Copying devcontainer template...${NC}"
if [ ! -d "${PROJECT_ROOT}/devcontainer.example" ]; then
    echo -e "${RED}  ✗ devcontainer.example not found${NC}"
    exit 1
fi

# Use -L to dereference symlinks and copy actual files
cp -rL "${PROJECT_ROOT}/devcontainer.example"/* "${WORKSPACE_DIR}/.devcontainer/"
echo -e "${GREEN}  ✓ Template copied (symlinks dereferenced)${NC}"

# Update docker-compose.yml to use pre-built image instead of building
if [ -f "${WORKSPACE_DIR}/.devcontainer/docker-compose.yml" ]; then
    # Replace build section with image reference
    sed -i '/^    build:/,/^        USER_GID:/c\    image: frappe-bench:'"${USER}" "${WORKSPACE_DIR}/.devcontainer/docker-compose.yml"
    echo -e "${GREEN}  ✓ Configured to use pre-built image (frappe-bench:${USER})${NC}"
fi

# Create .env symlink in .devcontainer for docker compose
ln -sf ../.env "${WORKSPACE_DIR}/.devcontainer/.env"
echo -e "${GREEN}  ✓ Created .env symlink for docker compose${NC}"
echo ""

# Clone the dartwing app
echo -e "${BLUE}[3/5] Cloning dartwing app...${NC}"
if [ -d "${WORKSPACE_DIR}/bench/apps/dartwing" ]; then
    echo -e "${YELLOW}  → App already exists, skipping${NC}"
else
    cd "${WORKSPACE_DIR}/bench/apps"
    if git clone https://github.com/opensoft/frappe-app-dartwing.git dartwing 2>/dev/null; then
        echo -e "${GREEN}  ✓ App cloned successfully${NC}"
    else
        echo -e "${YELLOW}  ⚠ Could not clone app (may need SSH keys)${NC}"
        echo -e "${YELLOW}  → App will be installed during container initialization${NC}"
    fi
    cd "${PROJECT_ROOT}"
fi
echo ""

# Create .env file
echo -e "${BLUE}[4/5] Creating workspace configuration...${NC}"
cat > "${WORKSPACE_DIR}/.env" << EOF
# Workspace: ${WORKSPACE_NAME}
# Frappe Bench Workspace Configuration

# Workspace identity
CODENAME=${WORKSPACE_NAME}
CONTAINER_NAME=frappe-${WORKSPACE_NAME}
COMPOSE_PROJECT_NAME=frappe-${WORKSPACE_NAME}
HOST_PORT=${HOST_PORT}

# User configuration (matches host user)
USER=${USER}
UID=$(id -u)
GID=$(id -g)

# Frappe Bench configuration
FRAPPE_BENCH_PATH=bench
SITE_NAME=${WORKSPACE_NAME}.localhost
DB_NAME=dartwing_${WORKSPACE_NAME}
DB_HOST=frappe-mariadb
DB_PORT=3306
DB_ROOT_PASSWORD=frappe
ADMIN_PASSWORD=admin

# Redis configuration (shared infrastructure)
REDIS_CACHE=redis://frappe-redis-cache:6379
REDIS_QUEUE=redis://frappe-redis-queue:6379
REDIS_SOCKETIO=redis://frappe-redis-socketio:6379

# Apps to install
APPS_TO_INSTALL=dartwing
EOF
echo -e "${GREEN}  ✓ Configuration created${NC}"
echo ""

# Update devcontainer.json
echo -e "${BLUE}[5/5] Configuring devcontainer...${NC}"
if [ -f "${WORKSPACE_DIR}/.devcontainer/devcontainer.json" ]; then
    # Update name in devcontainer.json
    sed -i "s/\"name\": \".*\"/\"name\": \"Frappe ${WORKSPACE_NAME^}\"/" "${WORKSPACE_DIR}/.devcontainer/devcontainer.json"
    echo -e "${GREEN}  ✓ Devcontainer configured${NC}"
fi
echo ""

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}Workspace Created Successfully!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${BLUE}Workspace: ${WORKSPACE_NAME}${NC}"
echo -e "${BLUE}Location: workspaces/${WORKSPACE_NAME}${NC}"
echo -e "${BLUE}Port: http://localhost:${HOST_PORT}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. cd workspaces/${WORKSPACE_NAME}"
echo -e "  2. code .  ${BLUE}(open in VSCode)${NC}"
echo -e "  3. Click ${YELLOW}'Reopen in Container'${NC} when prompted"
echo -e "  4. Wait for automatic bench initialization"
echo ""
