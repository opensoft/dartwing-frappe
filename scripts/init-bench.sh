#!/bin/bash
set -e

# Disable yarn corepack prompts
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Frappe Bench Initialization"
echo "Running inside devcontainer"
echo -e "==========================================${NC}"
echo ""

# Install required packages if not present
echo -e "${BLUE}Ensuring required packages are installed...${NC}"
if ! command -v mariadb >/dev/null 2>&1; then
    echo -e "${YELLOW}  → mariadb client not found; attempting install...${NC}"
    if command -v sudo >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y mariadb-client || true
    else
        apt-get update && apt-get install -y mariadb-client || true
    fi
fi
if command -v mariadb >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ mariadb-client available${NC}"
else
    echo -e "${RED}  ✗ mariadb-client still missing; rebuild container${NC}"
    exit 1
fi
echo ""

# Determine script location and workspace root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load environment variables from .env (required for multi-workspace naming)
ENV_FILE="${WORKSPACE_ROOT}/.devcontainer/.env"
if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^(UID|GID)= ]] && continue
        export "$line"
    done < "$ENV_FILE"
    echo -e "${GREEN}✓ Loaded environment variables${NC}"
else
    echo -e "${RED}✗ .env file not found at: ${ENV_FILE}${NC}"
    exit 1
fi

# Determine bench directory (allow override from .env)
BENCH_DIR="${FRAPPE_BENCH_PATH:-${WORKSPACE_ROOT}/bench}"
if [[ "$BENCH_DIR" != /* ]]; then
    BENCH_DIR="${WORKSPACE_ROOT}/${BENCH_DIR}"
fi

# Determine workspace name/codename.
# In containers, /workspace is a fixed path, so basename(/workspace) is not useful.
NAME=""
if [ -n "${CODENAME:-}" ] && [ "${CODENAME}" != "default" ]; then
    NAME="${CODENAME}"
else
    # Prefer the comment written by scripts/new-workspace.sh
    if grep -q '^# Workspace:' "$ENV_FILE"; then
        NAME="$(grep '^# Workspace:' "$ENV_FILE" | head -n1 | sed 's/^# Workspace:[[:space:]]*//')"
    elif [ -n "${SITE_NAME:-}" ]; then
        NAME="${SITE_NAME%%.*}"
    fi
fi
if [ -z "$NAME" ]; then
    NAME=$(basename "$WORKSPACE_ROOT")
fi

# Set defaults based on NAME
SITE_NAME="${SITE_NAME:-${NAME}.localhost}"
DB_NAME="${DB_NAME:-dartwing_${NAME}}"
DB_HOST="${DB_HOST:-frappe-mariadb}"
DB_PORT="${DB_PORT:-3306}"
if [ -z "${CODENAME:-}" ] || [ "${CODENAME}" = "default" ]; then
    CODENAME="${NAME}"
fi
HOST_PORT="${HOST_PORT:-8000}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-frappe}"

# Get app list from .env or default (used for pre-clone and install)
APPS_TO_INSTALL="${APPS_TO_INSTALL:-dartwing}"
IFS=',' read -ra APPS <<< "$APPS_TO_INSTALL"

echo -e "${BLUE}Workspace Structure:${NC}"
echo -e "  Workspace root: ${WORKSPACE_ROOT}"
echo -e "  Bench directory: ${BENCH_DIR}"
echo -e "  Env file: ${ENV_FILE}"
echo -e "  Workspace name: ${NAME}"
echo ""

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Site: ${SITE_NAME}"
echo -e "  Database: ${DB_NAME}"
echo -e "  Codename: ${CODENAME}"
echo -e "  Host port: ${HOST_PORT}"
echo -e "  Apps: ${APPS_TO_INSTALL}"
echo ""

# Check if setup already completed
SETUP_MARKER="${BENCH_DIR}/.setup_complete"
if [ -f "$SETUP_MARKER" ]; then
    echo -e "${GREEN}Setup already completed. Skipping...${NC}"
    echo -e "${YELLOW}To re-run setup, delete: ${SETUP_MARKER}${NC}"
    exit 0
fi

# Step 1: Initialize Frappe Bench
echo -e "${BLUE}[1/6] Initializing Frappe bench...${NC}"
echo -e "${YELLOW}  → This will take several minutes...${NC}"

mkdir -p "$BENCH_DIR"
cd "$BENCH_DIR"

# Pre-clone apps before bench init if needed (bench commands require an initialized bench)
if [ ! -f "sites/apps.txt" ]; then
    mkdir -p "apps"
    for app in "${APPS[@]}"; do
        app=$(echo "$app" | xargs)
        [ -z "$app" ] && continue
        if [ "$app" = "dartwing" ]; then
            if [ ! -d "apps/dartwing" ]; then
                echo -e "${YELLOW}  → Pre-cloning dartwing app before bench init...${NC}"
                git clone https://github.com/opensoft/frappe-app-dartwing.git "apps/dartwing"
                echo -e "${GREEN}  ✓ dartwing app pre-cloned${NC}"
            elif [ -d "apps/dartwing/.git" ]; then
                echo -e "${YELLOW}  → dartwing already present; checking for updates...${NC}"
                if git -C "apps/dartwing" diff-index --quiet HEAD -- 2>/dev/null; then
                    git -C "apps/dartwing" pull --ff-only || echo -e "${YELLOW}  → Update failed or offline; continuing${NC}"
                else
                    echo -e "${YELLOW}  → Uncommitted changes in apps/dartwing; skipping pull${NC}"
                fi
            else
                echo -e "${YELLOW}  → apps/dartwing exists but is not a git repo; skipping update${NC}"
            fi
        fi
    done
fi

# Check if bench is already initialized
if [ ! -f "sites/apps.txt" ]; then
bench init --skip-redis-config-generation --ignore-exist --frappe-branch version-15 .
    
    # Configure Redis and DB connections
    cat > sites/common_site_config.json << 'EOF'
{
 "db_host": "frappe-mariadb",
 "db_port": 3306,
 "redis_cache": "redis://frappe-redis-cache:6379",
 "redis_queue": "redis://frappe-redis-queue:6379",
 "redis_socketio": "redis://frappe-redis-socketio:6379"
}
EOF
    
    echo -e "${GREEN}  ✓ Bench initialized${NC}"
else
    echo -e "${YELLOW}  → Bench already initialized, skipping${NC}"
fi
echo ""

# Ensure common_site_config.json settings (run every time)
echo -e "${BLUE}Ensuring bench common_site_config.json settings...${NC}"
CONFIG_PATH="sites/common_site_config.json"
TMP_CFG="$(mktemp)"
cat > "$TMP_CFG" << 'EOF'
{
  "db_host": "frappe-mariadb",
  "db_port": 3306,
  "db_root_password": "frappe",
  "redis_cache": "redis://frappe-redis-cache:6379",
  "redis_queue": "redis://frappe-redis-queue:6379",
  "redis_socketio": "redis://frappe-redis-socketio:6379"
}
EOF
if [ -f "$CONFIG_PATH" ]; then
  jq -s '.[0] * .[1]' "$CONFIG_PATH" "$TMP_CFG" > "${CONFIG_PATH}.tmp" && mv "${CONFIG_PATH}.tmp" "$CONFIG_PATH"
  echo -e "${GREEN}  ✓ Merged desired settings into ${CONFIG_PATH}${NC}"
else
  mkdir -p "$(dirname "$CONFIG_PATH")"
  mv "$TMP_CFG" "$CONFIG_PATH"
  echo -e "${GREEN}  ✓ Created ${CONFIG_PATH} with desired settings${NC}"
fi
rm -f "$TMP_CFG" 2>/dev/null || true
echo ""

# Step 2: Install Apps in Bench (from .env or default to dartwing)
echo -e "${BLUE}[2/6] Installing apps in bench...${NC}"

for app in "${APPS[@]}"; do
    app=$(echo "$app" | xargs) # trim whitespace

    [ -z "$app" ] && continue

    # If the app was pre-cloned into apps/, register it without overwriting.
    APP_DIR="apps/${app}"
    if [ -d "$APP_DIR" ]; then
        if grep -q "^${app}$" sites/apps.txt 2>/dev/null; then
            echo -e "${YELLOW}  → ${app} already registered (local)${NC}"
        else
            echo -e "${YELLOW}  → Registering existing app: ${app}${NC}"
            echo "${app}" >> sites/apps.txt
            if [ -x "env/bin/pip" ]; then
                env/bin/pip install -e "$APP_DIR"
            fi
            bench build --app "${app}" || true
            echo -e "${GREEN}  ✓ ${app} registered from existing directory${NC}"
        fi
        continue
    fi

    if [ "$app" == "dartwing" ]; then
        # Special handling for dartwing app - clone from GitHub if missing
        if ! grep -q "^dartwing$" sites/apps.txt 2>/dev/null; then
            echo 'y' | bench get-app https://github.com/opensoft/frappe-app-dartwing.git
            if [ -x "env/bin/pip" ] && [ -d "$APP_DIR" ]; then
                env/bin/pip install -e "$APP_DIR"
            fi
            bench build --app "${app}" || true
            echo -e "${GREEN}  ✓ dartwing app installed${NC}"
        else
            echo -e "${YELLOW}  → dartwing app already installed${NC}"
        fi
    else
        # Generic app installation
        if ! grep -q "^${app}$" sites/apps.txt 2>/dev/null; then
            echo -e "${YELLOW}  → Installing app: ${app}${NC}"
            bench get-app "$app"
            if [ -x "env/bin/pip" ] && [ -d "$APP_DIR" ]; then
                env/bin/pip install -e "$APP_DIR"
            fi
            bench build --app "${app}" || true
            echo -e "${GREEN}  ✓ ${app} registered with bench${NC}"
        else
            echo -e "${YELLOW}  → ${app} already registered${NC}"
        fi
    fi
done
echo ""

# Ensure known fixture issues don't break installs/migrations
echo -e "${BLUE}Validating app fixtures...${NC}"
ROLE_TEMPLATE_FIXTURE="apps/dartwing/dartwing/fixtures/role_template.json"
if [ -f "$ROLE_TEMPLATE_FIXTURE" ]; then
    FIXTURE_RESULT="$(
        python3 - "$ROLE_TEMPLATE_FIXTURE" <<'PY'
import json
import sys
from collections import OrderedDict

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f, object_pairs_hook=OrderedDict)

changed = False
if isinstance(data, list):
    for obj in data:
        if isinstance(obj, dict) and "doctype" in obj and "name" not in obj:
            role_name = obj.get("role_name")
            if role_name:
                obj["name"] = role_name
                changed = True

if changed:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("patched")
else:
    print("ok")
PY
    )" || {
        echo -e "${RED}  ✗ Failed to validate/patch ${ROLE_TEMPLATE_FIXTURE}${NC}"
        exit 1
    }

    if [ "$FIXTURE_RESULT" = "patched" ]; then
        echo -e "${GREEN}  ✓ Patched missing \"name\" fields in ${ROLE_TEMPLATE_FIXTURE}${NC}"
    else
        echo -e "${GREEN}  ✓ Fixtures look good${NC}"
    fi
else
    echo -e "${YELLOW}  → ${ROLE_TEMPLATE_FIXTURE} not found; skipping${NC}"
fi
echo ""

# Step 3: Create Site
echo -e "${BLUE}[3/6] Creating Frappe site...${NC}"
echo -e "${YELLOW}  → This may take a few minutes...${NC}"

# Clean up existing DB/site for rebuilds
echo -e "${BLUE}Preparing site/database for creation...${NC}"
SITE_DIR="sites/${SITE_NAME}"
if [ -d "$SITE_DIR" ]; then
    echo -e "${YELLOW}  → Removing existing site directory: ${SITE_DIR}${NC}"
    rm -rf "$SITE_DIR"
fi
if command -v mariadb >/dev/null 2>&1; then
    echo -e "${YELLOW}  → Dropping database if it exists: ${DB_NAME}${NC}"
    mariadb --host="${DB_HOST}" --port="${DB_PORT}" --user=root --password="${DB_ROOT_PASSWORD}" \
        --execute="DROP DATABASE IF EXISTS \`${DB_NAME}\`;" || true
fi
echo ""

if [ ! -d "sites/${SITE_NAME}" ]; then
    bench new-site "${SITE_NAME}" \
        --db-name "${DB_NAME}" \
        --admin-password "${ADMIN_PASSWORD}" \
        --db-root-password "${DB_ROOT_PASSWORD}" \
        --no-mariadb-socket
    
    echo -e "${GREEN}  ✓ Site created${NC}"
else
    echo -e "${YELLOW}  → Site already exists, skipping${NC}"
fi
echo ""

# Step 4: Install Apps on Site
echo -e "${BLUE}[4/6] Installing apps on site...${NC}"

for app in "${APPS[@]}"; do
    app=$(echo "$app" | xargs) # trim whitespace
    
    # Check if app is already installed
    if ! bench --site ${SITE_NAME} list-apps 2>/dev/null | grep -q "^${app}$"; then
        bench --site ${SITE_NAME} install-app ${app}
        echo -e "${GREEN}  ✓ ${app} installed on site${NC}"
    else
        echo -e "${YELLOW}  → ${app} already installed${NC}"
    fi
done

# Set as default site
bench use ${SITE_NAME}
echo -e "${GREEN}  ✓ Set as default site${NC}"
echo ""

# Step 5: Enable Developer Mode and Additional Developer Options
echo -e "${BLUE}[5/6] Configuring developer options...${NC}"

# Enable developer mode globally
bench set-config -g developer_mode 1
echo -e "${GREEN}  ✓ Developer mode enabled${NC}"

# Enable custom JavaScript scripts for development
bench set-config -g allow_js_scripts true
echo -e "${GREEN}  ✓ Custom JS scripts enabled${NC}"

# Disable debugger restrictions for development
bench set-config -g disable_debugger false
echo -e "${GREEN}  ✓ Debugger enabled${NC}"

# Clear cache to apply all changes
bench clear-cache
echo -e "${GREEN}  ✓ Cache cleared${NC}"
echo ""

# Step 6: Mark Setup Complete
echo -e "${BLUE}[6/6] Marking setup as complete...${NC}"
touch "$SETUP_MARKER"
echo -e "${GREEN}  ✓ Setup complete marker created${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Bench Initialization Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "Site Details:"
echo -e "  URL: ${BLUE}http://localhost:${HOST_PORT}${NC}"
echo -e "  Site: ${SITE_NAME}"
echo -e "  Username: ${YELLOW}Administrator${NC}"
echo -e "  Password: ${YELLOW}${ADMIN_PASSWORD}${NC}"
echo ""
echo -e "To start developing:"
echo -e "  ${YELLOW}cd ${BENCH_DIR}${NC}"
echo -e "  ${YELLOW}bench start${NC}"
echo ""
