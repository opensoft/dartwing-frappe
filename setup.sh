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
echo -e "${BLUE}[1/4] Checking prerequisites...${NC}"

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

# Check if del-workspace.sh exists
if [ ! -f "${SCRIPT_DIR}/del-workspace.sh" ]; then
    echo -e "${RED}  ✗ del-workspace.sh script not found!${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ del-workspace.sh found${NC}"
echo ""

# Step 2: Install workspace commands for easy access
echo -e "${BLUE}[2/4] Installing workspace commands...${NC}"

# Install to a shared bin under projects/dartwing by default.
DARTWING_ROOT="$(dirname "$PROJECT_ROOT")"
INSTALL_DIR="${DARTWING_BIN_DIR:-${DARTWING_ROOT}/bin}"

install_wrapper() {
    local script_name="$1"
    local source_script="$2"
    local install_path="${INSTALL_DIR}/${script_name}"
    local need_install=true

    if [ -L "$install_path" ]; then
        local target
        target="$(readlink "$install_path" 2>/dev/null || true)"
        if [ "$target" = "$source_script" ]; then
            need_install=false
        fi
    elif [ -f "$install_path" ]; then
        if grep -Fq "exec \"${source_script}\"" "$install_path" 2>/dev/null; then
            need_install=false
        fi
    fi

    if [ "$need_install" = false ]; then
        echo -e "${GREEN}  ✓ ${script_name} already installed at ${install_path}${NC}"
        return 0
    fi

    if [ -e "$install_path" ]; then
        echo -e "${YELLOW}  → Existing ${install_path} found${NC}"
        read -p "Overwrite ${script_name} wrapper? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}  → Skipping ${script_name} install${NC}"
            return 0
        fi
    fi

    rm -f "$install_path"
    cat > "$install_path" << EOF
#!/bin/bash
exec "${source_script}" "\$@"
EOF
    chmod +x "$install_path"
    echo -e "${GREEN}  ✓ Installed ${script_name} at ${install_path}${NC}"
}

if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
    install_wrapper "new-workspace.sh" "${SCRIPT_DIR}/new-workspace.sh"
    install_wrapper "del-workspace.sh" "${SCRIPT_DIR}/del-workspace.sh"

    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo -e "${YELLOW}  → ${INSTALL_DIR} is not on PATH${NC}"
        echo -e "${YELLOW}    Add this to your shell rc:${NC}"
        echo -e "      export PATH=\"${INSTALL_DIR}:\$PATH\""
    fi
else
    echo -e "${YELLOW}  ⚠ Could not create ${INSTALL_DIR}; skipping install${NC}"
fi
echo ""

# Step 3: Ensure workspaces folder exists and check existing workspaces
echo -e "${BLUE}[3/4] Checking workspaces directory...${NC}"
if [ ! -d "${PROJECT_ROOT}/workspaces" ]; then
    mkdir -p "${PROJECT_ROOT}/workspaces"
    echo -e "${GREEN}  ✓ Created workspaces directory${NC}"
else
    echo -e "${YELLOW}  → workspaces directory already exists${NC}"
    
    # Get current template version
    CURRENT_TEMPLATE_VERSION=""
    if [ -f "${PROJECT_ROOT}/devcontainer.example/README.md" ]; then
        CURRENT_TEMPLATE_VERSION=$(grep 'Current Version:' "${PROJECT_ROOT}/devcontainer.example/README.md" | grep -oP '\d+\.\d+\.\d+')
    fi
    
    # Check existing workspaces
    WORKSPACES_FOUND=false
    WORKSPACES_TO_UPDATE=()
    
    for workspace_dir in "${PROJECT_ROOT}/workspaces"/*; do
        if [ -d "$workspace_dir" ]; then
            WORKSPACES_FOUND=true
            workspace_name=$(basename "$workspace_dir")
            
            echo -e "\n${BLUE}  Checking workspace: ${workspace_name}${NC}"
            
            # Check devcontainer version
            WORKSPACE_VERSION="unknown"
            if [ -f "${workspace_dir}/.devcontainer/README.md" ]; then
                WORKSPACE_VERSION=$(grep 'Current Version:' "${workspace_dir}/.devcontainer/README.md" | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
            fi
            
            if [ "$WORKSPACE_VERSION" = "$CURRENT_TEMPLATE_VERSION" ]; then
                echo -e "    ${GREEN}✓ Devcontainer version: ${WORKSPACE_VERSION} (up to date)${NC}"
            else
                echo -e "    ${YELLOW}⚠ Devcontainer version: ${WORKSPACE_VERSION} (latest: ${CURRENT_TEMPLATE_VERSION})${NC}"
                WORKSPACES_TO_UPDATE+=("$workspace_name")
            fi
            
            # Check frappe-app-dartwing git status
            APP_DIR="${workspace_dir}/bench/apps/dartwing"
            if [ -d "$APP_DIR/.git" ]; then
                cd "$APP_DIR"
                
                # Get current branch
                BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
                echo -e "    ${BLUE}→ App branch: ${BRANCH}${NC}"
                
                # Check for uncommitted changes
                if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                    echo -e "    ${YELLOW}⚠ Uncommitted changes in dartwing app${NC}"
                else
                    # Check if in sync with remote
                    git fetch --quiet 2>/dev/null || true
                    LOCAL=$(git rev-parse @ 2>/dev/null)
                    REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
                    
                    if [ "$LOCAL" = "$REMOTE" ]; then
                        echo -e "    ${GREEN}✓ App repository in sync with remote${NC}"
                    elif [ -z "$REMOTE" ]; then
                        echo -e "    ${YELLOW}⚠ No upstream branch set${NC}"
                    else
                        echo -e "    ${YELLOW}⚠ App repository out of sync with remote${NC}"
                    fi
                fi
                
                cd "$PROJECT_ROOT"
            else
                echo -e "    ${YELLOW}⚠ dartwing app not found or not a git repository${NC}"
            fi
        fi
    done
    
    # Ask to update workspaces if needed
    if [ ${#WORKSPACES_TO_UPDATE[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}The following workspaces have outdated devcontainer templates:${NC}"
        for ws in "${WORKSPACES_TO_UPDATE[@]}"; do
            echo -e "  - $ws"
        done
        echo -e "\n${YELLOW}Update these workspaces to version ${CURRENT_TEMPLATE_VERSION}?${NC}"
        echo -e "${YELLOW}This will backup and replace devcontainer files.${NC}"
        read -p "Update workspaces? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for ws in "${WORKSPACES_TO_UPDATE[@]}"; do
                echo -e "\n${BLUE}Updating workspace: ${ws}${NC}"
                
                # Backup current devcontainer
                BACKUP_DIR="${PROJECT_ROOT}/workspaces/${ws}/.devcontainer.backup.$(date +%Y%m%d-%H%M%S)"
                cp -r "${PROJECT_ROOT}/workspaces/${ws}/.devcontainer" "$BACKUP_DIR"
                echo -e "  ${GREEN}✓ Backup created: $(basename "$BACKUP_DIR")${NC}"
                
                # Copy new template (except .env to preserve workspace-specific settings)
                rm -rf "${PROJECT_ROOT}/workspaces/${ws}/.devcontainer"
                cp -r "${PROJECT_ROOT}/devcontainer.example" "${PROJECT_ROOT}/workspaces/${ws}/.devcontainer"
                
                # Restore .env from backup
                if [ -f "${BACKUP_DIR}/.env" ]; then
                    cp "${BACKUP_DIR}/.env" "${PROJECT_ROOT}/workspaces/${ws}/.devcontainer/.env"
                    echo -e "  ${GREEN}✓ Preserved workspace .env settings${NC}"
                fi
                
                # Update devcontainer.json with workspace name
                sed -i "s/WORKSPACE_NAME/${ws}/g" "${PROJECT_ROOT}/workspaces/${ws}/.devcontainer/devcontainer.json"
                
                echo -e "  ${GREEN}✓ Updated to version ${CURRENT_TEMPLATE_VERSION}${NC}"
            done
            echo -e "\n${GREEN}All workspaces updated!${NC}"
        else
            echo -e "${YELLOW}Skipping workspace updates${NC}"
        fi
    fi
fi
echo ""

# Step 4: Create alpha workspace if it doesn't exist
echo -e "${BLUE}[4/4] Checking alpha workspace...${NC}"
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
