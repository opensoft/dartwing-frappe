# Dartwing Frappe Architecture

## Container Overview

You have **TWO development containers** that share infrastructure:

### Container 1: `frappe-dev` (Primary)
- **Location**: `/home/brett/projects/frappe`
- **Purpose**: Main Frappe development environment
- **Role**: Runs `bench start` to serve the Frappe application
- **Ports**: None directly (uses nginx)
- **Mounts**: 
  - Host: `/home/brett/projects/frappe` → Container: `/workspace`
  - Volume: `frappe-bench-data-frappe` → `/workspace/development/frappe-bench`

### Container 2: `dartwing-frappe-dev` (Secondary)
- **Location**: `/home/brett/projects/dartwingers/dartwing/dartwing-frappe`
- **Purpose**: Dartwing app development workspace
- **Role**: Development environment ONLY (does not run bench start)
- **Ports**: None
- **Mounts**:
  - Host: `/home/brett/projects/dartwingers/dartwing/dartwing-frappe` → Container: `/workspace`
  - Volume: `frappe-bench-data-frappe` → `/workspace/development/frappe-bench` (SHARED!)

## Shared Infrastructure

Both containers connect to the same infrastructure:

### Network: `frappe_frappe-network`
All containers communicate over this Docker network.

### Database: `frappe-mariadb`
- Image: `mariadb:10.6`
- Port: `3306` (internal)
- Accessible as `frappe-mariadb:3306` from both dev containers

### Redis Services
- `frappe-redis-cache` (cache)
- `frappe-redis-queue` (job queue)
- `frappe-redis-socketio` (real-time)
- All accessible on port `6379` internally

### Web Server: `frappe-nginx`
- Image: `nginx:alpine`
- Port: `8081` (mapped to host)
- Proxies requests to Frappe bench
- **URL**: http://localhost:8081

### Shared Volume: `frappe-bench-data-frappe`
This is the KEY to the architecture! Both containers mount the same volume at:
```
/workspace/development/frappe-bench
```

This means:
- ✓ Both containers see the same Frappe bench
- ✓ Both containers can edit the same code
- ✓ Changes in one container are visible in the other
- ✓ Both containers access the same apps, sites, config

## Port Summary

| Service | Port | Usage |
|---------|------|-------|
| Frappe Web UI | 8081 | External access to Frappe |
| Dartwing App | 8080 | Your main Dartwing Flutter app |
| MariaDB | 3306 | Internal only |
| Redis | 6379 | Internal only |

**No port conflicts!** Each service uses a different port.

## How It Works

### Starting Up

1. **Start Main Container** (`frappe-dev`)
   ```bash
   cd /home/brett/projects/frappe
   # Open in VSCode → Reopen in Container
   ```

2. **Start Frappe Server** (inside `frappe-dev`)
   ```bash
   cd /workspace/development/frappe-bench
   bench start
   ```
   This starts the Frappe web server that nginx proxies to.

3. **Start Dartwing Container** (`dartwing-frappe-dev`)
   ```bash
   cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe
   # Open in VSCode → Reopen in Container
   ```

4. **Develop Dartwing App** (inside `dartwing-frappe-dev`)
   ```bash
   cd /workspace/development/frappe-bench
   bench new-app dartwing
   bench --site site1.localhost install-app dartwing
   # Edit code in apps/dartwing/
   ```

### Development Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                      Your Host Machine                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  /home/brett/projects/frappe/                               │
│  ├── .devcontainer/                                         │
│  └── ... (general Frappe dev files)                         │
│                                                              │
│  /home/brett/projects/dartwingers/dartwing/dartwing-frappe/ │
│  ├── .devcontainer/                                         │
│  └── ... (Dartwing app specific files)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                            ↓↓↓
┌─────────────────────────────────────────────────────────────┐
│                    Docker Infrastructure                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐                  ┌──────────────────┐    │
│  │ frappe-dev   │                  │ dartwing-frappe- │    │
│  │              │                  │      dev         │    │
│  │ /workspace/  │◄────────────────►│ /workspace/      │    │
│  └──────┬───────┘                  └────────┬─────────┘    │
│         │                                   │               │
│         └───────────────┬───────────────────┘               │
│                         ↓                                   │
│              ┌─────────────────────┐                        │
│              │ frappe-bench-data-  │                        │
│              │      frappe         │                        │
│              │  (SHARED VOLUME)    │                        │
│              │                     │                        │
│              │ /workspace/         │                        │
│              │  development/       │                        │
│              │   frappe-bench/     │                        │
│              │    ├── apps/        │                        │
│              │    │   ├── frappe   │                        │
│              │    │   ├── erpnext  │                        │
│              │    │   └── dartwing │                        │
│              │    ├── sites/       │                        │
│              │    └── config/      │                        │
│              └──────────┬──────────┘                        │
│                         │                                   │
│         ┌───────────────┼───────────────┐                   │
│         ↓               ↓               ↓                   │
│  ┌──────────┐  ┌────────────┐  ┌──────────────┐           │
│  │ mariadb  │  │   redis    │  │    nginx     │           │
│  │  :3306   │  │   :6379    │  │ 8081→80      │           │
│  └──────────┘  └────────────┘  └──────┬───────┘           │
│                                        │                    │
└────────────────────────────────────────┼────────────────────┘
                                         ↓
                                  http://localhost:8081
```

## Key Benefits

1. **No Duplication**: Only one Frappe bench, one database, one set of Redis services
2. **Consistent State**: Both containers see the same data and code
3. **Resource Efficient**: Shared infrastructure uses less memory/CPU
4. **Isolated Workspaces**: Each container can have different VSCode settings, extensions, etc.
5. **Flexible Development**: Work on general Frappe code in one container, Dartwing app in the other

## Important Rules

1. **Only run `bench start` in ONE container** (usually `frappe-dev`)
2. **Always start `frappe-dev` first** (creates the infrastructure)
3. **Both containers can edit code**, but server runs in `frappe-dev`
4. **nginx must be running** for web access at http://localhost:8081
5. **Port 8081 is for Frappe**, port 8080 is for your Dartwing Flutter app

## Common Tasks

### Access Frappe Web UI
1. Ensure `bench start` is running in `frappe-dev`
2. Ensure `frappe-nginx` container is running
3. Visit: http://localhost:8081

### Create Dartwing App
```bash
# In either container (usually dartwing-frappe-dev)
cd /workspace/development/frappe-bench
bench new-app dartwing
bench --site site1.localhost install-app dartwing
```

### Edit Dartwing Code
```bash
# In either container
cd /workspace/development/frappe-bench/apps/dartwing
# Edit files here
```

### Run Migrations
```bash
# In either container
cd /workspace/development/frappe-bench
bench --site site1.localhost migrate
```

### Access Database
```bash
# In either container
cd /workspace/development/frappe-bench
bench --site site1.localhost mariadb
```

## Troubleshooting

### Web UI shows 502 Bad Gateway
- `bench start` is not running in `frappe-dev`
- Solution: Open terminal in `frappe-dev` and run `bench start`

### Changes not visible
- Check you're editing in the shared volume: `/workspace/development/frappe-bench/apps/dartwing`
- Clear cache: `bench clear-cache`
- Restart bench: Stop and start `bench start` again

### Port 8081 already in use
- Check what's using it: `docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8081`
- You may need to stop another service or change the nginx port

### Container won't start
- Ensure main `frappe-dev` container is running first
- Check network exists: `docker network ls | grep frappe_frappe-network`
- Check volume exists: `docker volume ls | grep frappe-bench-data-frappe`
