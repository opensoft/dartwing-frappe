# Dartwing Frappe Devcontainer Setup

## Overview

This devcontainer is configured to **attach** to the existing Frappe infrastructure rather than creating its own stack. This allows multiple developers or workspaces to share the same Frappe bench, database, and services.

## Architecture

### Primary Infrastructure (External)
Located at: `/home/brett/projects/frappe`

- **Container**: `frappe-dev`
- **Network**: `frappe_frappe-network`
- **Volume**: `frappe-bench-data-frappe`
- **Services**:
  - `frappe-mariadb` (MariaDB 10.6)
  - `frappe-redis-cache` (Redis cache)
  - `frappe-redis-queue` (Redis queue)
  - `frappe-redis-socketio` (Redis SocketIO)
  - `frappe-nginx` (Nginx on port 8081)

### This Workspace
Located at: `/home/brett/projects/dartwingers/dartwing/dartwing-frappe`

- **Container**: `dartwing-frappe-dev`
- **Purpose**: Development environment for Dartwing Frappe app
- **Network**: Uses `frappe_frappe-network` (external)
- **Volume**: Mounts `frappe-bench-data-frappe` (external)

## Configuration Files

### `.devcontainer/devcontainer.json`
- References docker-compose.yml
- Configures VSCode extensions (Python, AI tools)
- Sets remote user to `brett`
- Validates that main Frappe network exists before starting

### `.devcontainer/docker-compose.yml`
- Creates a single lightweight container (`dartwing-dev`)
- Connects to external network: `frappe_frappe-network`
- Mounts external volume: `frappe-bench-data-frappe`
- Mounts this project folder to `/workspace`
- Configures environment variables for service discovery

### `.devcontainer/Dockerfile`
- Based on `frappe/bench:latest`
- Adds development tools (git, vim, curl, etc.)
- Adds Python dev tools (black, flake8, pytest, etc.)
- Creates user matching host user (brett/1000)

### `.devcontainer/.env`
- User configuration (brett, UID 1000, GID 1000)
- Database connection settings (frappe-mariadb)
- Redis connection settings (shared services)
- Site configuration (dartwing.localhost)

## Usage Workflow

1. **Start Main Frappe Container** (Required First!)
   ```bash
   cd /home/brett/projects/frappe
   # Open in VSCode and start devcontainer
   ```

2. **Open This Workspace**
   ```bash
   cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe
   # Open in VSCode, click "Reopen in Container"
   ```

3. **Access Shared Frappe Bench**
   ```bash
   cd /workspace/development/frappe-bench
   bench new-app dartwing  # First time only
   bench --site site1.localhost install-app dartwing
   ```

4. **Develop Your App**
   - App code location: `/workspace/development/frappe-bench/apps/dartwing`
   - Changes are immediately visible
   - Main container runs `bench start` (web server)
   - Access at: http://localhost:8081

## Key Benefits

- **Shared Infrastructure**: No duplicate services, saves resources
- **Single Source of Truth**: One Frappe bench shared between workspaces
- **Isolated Development**: Each workspace has its own container
- **Consistent Environment**: All workspaces use the same database/Redis
- **Easy Setup**: No need to initialize Frappe bench again

## Important Notes

- The main Frappe container MUST be running first
- Only the main container should run `bench start`
- Both containers can read/write to the Frappe bench
- Changes in one container are visible in the other
- User permissions are consistent (brett/1000) across containers

## Troubleshooting

### Container fails to start
```bash
# Check main container is running
docker ps | grep frappe-dev

# Check network exists
docker network inspect frappe_frappe-network

# Check volume exists
docker volume inspect frappe-bench-data-frappe
```

### Cannot connect to services
```bash
# From inside dartwing-frappe-dev container
ping frappe-mariadb
ping frappe-redis-cache
```

### Frappe bench not accessible
```bash
# Check volume is mounted
docker inspect dartwing-frappe-dev | grep frappe-bench-data-frappe

# Check bench exists
docker exec dartwing-frappe-dev ls -la /workspace/development/frappe-bench
```

## Version History

- **Initial Setup**: November 16, 2025
  - Configured as secondary workspace
  - Connects to external Frappe infrastructure
  - Shares frappe-bench-data-frappe volume
  - Uses frappe_frappe-network
