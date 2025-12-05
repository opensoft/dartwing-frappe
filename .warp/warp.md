# Dartwing Frappe App - Warp Instructions

## Project Overview

This is a **secondary devcontainer workspace** for Dartwing Frappe app development that:
- **Attaches** to the existing Frappe infrastructure from `/home/brett/projects/frappe`
- **Shares** the Frappe bench volume (`frappe-bench-data-frappe`)
- **Connects** to the existing MariaDB and Redis services
- **Provides** an isolated development environment for the Dartwing app

## Architecture

### Main Frappe Container (Primary)
- Location: `/home/brett/projects/frappe`
- Container: `frappe-dev`
- Purpose: Runs the Frappe bench and web server
- Network: `frappe_frappe-network`
- Volume: `frappe-bench-data-frappe`

### Dartwing Container (Secondary - This Workspace)
- Location: `/home/brett/projects/dartwingers/dartwing/dartwing-frappe`
- Container: `dartwing-frappe-dev`
- Purpose: Development workspace for Dartwing app
- Network: `frappe_frappe-network` (shared)
- Volume: `frappe-bench-data-frappe` (shared)

### Shared Infrastructure
- `frappe-mariadb`: Database (10.6)
- `frappe-redis-cache`: Cache service
- `frappe-redis-queue`: Queue service
- `frappe-redis-socketio`: SocketIO service
- `frappe-nginx`: Web server (port 8081)

## Quick Start

### Prerequisites
**The main Frappe devcontainer MUST be running first!**

```bash
# Start main Frappe container first
cd /home/brett/projects/frappe
# Open in VSCode and start devcontainer
```

### Open This Workspace

```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe

# Open in VSCode
# Click "Reopen in Container"
```

### Develop Your App

```bash
# Inside the container, access shared Frappe bench
cd /workspace/development/frappe-bench

# Create Dartwing app (first time)
bench new-app dartwing

# Install to site
bench --site site1.localhost install-app dartwing

# Make changes to your app in /workspace/development/frappe-bench/apps/dartwing
```

## Devcontainer Files

- **Dockerfile**: Development image with Python tools
- **docker-compose.yml**: Lightweight container connecting to external network/volumes
- **devcontainer.json**: VSCode integration referencing external infrastructure
- **.env**: Environment variables (pre-configured for shared setup)

## Key Differences from Main Container

| Aspect | Main Container | Dartwing Container |
|--------|---------------|-------------------|
| Purpose | Runs Frappe bench | App development |
| Services | Creates all services | Uses existing services |
| Volumes | Creates volumes | References volumes |
| Network | Creates network | References network |
| bench start | Yes, runs server | No, uses main container's server |

## Development Workflow

1. Main container runs `bench start` (web server)
2. This container is used for:
   - Creating/modifying Dartwing app code
   - Running migrations
   - Testing features
   - Database access
3. Changes are immediately visible at http://localhost:8081
4. Both containers share the same Frappe bench

## AI Development Tools

- **Claude Code** (anthropic.claude-dev)
- **Cody** (sourcegraph.cody-ai)
- **Continue** (continue.continue)
- All pre-configured in devcontainer.json

## Troubleshooting

### Container won't start
```bash
# Check main Frappe container is running
docker ps | grep frappe

# Check network exists
docker network ls | grep frappe_frappe-network

# Check volume exists
docker volume ls | grep frappe-bench-data-frappe
```

### Can't access database
```bash
# From inside container
ping frappe-mariadb

# Test database connection
cd /workspace/development/frappe-bench
bench --site site1.localhost mariadb
```

## Multi-Branch Development

For working on multiple branches simultaneously, see:
- [Multi-Branch Setup Documentation](.warp/multi-branch-setup.md)
- Script: `scripts/new-multibranch.sh`

This allows you to run multiple isolated instances (alpha, bravo, charlie, etc.) each with different branches of the app.

## Git Repository

This folder is its own git repository for the Dartwing app, separate from the main dartwing repo.
