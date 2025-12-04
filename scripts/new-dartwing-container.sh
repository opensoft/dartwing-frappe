#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# NATO phonetic alphabet for codenames
NATO_ALPHABET=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu)

# Configuration
DARTWING_ROOT="/home/brett/projects/dartwingers/dartwing"
FRAPPE_INFRA_PATH="/home/brett/projects/workBenches/devBenches/frappeBench"
FRAPPE_REPO="git@github.com:opensoft/dartwing-frappe.git"
APP_REPO="git@github.com:opensoft/frappe-app-dartwing.git"
BASE_PORT=8001

# Parse arguments
APP_BRANCH="${1:-main}"
CODENAME_OVERRIDE="${2:-}"

echo -e "${BLUE}=========================================="
echo "Dartwing Multi-Branch Container Creator"
echo -e "==========================================${NC}"
echo ""

# Step 1: Verify Infrastructure
echo -e "${BLUE}[1/11] Verifying Frappe infrastructure...${NC}"
if ! docker network inspect frappe-network >/dev/null 2>&1; then
    echo -e "${RED}  ✗ frappe-network not found!${NC}"
    echo -e "${YELLOW}  → Starting Frappe infrastructure...${NC}"
    cd "$FRAPPE_INFRA_PATH"
    docker compose up -d mariadb redis-cache redis-queue redis-socketio
    echo -e "${GREEN}  ✓ Infrastructure started${NC}"
else
    echo -e "${GREEN}  ✓ frappe-network exists${NC}"
fi

# Check if containers are running
if ! docker ps | grep -q frappe-mariadb; then
    echo -e "${YELLOW}  → Starting MariaDB...${NC}"
    cd "$FRAPPE_INFRA_PATH"
    docker compose up -d mariadb
fi

if ! docker ps | grep -q frappe-redis-cache; then
    echo -e "${YELLOW}  → Starting Redis containers...${NC}"
    cd "$FRAPPE_INFRA_PATH"
    docker compose up -d redis-cache redis-queue redis-socketio
fi

echo -e "${GREEN}  ✓ All infrastructure services running${NC}"
echo ""

# Step 2: Determine Codename
echo -e "${BLUE}[2/11] Determining codename...${NC}"
cd "$DARTWING_ROOT"

if [ -n "$CODENAME_OVERRIDE" ]; then
    CODENAME_LOWER="$CODENAME_OVERRIDE"
    CODENAME_UPPER=$(echo "$CODENAME_LOWER" | tr '[:lower:]' '[:upper:]')
    echo -e "${GREEN}  ✓ Using override codename: ${CODENAME_LOWER}${NC}"
else
    # Find existing frappe-* directories
    EXISTING_INSTANCES=($(ls -d frappe-* 2>/dev/null | sed 's/frappe-//' | grep -v "app-dartwing" || true))
    
    # Find first available codename
    CODENAME_LOWER=""
    for nato in "${NATO_ALPHABET[@]}"; do
        if [[ ! " ${EXISTING_INSTANCES[@]} " =~ " ${nato} " ]]; then
            CODENAME_LOWER="$nato"
            break
        fi
    done
    
    if [ -z "$CODENAME_LOWER" ]; then
        echo -e "${RED}  ✗ All NATO codenames exhausted!${NC}"
        exit 1
    fi
    
    CODENAME_UPPER=$(echo "$CODENAME_LOWER" | tr '[:lower:]' '[:upper:]')
    echo -e "${GREEN}  ✓ Generated codename: ${CODENAME_LOWER}${NC}"
fi

# Determine port
INSTANCE_COUNT=${#EXISTING_INSTANCES[@]}
PORT=$((BASE_PORT + INSTANCE_COUNT))
INSTANCE_DIR="frappe-${CODENAME_LOWER}"
CONTAINER_NAME="frappe-${CODENAME_LOWER}"
SITE_NAME="site-${CODENAME_LOWER}.local"
DB_NAME="dartwing_${CODENAME_LOWER}"

echo -e "${BLUE}  Instance: ${INSTANCE_DIR}${NC}"
echo -e "${BLUE}  Port: ${PORT}${NC}"
echo -e "${BLUE}  Site: ${SITE_NAME}${NC}"
echo -e "${BLUE}  Database: ${DB_NAME}${NC}"
echo ""

# Step 3: Clone dartwing-frappe repo
echo -e "${BLUE}[3/11] Cloning dartwing-frappe repository...${NC}"
if [ -d "$INSTANCE_DIR" ]; then
    echo -e "${RED}  ✗ Directory ${INSTANCE_DIR} already exists!${NC}"
    exit 1
fi

git clone "$FRAPPE_REPO" "$INSTANCE_DIR"
echo -e "${GREEN}  ✓ Repository cloned${NC}"
echo ""

# Step 4: Configure .env file
echo -e "${BLUE}[4/11] Configuring .env file...${NC}"
cd "$INSTANCE_DIR/.devcontainer"
cp .env.example .env

# Update .env file
sed -i "s/^CODENAME=.*/CODENAME=${CODENAME_LOWER}/" .env
sed -i "s/^CONTAINER_NAME=.*/CONTAINER_NAME=${CONTAINER_NAME}/" .env
sed -i "s/^HOST_PORT=.*/HOST_PORT=${PORT}/" .env
sed -i "s/^SITE_NAME=.*/SITE_NAME=${SITE_NAME}/" .env
sed -i "s/^DB_NAME=.*/DB_NAME=${DB_NAME}/" .env

echo -e "${GREEN}  ✓ .env file configured${NC}"
echo ""

# Step 5: Update devcontainer.json
echo -e "${BLUE}[5/11] Updating devcontainer.json...${NC}"

# Update the service name in devcontainer.json
sed -i "s/\"service\": \".*\"/\"service\": \"${CODENAME_LOWER}-dev\"/" devcontainer.json

# Update the name
sed -i "s/\"name\": \".*\"/\"name\": \"Frappe ${CODENAME_UPPER}\"/" devcontainer.json

# Update workspace folder to point to the app
sed -i "s|\"workspaceFolder\": \".*\"|\"workspaceFolder\": \"/workspace/frappe-bench/apps/frappe-app-dartwing\"|" devcontainer.json

echo -e "${GREEN}  ✓ devcontainer.json updated${NC}"
echo ""

cd "$DARTWING_ROOT/$INSTANCE_DIR"

# Step 6: Create frappe-bench directory
echo -e "${BLUE}[6/11] Creating frappe-bench directory...${NC}"
mkdir -p frappe-bench
echo -e "${GREEN}  ✓ Directory created${NC}"
echo ""

# Step 7: Initialize bench (using docker container with bench installed)
echo -e "${BLUE}[7/11] Initializing Frappe bench...${NC}"
echo -e "${YELLOW}  → This will take several minutes...${NC}"

# Start a temporary container to init bench
docker run --rm \
    --network frappe-network \
    -v "$DARTWING_ROOT/$INSTANCE_DIR/frappe-bench:/workspace" \
    -e DB_HOST=frappe-mariadb \
    -e REDIS_CACHE=frappe-redis-cache:6379 \
    -e REDIS_QUEUE=frappe-redis-queue:6379 \
    -e REDIS_SOCKETIO=frappe-redis-socketio:6379 \
    frappe/bench:latest \
    bash -c "cd /workspace && bench init --skip-redis-config-generation --frappe-branch version-15 . && \
             bench set-config -g db_host frappe-mariadb && \
             bench set-config -g redis_cache frappe-redis-cache:6379 && \
             bench set-config -g redis_queue frappe-redis-queue:6379 && \
             bench set-config -g redis_socketio frappe-redis-socketio:6379"

echo -e "${GREEN}  ✓ Bench initialized${NC}"
echo ""

# Step 8: Clone frappe-app-dartwing
echo -e "${BLUE}[8/11] Cloning frappe-app-dartwing repository...${NC}"
cd frappe-bench/apps
git clone "$APP_REPO"
cd frappe-app-dartwing

if [ "$APP_BRANCH" != "main" ]; then
    echo -e "${YELLOW}  → Checking out branch: ${APP_BRANCH}${NC}"
    git checkout "$APP_BRANCH"
fi

echo -e "${GREEN}  ✓ App repository cloned${NC}"
echo ""

cd "$DARTWING_ROOT/$INSTANCE_DIR"

# Step 9: Install app in bench
echo -e "${BLUE}[9/11] Installing app in bench...${NC}"
docker run --rm \
    --network frappe-network \
    -v "$DARTWING_ROOT/$INSTANCE_DIR/frappe-bench:/workspace" \
    frappe/bench:latest \
    bash -c "cd /workspace && bench get-app /workspace/apps/frappe-app-dartwing"

echo -e "${GREEN}  ✓ App installed in bench${NC}"
echo ""

# Step 10: Create site
echo -e "${BLUE}[10/11] Creating site...${NC}"
echo -e "${YELLOW}  → This will take a few minutes...${NC}"

docker run --rm \
    --network frappe-network \
    -v "$DARTWING_ROOT/$INSTANCE_DIR/frappe-bench:/workspace" \
    -e DB_HOST=frappe-mariadb \
    frappe/bench:latest \
    bash -c "cd /workspace && \
             bench new-site ${SITE_NAME} \
             --db-name ${DB_NAME} \
             --admin-password admin \
             --db-root-password frappe \
             --no-mariadb-socket && \
             bench --site ${SITE_NAME} install-app dartwing && \
             bench use ${SITE_NAME}"

echo -e "${GREEN}  ✓ Site created and app installed${NC}"
echo ""

# Step 11: Create instance info file
echo -e "${BLUE}[11/11] Creating instance info file...${NC}"

cat > INSTANCE_INFO.md << EOF
# Frappe Instance: ${CODENAME_UPPER}

## Configuration
- **Codename**: ${CODENAME_LOWER}
- **Container Name**: ${CONTAINER_NAME}
- **Port**: ${PORT}
- **Site Name**: ${SITE_NAME}
- **Database**: ${DB_NAME}
- **App Branch**: ${APP_BRANCH}
- **Created**: $(date)

## URLs
- Development: http://localhost:${PORT}
- Site: http://${SITE_NAME}:${PORT}

## Credentials
- Username: Administrator
- Password: admin

## Commands
Start the development server:
\`\`\`bash
cd /workspace/frappe-bench
bench start
\`\`\`

Access the site:
\`\`\`bash
bench --site ${SITE_NAME} console
\`\`\`

## Cleanup
To remove this instance:
\`\`\`bash
cd /home/brett/projects/dartwingers/dartwing
rm -rf ${INSTANCE_DIR}
docker exec frappe-mariadb mysql -uroot -pfrappe -e "DROP DATABASE ${DB_NAME};"
\`\`\`
EOF

echo -e "${GREEN}  ✓ Instance info created${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "Instance Details:"
echo -e "  Codename:  ${BLUE}${CODENAME_LOWER}${NC}"
echo -e "  Directory: ${BLUE}${INSTANCE_DIR}${NC}"
echo -e "  Port:      ${BLUE}${PORT}${NC}"
echo -e "  Branch:    ${BLUE}${APP_BRANCH}${NC}"
echo ""
echo -e "Next Steps:"
echo -e "  1. ${YELLOW}cd ${INSTANCE_DIR}${NC}"
echo -e "  2. ${YELLOW}code .${NC}"
echo -e "  3. Reopen in Container (VS Code will prompt)"
echo -e "  4. Inside container: ${YELLOW}cd /workspace/frappe-bench && bench start${NC}"
echo -e "  5. Visit: ${BLUE}http://localhost:${PORT}${NC}"
echo ""
echo -e "See ${BLUE}INSTANCE_INFO.md${NC} for more details."
