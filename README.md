# Dartwing Frappe App

Development workspace for the Dartwing Frappe application. This devcontainer attaches to the existing Frappe infrastructure started from `/home/brett/projects/frappe` and shares the same Frappe bench.

## Prerequisites

- Docker and Docker Compose
- VSCode with Dev Containers extension
- **The main Frappe devcontainer must be running** (from `/home/brett/projects/frappe`)

## Architecture

This workspace:
- **Connects** to the existing `frappe_frappe-network` Docker network
- **Shares** the `frappe-bench-data-frappe` volume with the main Frappe container
- **Uses** the existing Frappe infrastructure (MariaDB, Redis services)
- **Mounts** this project folder at `/workspace` in the container

### Shared Infrastructure

- **Database**: `frappe-mariadb` (shared)
- **Redis Cache**: `frappe-redis-cache` (shared)
- **Redis Queue**: `frappe-redis-queue` (shared)
- **Redis SocketIO**: `frappe-redis-socketio` (shared)
- **Frappe Bench**: `/workspace/development/frappe-bench` (shared volume)

## Getting Started

### 1. Start the Main Frappe Environment

First, ensure the main Frappe devcontainer is running:
```bash
cd /home/brett/projects/frappe
# Open in VSCode and start devcontainer
```

### 2. Open Dartwing Workspace

```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe
```

In VSCode:
- Open this folder
- Click "Reopen in Container" when prompted
- Or use Command Palette: "Dev Containers: Reopen in Container"

### 3. Automatic Setup

The devcontainer automatically runs a setup script on each start that:
- ✅ Configures MariaDB connection
- ✅ Creates `dartwing.localhost` site (if not exists)
- ✅ Creates `dartwing_frappe` app (if not exists)
- ✅ Installs app to site (if not installed)

**The script is idempotent** - safe to run multiple times, only does what's needed.

### 4. Manual Setup (Optional)

If you need to run the setup manually:

```bash
bash /workspace/.devcontainer/setup-dartwing.sh
```

### 5. Access the Application

- **URL**: http://localhost:8081
- **Site**: dartwing.localhost
- **Login**: Administrator / admin
- **App Location**: `/workspace/development/frappe-bench/apps/dartwing_frappe`

## Development

### Project Structure

```
/workspace/                          # This project (dartwing-frappe)
/workspace/development/frappe-bench/ # Shared Frappe bench (volume)
```

### Useful Bench Commands

```bash
cd /workspace/development/frappe-bench

# Create a new app (if not already created)
bench new-app dartwing

# Install app to site
bench --site site1.localhost install-app dartwing

# Run migrations
bench --site site1.localhost migrate

# Clear cache
bench clear-cache

# Access MariaDB
bench --site site1.localhost mariadb

# Watch for changes (if bench is not running in main container)
bench watch
```

### AI Tools Included
- **Claude Code**: Anthropic's AI assistant
- **Cody**: Sourcegraph's AI coding assistant  
- **Continue**: Open-source AI code assistant

### Python Tools
- Black (formatter)
- isort (import organizer)
- flake8 (linter)
- pytest (testing)
- ipython (interactive shell)

## Configuration

- `.devcontainer/.env`: Environment variables (already configured for shared infrastructure)
- `.devcontainer/devcontainer.json`: VSCode devcontainer config
- `.devcontainer/docker-compose.yml`: Lightweight container that connects to existing network
- `.devcontainer/Dockerfile`: Development container image with tools

## Important Notes

- **Always start the main Frappe devcontainer first** (from `/home/brett/projects/frappe`)
- This container shares the Frappe bench volume - changes are visible in both containers
- User permissions match your host user (`brett`)
- The main container runs `bench start` - this container is for development only
- Both containers can access the same database and Redis instances

## Troubleshooting

### Container won't start
- Ensure the main Frappe devcontainer is running
- Check that `frappe_frappe-network` exists: `docker network ls | grep frappe`
- Check that volume exists: `docker volume ls | grep frappe-bench-data`

### Can't connect to database
- Verify `frappe-mariadb` container is running: `docker ps | grep mariadb`
- Check network connectivity from inside container: `ping frappe-mariadb`
