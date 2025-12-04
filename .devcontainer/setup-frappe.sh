#!/bin/bash
set -e

# Load environment variables
if [ -f .devcontainer/.env ]; then
    export $(grep -v '^#' .devcontainer/.env | xargs)
fi

FRAPPE_SITE_NAME=${FRAPPE_SITE_NAME:-site1.localhost}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
DB_HOST=${DB_HOST:-mariadb}
DB_PASSWORD=${DB_PASSWORD:-frappe}

echo "Setting up Frappe Bench..."

# Navigate to workspace
cd /workspace/development || mkdir -p /workspace/development && cd /workspace/development

# Check if bench is already initialized
if [ ! -d "frappe-bench" ]; then
    echo "Initializing Frappe Bench..."
    bench init frappe-bench --frappe-branch version-15 --python python3.11
    cd frappe-bench
else
    echo "Frappe Bench already exists"
    cd frappe-bench
fi

# Configure database connection
echo "Configuring database connection..."
bench set-config -g db_host "$DB_HOST"
bench set-config -g db_port 3306

# Check if site exists
if [ ! -d "sites/$FRAPPE_SITE_NAME" ]; then
    echo "Creating new site: $FRAPPE_SITE_NAME"
    bench new-site "$FRAPPE_SITE_NAME" \
        --mariadb-root-password "$DB_PASSWORD" \
        --admin-password "$ADMIN_PASSWORD" \
        --no-mariadb-socket
    
    echo "Site created successfully!"
else
    echo "Site $FRAPPE_SITE_NAME already exists"
fi

# Set current site
bench use "$FRAPPE_SITE_NAME"

# Configure Redis
bench set-config -g redis_cache "redis://redis-cache:6379"
bench set-config -g redis_queue "redis://redis-queue:6379"
bench set-config -g redis_socketio "redis://redis-socketio:6379"

echo "Frappe setup complete!"
echo "You can now run: bench start"
