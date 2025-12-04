#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Frappe Bench Setup - Phase 2"
echo "Running inside devcontainer"
echo -e "==========================================${NC}"
echo ""

# Check if setup already completed
if [ -f "/workspace/development/.setup_complete" ]; then
    echo -e "${GREEN}Setup already completed. Skipping...${NC}"
    echo -e "${YELLOW}To re-run setup, delete: /workspace/development/.setup_complete${NC}"
    exit 0
fi

# Load environment variables from .env
if [ -f "/workspace/.devcontainer/.env" ]; then
    export $(grep -v '^#' /workspace/.devcontainer/.env | xargs)
    echo -e "${GREEN}✓ Loaded environment variables${NC}"
else
    echo -e "${RED}✗ .env file not found!${NC}"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Site: ${SITE_NAME}"
echo -e "  Database: ${DB_NAME}"
echo -e "  Codename: ${CODENAME}"
echo ""

# Step 1: Initialize Frappe Bench
echo -e "${BLUE}[1/5] Initializing Frappe bench...${NC}"
echo -e "${YELLOW}  → This will take several minutes...${NC}"

cd /workspace/development/frappe-bench

# Check if bench is already initialized
if [ ! -f "sites/apps.txt" ]; then
    bench init --skip-redis-config-generation --frappe-branch version-15 .
    
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

# Step 2: Install App in Bench
echo -e "${BLUE}[2/5] Installing frappe-app-dartwing in bench...${NC}"

if ! grep -q "frappe-app-dartwing" sites/apps.txt 2>/dev/null; then
    bench get-app ./apps/frappe-app-dartwing
    echo -e "${GREEN}  ✓ App registered with bench${NC}"
else
    echo -e "${YELLOW}  → App already registered, skipping${NC}"
fi
echo ""

# Step 3: Create Site
echo -e "${BLUE}[3/5] Creating Frappe site...${NC}"
echo -e "${YELLOW}  → This may take a few minutes...${NC}"

if [ ! -d "sites/${SITE_NAME}" ]; then
    bench new-site ${SITE_NAME} \
        --db-name ${DB_NAME} \
        --admin-password admin \
        --db-root-password frappe \
        --no-mariadb-socket
    
    echo -e "${GREEN}  ✓ Site created${NC}"
else
    echo -e "${YELLOW}  → Site already exists, skipping${NC}"
fi
echo ""

# Step 4: Install App on Site
echo -e "${BLUE}[4/5] Installing app on site...${NC}"

# Check if app is already installed
if ! bench --site ${SITE_NAME} list-apps 2>/dev/null | grep -q "dartwing"; then
    bench --site ${SITE_NAME} install-app dartwing
    echo -e "${GREEN}  ✓ App installed on site${NC}"
else
    echo -e "${YELLOW}  → App already installed, skipping${NC}"
fi

# Set as default site
bench use ${SITE_NAME}
echo -e "${GREEN}  ✓ Set as default site${NC}"
echo ""

# Step 5: Mark Setup Complete
echo -e "${BLUE}[5/5] Marking setup as complete...${NC}"
touch /workspace/development/.setup_complete
echo -e "${GREEN}  ✓ Setup complete marker created${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Phase 2 Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "Site Details:"
echo -e "  URL: ${BLUE}http://localhost:${HOST_PORT}${NC}"
echo -e "  Site: ${SITE_NAME}"
echo -e "  Username: ${YELLOW}Administrator${NC}"
echo -e "  Password: ${YELLOW}admin${NC}"
echo ""
echo -e "To start developing:"
echo -e "  ${YELLOW}cd /workspace/development/frappe-bench${NC}"
echo -e "  ${YELLOW}bench start${NC}"
echo ""
