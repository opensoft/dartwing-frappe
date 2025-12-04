#!/bin/bash
set -e

echo "=========================================="
echo "Dartwing Frappe Setup"
echo "=========================================="

# Load .env file if it exists
if [ -f "/workspace/.devcontainer/.env" ]; then
    export $(grep -v '^#' /workspace/.devcontainer/.env | xargs)
fi

# Configuration
BENCH_PATH="${FRAPPE_BENCH_PATH:-/workspace/development/frappe-bench}"
SITE_NAME="${SITE_NAME:-dartwing.localhost}"
APP_NAME="dartwing"
APP_REPO_DIR="frappe-app-dartwing"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${DB_PASSWORD:-frappe}"
DB_NAME="${DB_NAME:-dartwing}"
FALLBACK_SCRIPT="$BENCH_PATH/setup_new_frappe-app-dartwing.sh"

# Add bench to PATH
export PATH="$PATH:$HOME/.local/bin:$BENCH_PATH/env/bin"
export PYTHONPATH="$BENCH_PATH/apps:$PYTHONPATH"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

cd $BENCH_PATH

# Step 1: Check and configure MariaDB host
echo -e "${BLUE}[1/4] Checking MariaDB configuration...${NC}"
DB_HOST_CONFIG="${DB_HOST:-frappe-mariadb}"
if ! grep -q "db_host" sites/common_site_config.json 2>/dev/null; then
    echo -e "${YELLOW}  → Setting MariaDB host to ${DB_HOST_CONFIG}${NC}"
    bench set-mariadb-host "$DB_HOST_CONFIG"
else
    echo -e "${GREEN}  ✓ MariaDB host already configured${NC}"
fi

# Step 2: Check if site exists
echo -e "${BLUE}[2/4] Checking if site '$SITE_NAME' exists...${NC}"
if [ ! -d "sites/$SITE_NAME" ]; then
    echo -e "${YELLOW}  → Creating site '$SITE_NAME'${NC}"
    if [ -n "$DB_NAME" ] && [ "$DB_NAME" != "dartwing" ]; then
        bench new-site $SITE_NAME \
            --db-name $DB_NAME \
            --admin-password $ADMIN_PASSWORD \
            --db-root-password $DB_ROOT_PASSWORD \
            --no-mariadb-socket
    else
        bench new-site $SITE_NAME \
            --admin-password $ADMIN_PASSWORD \
            --db-root-password $DB_ROOT_PASSWORD \
            --no-mariadb-socket
    fi
    echo -e "${GREEN}  ✓ Site created successfully${NC}"
else
    echo -e "${GREEN}  ✓ Site already exists${NC}"
fi

# Step 3: Check if app exists
echo -e "${BLUE}[3/4] Checking if app '$APP_NAME' exists...${NC}"
if [ ! -d "apps/$APP_REPO_DIR" ]; then
    echo -e "${YELLOW}  → App repo missing, attempting to clone '$APP_NAME' from GitHub${NC}"
    if bench get-app https://github.com/Opensoft/frappe-app-dartwing.git "$APP_REPO_DIR"; then
        echo -e "${GREEN}  ✓ App cloned successfully${NC}"
    else
        echo -e "${YELLOW}  → Clone failed. Running local bootstrap script '${FALLBACK_SCRIPT}'${NC}"
        if [ -x "$FALLBACK_SCRIPT" ]; then
            "$FALLBACK_SCRIPT"
            echo -e "${GREEN}  ✓ Local app bootstrap complete${NC}"
        else
            echo -e "${YELLOW}  → Fallback script not found or not executable${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}  ✓ App already exists${NC}"
fi

# Step 4: Check if app is installed on site
echo -e "${BLUE}[4/4] Checking if app is installed on site...${NC}"
if ! bench --site $SITE_NAME list-apps | grep -q "^$APP_NAME$"; then
    echo -e "${YELLOW}  → Installing app '$APP_NAME' to site '$SITE_NAME'${NC}"
    bench --site $SITE_NAME install-app $APP_NAME
    echo -e "${GREEN}  ✓ App installed successfully${NC}"
else
    echo -e "${GREEN}  ✓ App already installed${NC}"
fi

# Set as default site
echo -e "${BLUE}Setting '$SITE_NAME' as default site...${NC}"
bench use $SITE_NAME
echo -e "${GREEN}  ✓ Default site set${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo "Site: http://localhost:8081"
echo "Login: Administrator / $ADMIN_PASSWORD"
echo "App Location: $BENCH_PATH/apps/$APP_REPO_DIR"
echo ""
echo "To start development server:"
echo "  cd $BENCH_PATH"
echo "  bench start"
echo "=========================================="
