# Multi-Branch Frappe Development Architecture

## Problem Statement

This architecture enables parallel development across multiple branches (Alpha, Bravo, Charlie, etc.) where each branch gets:
- Its own isolated bench instance
- Its own clone of the dartwing-frappe devcontainer configuration
- Its own clone of the frappe-app-dartwing application code
- Its own site with unique ports
- All sharing the same infrastructure services (MariaDB, Redis, etc.)

## Two Repository Structure

This setup uses two separate GitHub repositories:

1. **dartwing-frappe** (`git@github.com:opensoft/dartwing-frappe.git`) - Devcontainer configuration management
2. **frappe-app-dartwing** (`git@github.com:opensoft/frappe-app-dartwing.git`) - The actual Frappe application code

## Directory Structure

```
/home/brett/projects/dartwingers/dartwing/
├── dartwing-frappe/                    # Template repo (container config)
│   ├── .devcontainer/
│   │   ├── devcontainer.json
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   ├── .env.example
│   │   └── setup scripts
│   └── scripts/
│       └── new-dartwing-container.sh   # Script to create new instances
├── frappe-app-dartwing/                # Template repo (application code)
│   └── dartwing/                       # Python package
├── frappe-alpha/                       # Instance 1 (CLONE of dartwing-frappe)
│   ├── .devcontainer/
│   │   ├── devcontainer.json
│   │   ├── docker-compose.yml
│   │   ├── Dockerfile
│   │   └── .env                        # Configured for alpha
│   └── frappe-bench/
│       └── apps/
│           └── frappe-app-dartwing/    # CLONE (can be on any branch)
├── frappe-bravo/                       # Instance 2 (CLONE of dartwing-frappe)
│   ├── .devcontainer/
│   │   ├── .env                        # Configured for bravo
│   │   └── ...
│   └── frappe-bench/
│       └── apps/
│           └── frappe-app-dartwing/    # CLONE (different branch)
└── frappe-charlie/                     # Instance 3, etc.
```

## Infrastructure Layer (Shared)

The existing frappeBench infrastructure continues to provide:
- MariaDB (frappe-mariadb) - single database server, multiple databases
- Redis services (frappe-redis-cache, frappe-redis-queue, frappe-redis-socketio)
- frappe-network Docker network

Startup command:
```bash
cd /home/brett/projects/workBenches/devBenches/frappeBench
docker compose up -d mariadb redis-cache redis-queue redis-socketio
```

## Branch Instance Layer (Per Branch)

Each frappe-<codename> folder will have:

### 1. Isolated Bench
- Location: `frappe-<codename>/frappe-bench/`
- Initialized with `bench init` pointing to shared MariaDB/Redis
- Separate `sites/` directory for that branch's sites
- Separate Python virtualenv at `frappe-bench/env/`

### 2. Cloned frappe-app-dartwing Repository
- Location: `frappe-<codename>/frappe-bench/apps/frappe-app-dartwing/`
- Cloned via: `git clone git@github.com:opensoft/frappe-app-dartwing.git`
- Can checkout any branch independently
- Each instance has its own complete git repository

### 3. Unique Site
- Site name: `site-<codename>.local` (e.g., site-alpha.local)
- Bench command: `bench new-site site-<codename>.local --db-name dartwing_<codename>`
- App installation: `bench --site site-<codename>.local install-app dartwing`

### 4. Unique Ports
- Alpha: 8001 (host) → 8000 (container)
- Bravo: 8002 (host) → 8000 (container)
- Charlie: 8003 (host) → 8000 (container)
- Pattern: 8000 + index (1, 2, 3, etc.)

### 5. Docker Compose Configuration
Each instance uses same `docker-compose.yml` but with different service name (via .env):
- Service name: `bench-<codename>` (templated via .env)
- Container name: `frappe-<codename>` (from .env: CONTAINER_NAME)
- Connects to external `frappe-network`
- Mounts its own `frappe-bench/` directory
- Environment variables point to shared infra (DB_HOST=frappe-mariadb, etc.)
- Unique port mapping (from .env: HOST_PORT)

### 6. Devcontainer Configuration
Each `frappe-<codename>/.devcontainer/devcontainer.json`:
```json
{
  "name": "Frappe Alpha",
  "dockerComposeFile": "docker-compose.yml",
  "service": "bench-alpha",
  "workspaceFolder": "/workspace/frappe-bench/apps/frappe-app-dartwing",
  "shutdownAction": "stopCompose"
}
```

## User Workflow

### Creating a New Branch Instance
```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe
./scripts/new-dartwing-container.sh feature/new-api
# Output: Created frappe-alpha for branch feature/new-api on port 8001
```

### Opening in VS Code
```bash
cd /home/brett/projects/dartwingers/dartwing/frappe-alpha
code .
# VS Code → Reopen in Container
# Works on: /workspace/frappe-bench/apps/frappe-app-dartwing
```

### Starting Development
```bash
# Inside devcontainer terminal
cd /workspace/frappe-bench
bench start
# Site available at: http://localhost:8001
```

### Working with Multiple Branches
- Open frappe-alpha in VS Code instance 1 → port 8001
- Open frappe-bravo in VS Code instance 2 → port 8002
- Both can run simultaneously
- Each has isolated bench, site, and database

### Cleaning Up
```bash
cd /home/brett/projects/dartwingers/dartwing
rm -rf frappe-alpha
# Optionally drop database: 
docker exec frappe-mariadb mysql -uroot -pfrappe -e "DROP DATABASE dartwing_alpha;"
```

## Automation Script

The `new-dartwing-container.sh` script handles all setup automatically.

### Inputs
- Optional: Branch name for frappe-app-dartwing (e.g., "feature/new-api") - defaults to "main"
- Optional: Codename (auto-generates next available if not provided)

### Steps
1. **Verify Infrastructure**
   - Check that frappe-network exists: `docker network inspect frappe-network`
   - Check that MariaDB and Redis containers are running
   - If not running, start infrastructure

2. **Determine Codename**
   - List existing `frappe-*` directories in `/home/brett/projects/dartwingers/dartwing/`
   - Generate next codename from NATO phonetic alphabet (Alpha, Bravo, Charlie, Delta, Echo, Foxtrot, Golf, Hotel, India, Juliet, Kilo, Lima, Mike, November, Oscar, Papa, Quebec, Romeo, Sierra, Tango, Uniform, Victor, Whiskey, Xray, Yankee, Zulu)
   - Determine next available port (8001, 8002, 8003...)
   - Lowercase codename for directory: `frappe-alpha`, `frappe-bravo`, etc.

3. **Clone dartwing-frappe Repo**
   - `cd /home/brett/projects/dartwingers/dartwing/`
   - `git clone git@github.com:opensoft/dartwing-frappe.git frappe-<codename>`
   - This creates a complete, independent clone of the devcontainer configuration

4. **Configure .env File**
   - `cd frappe-<codename>/.devcontainer`
   - Copy `.env.example` to `.env`
   - Update variables:
     - `CODENAME=<codename>` (e.g., alpha)
     - `CONTAINER_NAME=frappe-<codename>`
     - `HOST_PORT=<port>` (e.g., 8001)
     - `SITE_NAME=site-<codename>.local`
     - `DB_NAME=dartwing_<codename>`
     - Keep shared infrastructure settings (DB_HOST=frappe-mariadb, etc.)

5. **Update docker-compose.yml**
   - Modify service name to `bench-<codename>`
   - Set container_name to `frappe-<codename>`
   - Update port mapping: `<port>:8000`
   - Ensure it connects to external `frappe-network`

6. **Update devcontainer.json**
   - Set name to `Frappe <Codename>`
   - Set service to `bench-<codename>`
   - Set workspaceFolder to `/workspace/frappe-bench/apps/frappe-app-dartwing`

7. **Initialize Bench (inside temporary container or on host)**
   - Create `frappe-<codename>/frappe-bench/` directory
   - Run `bench init` pointing to shared MariaDB/Redis
   - Configure `sites/common_site_config.json` with:
     - `db_host`: frappe-mariadb
     - `redis_cache`: frappe-redis-cache:6379
     - `redis_queue`: frappe-redis-queue:6379
     - `redis_socketio`: frappe-redis-socketio:6379

8. **Clone frappe-app-dartwing**
   - `cd frappe-<codename>/frappe-bench/apps/`
   - `git clone git@github.com:opensoft/frappe-app-dartwing.git`
   - `cd frappe-app-dartwing`
   - If branch specified: `git checkout <branch>`
   - This is the repo you'll work in - can be on any branch

9. **Install App in Bench**
   - `cd frappe-<codename>/frappe-bench`
   - `bench get-app frappe-app-dartwing` (registers the app)
   - Or manually add to `apps.txt`

10. **Create Site**
    - `bench new-site site-<codename>.local --db-name dartwing_<codename> --admin-password admin --db-root-password frappe --no-mariadb-socket`
    - `bench --site site-<codename>.local install-app dartwing`
    - `bench use site-<codename>.local`

11. **Create Instance Info File**
    - Create `frappe-<codename>/INSTANCE_INFO.md` with:
      - Codename
      - Port
      - Branch (of frappe-app-dartwing)
      - Database name
      - Site name
      - Creation date

## Configuration Management

### .env File Configuration
The dartwing-frappe repo should be updated to use .env variables throughout:
- `CODENAME` - alpha, bravo, charlie (used in service names, site names, etc.)
- `CONTAINER_NAME` - frappe-alpha, frappe-bravo, etc.
- `HOST_PORT` - 8001, 8002, 8003, etc.
- `SITE_NAME` - site-alpha.local, site-bravo.local, etc.
- `DB_NAME` - dartwing_alpha, dartwing_bravo, etc.
- `DB_HOST` - frappe-mariadb (shared)
- `REDIS_CACHE` - frappe-redis-cache:6379 (shared)
- `REDIS_QUEUE` - frappe-redis-queue:6379 (shared)
- `REDIS_SOCKETIO` - frappe-redis-socketio:6379 (shared)

### Files to Update in dartwing-frappe Template
- `docker-compose.yml` - use ${CONTAINER_NAME}, ${HOST_PORT}, service name from ${CODENAME}
- `devcontainer.json` - use service name from .env
- `.env.example` - document all variables
- Setup scripts - read from .env

## Key Design Decisions

### Why Separate Clones?
- Complete independence - each instance is fully isolated
- Simpler mental model than worktrees
- Each clone can have different remotes if needed
- Easy cleanup - just delete the directory
- No shared .git complexity

### Why Separate Benches?
- Complete isolation between branches
- Different dependencies per branch possible
- No conflicts in sites/, logs/, or env/
- Easier debugging (separate logs)

### Why Shared Infrastructure?
- Single MariaDB instance (separate databases)
- Reduces resource usage
- Faster startup (infra already running)
- Centralized infrastructure management

### Why Dynamic Codenames?
- Human-readable identifiers
- Easy to remember and reference
- Ordered (NATO alphabet)
- No confusion with branch names

## Testing Strategy

1. Create Alpha instance with main branch
2. Create Bravo instance with devcontainer branch
3. Start both simultaneously
4. Verify isolation (different ports, databases, sites)
5. Test git operations in both clones (commit, push, pull)
6. Test bench commands in both instances
7. Verify each can checkout different branches independently
8. Clean up both instances

## Migration Path

### Phase 1: Setup Infrastructure
1. Ensure frappeBench infrastructure is running
2. Update dartwing-frappe template files to use .env
3. Create automation script

### Phase 2: First Instance
1. Create frappe-alpha from main branch
2. Verify full functionality
3. Document any issues

### Phase 3: Multiple Instances
1. Create frappe-bravo from devcontainer branch
2. Test parallel operation
3. Verify isolation

### Phase 4: Cleanup Old Approach
1. Archive existing dartwing-frappe devcontainer setup if needed
2. Update documentation
3. Add this workflow to team docs
