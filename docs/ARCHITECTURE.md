# Dartwing Frappe Development Environment - Complete Architecture Guide

This document provides comprehensive documentation for the Dartwing Frappe development environment, including architecture, setup, configuration, and troubleshooting.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Multi-Branch Workflow](#multi-branch-workflow)
- [Development](#development)
- [AI Coding Assistant Setup](#ai-coding-assistant-setup)
- [User Configuration](#user-configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Configuration Reference](#configuration-reference)

## Overview

The Dartwing Frappe development environment provides isolated Frappe bench instances for parallel development while sharing common infrastructure (MariaDB, Redis). This allows multiple developers or features to work independently without conflicts.

### Key Features

- **Isolated Benches** - Each workspace maintains its own Frappe bench with independent Python virtualenv, sites, and app clones
- **Shared Infrastructure** - All workspaces connect to shared MariaDB and Redis services via Docker network
- **Multi-Branch Support** - Create unlimited parallel workspaces (alpha-frappe, bravo-frappe, etc.) for different features or branches
- **Automated Setup** - Scripts handle environment setup, bench initialization, and app installation
- **Dynamic User Configuration** - Container user automatically matches host user to avoid permission issues
- **AI Assistant Integration** - Optional mounts for Claude, Copilot, and other AI coding assistants

## Architecture

### Isolated Bench Model

Each workspace (dartwing-frappe, alpha-frappe, bravo-frappe, etc.) maintains complete independence:

**Independent Components:**
- Frappe bench directory (`development/frappe-bench/`)
- Python virtual environment
- Frappe sites and configurations
- Database (separate database per workspace)
- Clone of frappe-app-dartwing repository

**Benefits:**
- No conflicts between branches or features
- Safe to experiment without affecting other work
- Each workspace can run different Frappe versions if needed
- Easy to create and destroy workspaces

### Shared Infrastructure

All workspaces connect to common services via `frappe-network`:

**Shared Services:**
- **frappe-mariadb** - MariaDB 10.6 container (hosts multiple databases)
- **frappe-redis-cache** - Redis cache service
- **frappe-redis-queue** - Redis queue service
- **frappe-redis-socketio** - Redis SocketIO service

**Network:**
- External Docker network: `frappe-network`
- Created by frappeBench infrastructure
- All containers connect to this network

**Benefits:**
- Resource efficient (single MariaDB/Redis instead of duplicates)
- Consistent infrastructure across workspaces
- Centralized management
- Faster workspace creation

### Directory Structure

```
/home/brett/projects/dartwingers/dartwing/
├── dartwing-frappe/                   # Main development workspace
│   ├── .devcontainer/
│   │   ├── .env                       # Environment configuration
│   │   ├── .env.example               # Configuration template
│   │   ├── devcontainer.json          # VSCode devcontainer config
│   │   ├── docker-compose.yml         # Container definition
│   │   ├── Dockerfile                 # Development image
│   │   └── ...
│   ├── development/
│   │   └── frappe-bench/              # Isolated Frappe bench
│   │       ├── apps/
│   │       │   ├── frappe/           # Frappe framework (installed by bench init)
│   │       │   └── frappe-app-dartwing/  # Your application
│   │       ├── sites/
│   │       │   └── dartwing.localhost/
│   │       ├── env/                   # Python virtualenv
│   │       └── ...
│   ├── docs/
│   │   ├── ARCHITECTURE.md            # This file
│   │   └── MULTI_BRANCH_ARCHITECTURE.md
│   ├── scripts/
│   ├── setup.sh                       # Initial host-side setup
│   ├── init-bench.sh                  # Container bench initialization
│   └── new-branch.sh                  # Create branch workspace
│
├── alpha-frappe/                      # Branch workspace 1
│   ├── .devcontainer/
│   │   └── .env                       # Configured for alpha
│   └── development/
│       └── frappe-bench/              # Independent bench
│
├── bravo-frappe/                      # Branch workspace 2
│   ├── .devcontainer/
│   │   └── .env                       # Configured for bravo
│   └── development/
│       └── frappe-bench/              # Independent bench
│
└── charlie-frappe/                    # Branch workspace 3
    └── ...
```

### Container Architecture

Each workspace runs a lightweight container that:
- Connects to external `frappe-network`
- Mounts the workspace directory at `/workspace`
- Has Docker CLI access via socket mount
- Matches host user UID/GID for correct permissions
- Runs bench commands in isolated environment

## Getting Started

### Prerequisites

- Docker and Docker Compose installed
- VSCode with Dev Containers extension
- Frappe infrastructure running (MariaDB, Redis)
- SSH keys configured for GitHub access

### Infrastructure Setup

Start the shared Frappe infrastructure (one time):

```bash
cd /home/brett/projects/workBenches/devBenches/frappeBench
docker compose up -d mariadb redis-cache redis-queue redis-socketio
```

Verify infrastructure is running:
```bash
docker ps | grep frappe
docker network ls | grep frappe-network
```

### First-Time Workspace Setup

1. **Clone Repository**
   ```bash
   cd /home/brett/projects/dartwingers/dartwing
   git clone git@github.com:opensoft/dartwing-frappe.git
   cd dartwing-frappe
   ```

2. **Run Setup Script**
   ```bash
   ./scripts/setup.sh
   ```
   
   This script:
   - Creates `.env` from `.env.example`
   - Creates `development/frappe-bench/apps/` folder structure
   - Clones `frappe-app-dartwing` into the apps folder

3. **Open in VSCode**
   ```bash
   code .
   ```
   
   When prompted, click **"Reopen in Container"**

4. **Wait for Automatic Initialization**
   
   The container will automatically run `scripts/init-bench.sh` which:
   - Initializes Frappe bench (takes 5-10 minutes first time)
   - Configures database and Redis connections
   - Creates site with database
   - Installs dartwing app
   - Marks setup complete

5. **Start Development Server**
   ```bash
   # Inside container terminal
   cd /workspace/development/frappe-bench
   bench start
   ```

6. **Access Application**
   - URL: http://localhost:8081
   - Username: Administrator
   - Password: admin

## Multi-Branch Workflow

### Creating Additional Workspaces

Create parallel development environments for different features or branches:

```bash
cd dartwing-frappe
./scripts/new-branch.sh alpha
```

This creates `../alpha-frappe/` with:
- Complete clone of dartwing-frappe repository
- `.env` file with `CODENAME=alpha`
- Folder structure created
- frappe-app-dartwing cloned

### Opening the New Workspace

```bash
cd ../alpha-frappe
code .
# Click "Reopen in Container"
# Wait for automatic bench initialization
```

### Use Cases

**Multiple Features Simultaneously:**
```bash
# Feature A in alpha-frappe
./scripts/new-branch.sh alpha
cd ../alpha-frappe
# Edit .env to set HOST_PORT=8082 if running simultaneously
code .

# Feature B in bravo-frappe  
./scripts/new-branch.sh bravo
cd ../bravo-frappe
# Edit .env to set HOST_PORT=8083
code .

# Both can run bench start in parallel
```

**Testing Different Branches:**
Each workspace can independently checkout different branches of frappe-app-dartwing:

```bash
# In alpha-frappe container
cd /workspace/development/frappe-bench/apps/frappe-app-dartwing
git checkout feature-branch-1

# In bravo-frappe container  
cd /workspace/development/frappe-bench/apps/frappe-app-dartwing
git checkout feature-branch-2
```

### Workspace Isolation

Each workspace has:
- **Independent database**: dartwing, dartwing_alpha, dartwing_bravo
- **Independent site**: dartwing.localhost, site-alpha.local, site-bravo.local
- **Independent bench**: Complete separation of apps, sites, configs
- **Independent port**: 8081 (default), 8082, 8083, etc.

### Cleanup

Remove a workspace when done:

```bash
cd /home/brett/projects/dartwingers/dartwing
rm -rf alpha-frappe

# Optionally drop the database
docker exec frappe-mariadb mysql -uroot -pfrappe -e "DROP DATABASE dartwing_alpha;"
```

## Development

### Project Structure in Container

```
/workspace/                            # Workspace root
├── .devcontainer/                    # Container configuration
│   ├── .env                          # Environment variables
│   ├── devcontainer.json             # VSCode devcontainer config
│   └── ...
├── development/
│   └── frappe-bench/                 # Frappe bench
│       ├── apps/
│       │   ├── frappe/              # Frappe framework
│       │   └── frappe-app-dartwing/ # Your application code
│       ├── sites/
│       │   └── dartwing.localhost/
│       ├── env/                      # Python virtualenv
│       ├── config/
│       ├── logs/
│       └── ...
├── scripts/
├── docs/
└── ...
```

### Common Commands

#### Bench Commands

```bash
# Navigate to bench directory
cd /workspace/development/frappe-bench

# Start development server
bench start

# Run migrations
bench --site dartwing.localhost migrate

# Clear cache
bench clear-cache

# Access database console
bench --site dartwing.localhost mariadb

# Access Python console
bench --site dartwing.localhost console

# Run tests
bench --site dartwing.localhost run-tests --app dartwing

# Install new app
bench get-app <app-name>
bench --site dartwing.localhost install-app <app-name>

# List installed apps
bench --site dartwing.localhost list-apps

# Backup site
bench --site dartwing.localhost backup

# Restore backup
bench --site dartwing.localhost restore <backup-file>
```

#### Git Commands (for your app)

```bash
cd /workspace/development/frappe-bench/apps/frappe-app-dartwing

# Standard git operations
git status
git add .
git commit -m "message"
git push
git pull
git checkout <branch>
```

### Setup Scripts

#### scripts/setup.sh (Host-side)

Run once before opening workspace in VSCode.

**Purpose:**
- Prepare workspace for container initialization
- Create environment configuration
- Clone application repository

**What it does:**
1. Creates `.env` from `.env.example`
2. Creates folder structure: `development/frappe-bench/apps/`
3. Clones frappe-app-dartwing repository

**Usage:**
```bash
./scripts/setup.sh
```

#### scripts/init-bench.sh (Container-side)

Runs automatically as `postCreateCommand` when container starts.

**Purpose:**
- Initialize Frappe bench in container
- Configure infrastructure connections
- Create site and install apps

**What it does:**
1. Checks if setup already completed (idempotent)
2. Loads environment variables from `.env`
3. Initializes Frappe bench (version-15)
4. Configures common_site_config.json with infrastructure settings
5. Registers apps with bench (from `APPS_TO_INSTALL` env var)
6. Creates site with specified database name
7. Installs apps on site
8. Sets default site
9. Creates setup complete marker

**Environment Variables Used:**
- `SITE_NAME` - Site to create
- `DB_NAME` - Database name
- `CODENAME` - Workspace identifier
- `APPS_TO_INSTALL` - Comma-separated list of apps (default: "dartwing")

**Note:** This script is automatic. To re-run:
```bash
# Remove marker and rebuild container
docker exec dartwing-frappe-dev rm /workspace/development/.setup_complete
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

#### scripts/new-branch.sh (Host-side)

Creates new branch workspace.

**Purpose:**
- Quickly create parallel development environments
- Clone configuration and setup

**What it does:**
1. Determines target directory: `../<name>-frappe/`
2. Clones dartwing-frappe repository
3. Creates `.env` with updated `CODENAME`
4. Creates folder structure
5. Clones frappe-app-dartwing

**Usage:**
```bash
./scripts/new-branch.sh <workspace-name>

# Examples:
./scripts/new-branch.sh alpha
./scripts/new-branch.sh feature-auth
./scripts/new-branch.sh bugfix-123
```

### Development Tools

#### Python Tools

Pre-installed in container:
- **Black** - Code formatter
- **isort** - Import organizer
- **flake8** - Linter
- **pylint** - Code analysis
- **pytest** - Testing framework
- **ipython** - Interactive shell

#### Editor Features

VSCode extensions included:
- Python language support
- Pylance type checking
- Black formatter integration
- Docker support
- Git integration
- AI coding assistants (if configured)

#### Shell Environment

- **Default shell**: Zsh with Oh My Zsh
- **Powerline10k** theme
- **Host configurations mounted**: .zshrc, .bashrc
- **Git config mounted**: .gitconfig
- **SSH keys mounted**: For GitHub access

## AI Coding Assistant Setup

Configure AI coding assistants to work seamlessly in the container by mounting authentication directories.

### Supported Assistants

- **OpenAI Codex** - ChatGPT/GPT-4 code assistance
- **Claude Code** - Anthropic's Claude AI
- **GitHub Copilot** - GitHub's AI pair programmer
- **Google Gemini** - Google's AI assistant
- **Cody** - Sourcegraph's code intelligence
- **Continue** - Open-source AI code assistant

### Quick Setup

**1. Check for Authentication Files**

On your host machine:
```bash
ls ~/.codex ~/.claude ~/.gemini
```

If these directories exist, you're authenticated.

**2. Create Override File**

```bash
cd .devcontainer
cp docker-compose.override.example.yml docker-compose.override.yml
```

**3. Edit Override File**

Open `docker-compose.override.yml` and uncomment the AI tools you use:

```yaml
services:
  dartwing-dev:
    volumes:
      # Uncomment the lines for AI tools you use:
      - ~/.codex:/home/${USER}/.codex:cached
      - ~/.claude:/home/${USER}/.claude:cached
      - ~/.gemini:/home/${USER}/.gemini:cached
```

**4. Rebuild Container**

- In VSCode: `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
- Select: **Dev Containers: Rebuild Container**
- Wait for container to rebuild

**5. Verify Inside Container**

```bash
# Inside container terminal
ls ~/.codex ~/.claude ~/.gemini
```

You should see your authentication files mounted.

### Initial Authentication (if needed)

If you haven't authenticated with AI tools on your host yet:

**OpenAI Codex:**
```bash
# On host machine
npm install -g @openai/codex
codex login
# Follow browser authentication flow
```

**Claude Code:**
```bash
# On host machine
npm install -g @anthropic-ai/claude-code
claude login
# Enter API key when prompted
```

**GitHub Copilot:**
- Install via VSCode extension
- Sign in through VSCode
- Authentication is handled via VSCode settings

**Google Gemini:**
```bash
# Check Google's documentation for current installation
gemini auth login
```

### How It Works

**Mount Process:**
1. `docker-compose.override.yml` specifies volume mounts
2. Container mounts your host `~/.tool-name` directory to container `~/.tool-name`
3. AI extensions in VSCode read credentials from mounted directories
4. No re-authentication needed in container

**Security:**
- Override file is gitignored (never committed)
- Credentials stay on your host machine
- Container has read-only access (can use `:ro` flag)
- No credentials in Docker images

### Security Best Practices

**1. Never Commit Override Files**

The `.gitignore` includes:
```
.devcontainer/docker-compose.override.yml
```

**2. Use Read-Only Mounts (Optional)**

For extra security:
```yaml
- ~/.codex:/home/${USER}/.codex:ro
- ~/.claude:/home/${USER}/.claude:ro
```

**3. Revoke Access if Compromised**

If your machine is compromised:
- Revoke API keys from provider dashboards
- Regenerate keys
- Re-authenticate

**4. Separate Development Keys**

Consider using separate API keys for development vs. production.

### Troubleshooting

**AI Extension Still Asks for Login**

Check service name in override file:
```bash
# Should match service name in docker-compose.yml
grep "services:" -A 2 .devcontainer/docker-compose.yml
```

**Directories Not Mounted**

Verify inside container:
```bash
ls -la ~/.codex ~/.claude ~/.gemini
```

If empty, rebuild container:
```
Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

**Permission Denied**

Check file permissions on host:
```bash
ls -la ~/.codex ~/.claude ~/.gemini
chmod -R u+r ~/.codex ~/.claude ~/.gemini
```

**Wrong User Path**

Check container user:
```bash
echo $USER
id
```

Should match your host username. If not, rebuild container.

## User Configuration

### Dynamic User Matching

The container automatically creates a user matching your host user to avoid permission issues with mounted files.

### How It Works

**Environment Variables:**

When you build the container, these environment variables are passed from your host:
- `$USER` - Your username (e.g., brett)
- `$UID` - Your user ID (typically 1000)
- `$GID` - Your group ID (typically 1000)

**Build Process:**

1. **docker-compose.yml** reads environment variables:
   ```yaml
   args:
     USERNAME: ${USER:-vscode}
     USER_UID: ${UID:-1000}
     USER_GID: ${GID:-1000}
   ```

2. **Dockerfile** receives build arguments:
   ```dockerfile
   ARG USERNAME
   ARG USER_UID
   ARG USER_GID
   ```

3. **User creation** in Dockerfile:
   - Checks if UID exists (e.g., default `frappe` user)
   - Removes existing user at that UID if needed
   - Creates new user with YOUR username and UID/GID
   - Adds user to necessary groups (docker, sudo)

4. **VSCode configuration** in devcontainer.json:
   ```json
   "remoteUser": "${localEnv:USER}"
   ```

### Verification

Check that user matches inside container:

```bash
# Inside container
whoami
# Output: brett (your username)

id
# Output: uid=1000(brett) gid=1000(brett) groups=1000(brett),1001(docker)
```

Check file ownership:
```bash
ls -la /workspace/development/frappe-bench/
# Files should be owned by your username
```

### Benefits

**For Individual Developers:**
- No permission denied errors
- Files have correct ownership
- No manual UID/GID configuration needed
- Works the same on any machine

**For Teams:**
- Each team member automatically gets correct user
- No hardcoded usernames in configuration
- Works for any UID (1000, 1001, 501, etc.)
- Zero configuration for new team members

### Fallback Values

If environment variables aren't set, defaults are used:
- `USERNAME`: vscode
- `UID`: 1000
- `GID`: 1000

This ensures the container still builds in environments without these variables.

### Troubleshooting

**Container User is Wrong**

If `whoami` shows wrong username:

```bash
# Rebuild container with fresh build
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

**Permission Denied Errors**

Check UID matches between host and container:

```bash
# On host
echo "Host UID: $(id -u)"

# In container
docker exec dartwing-frappe-dev id -u

# Should be the same number
```

If different, rebuild container.

**Files Owned by Wrong User**

This happens if:
- Container was built with wrong UID
- Files were created by a different user

Solution:
```bash
# Rebuild container to get correct UID
# Then fix ownership of existing files:
docker exec dartwing-frappe-dev chown -R $(id -u):$(id -g) /workspace/development/
```

**User Not in Docker Group**

If you can't run docker commands:

```bash
# Check groups
id

# Should include docker(1001) or similar
# If not, rebuild container
```

### Advanced Configuration

**Custom UID/GID:**

If you need specific UID/GID:

```bash
# In .env file
USER=myusername
UID=1234
GID=1234

# Rebuild container
```

**Multiple Users:**

Each team member's environment variables automatically set their user:
- Alice: uid=1000
- Bob: uid=501  
- Carol: uid=1002

No configuration needed - it just works!

## Verification

Use this checklist to verify your environment is correctly configured.

### Pre-Flight Checks (Before Container)

**1. Verify Infrastructure Running**

```bash
docker ps --filter "name=frappe" --format "table {{.Names}}\t{{.Status}}"
```

**Expected:** frappe-mariadb, frappe-redis-cache, frappe-redis-queue, frappe-redis-socketio all running

**2. Verify Network Exists**

```bash
docker network inspect frappe-network
```

**Expected:** Network exists with infrastructure containers connected

**3. Verify Setup Scripts**

```bash
ls -la scripts/setup.sh scripts/init-bench.sh scripts/new-branch.sh
```

**Expected:** All scripts exist and are executable (-rwxr-xr-x)

### Configuration Checks

**4. Validate Docker Compose**

```bash
cd .devcontainer
docker-compose config --quiet
```

**Expected:** No errors (exit code 0)

**5. Check Network Reference**

```bash
docker-compose config | grep -A 1 "frappe-network"
```

**Expected:** Shows `external: true`

**6. Verify .env Exists**

```bash
test -f .devcontainer/.env && echo "✓ .env exists" || echo "✗ .env missing - run scripts/setup.sh"
```

**Expected:** ✓ .env exists

**7. Check Environment Variables**

```bash
grep -E "CODENAME|DB_HOST|SITE_NAME|REDIS" .devcontainer/.env
```

**Expected Output:**
- CODENAME=default (or alpha, bravo, etc.)
- DB_HOST=frappe-mariadb
- SITE_NAME=dartwing.localhost
- REDIS_CACHE=frappe-redis-cache:6379
- REDIS_QUEUE=frappe-redis-queue:6379
- REDIS_SOCKETIO=frappe-redis-socketio:6379

### Post-Container Checks

**8. Verify Container Running**

```bash
docker ps --filter "name=dartwing-frappe-dev"
```

**Expected:** Container is Up

**9. Test Network Connectivity**

```bash
docker exec dartwing-frappe-dev ping -c 1 frappe-mariadb
docker exec dartwing-frappe-dev ping -c 1 frappe-redis-cache
```

**Expected:** Successful ping responses

**10. Verify Bench Directory**

```bash
docker exec dartwing-frappe-dev ls /workspace/development/frappe-bench/
```

**Expected:** Directories: apps/, sites/, config/, env/, logs/

**11. Test Database Connection**

```bash
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench --site dartwing.localhost mariadb --execute 'SELECT 1;'"
```

**Expected:** Returns 1 (successful connection)

**12. Verify User Permissions**

```bash
docker exec dartwing-frappe-dev whoami
docker exec dartwing-frappe-dev id
```

**Expected:** Shows your username and UID (e.g., brett, uid=1000)

**13. Check Workspace Mount**

```bash
docker exec dartwing-frappe-dev ls /workspace/
```

**Expected:** Project files visible (.devcontainer/, development/, scripts/, etc.)

**14. Test Bench Commands**

```bash
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench version"
```

**Expected:** Frappe version information displayed

**15. Verify Site and Apps**

```bash
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench --site dartwing.localhost list-apps"
```

**Expected:** Lists installed apps including dartwing

**16. Check Setup Complete**

```bash
docker exec dartwing-frappe-dev test -f /workspace/development/.setup_complete && echo "✓ Setup complete" || echo "✗ Setup incomplete"
```

**Expected:** ✓ Setup complete

### Success Criteria

All checks should pass:

✓ Frappe infrastructure running  
✓ frappe-network exists  
✓ Setup scripts are executable  
✓ Docker Compose configuration valid  
✓ .env file exists with correct variables  
✓ Container starts successfully  
✓ Network connectivity to infrastructure confirmed  
✓ Bench directory initialized  
✓ Database connection works  
✓ User matches host user  
✓ Bench commands execute  
✓ Site created with apps installed  
✓ Setup complete marker exists  

### Quick Verification Script

Create a script to run all checks:

```bash
#!/bin/bash
# verify-scripts/setup.sh

echo "=== Infrastructure ==="
docker ps | grep frappe
docker network ls | grep frappe-network

echo -e "\n=== Configuration ==="
test -f .devcontainer/.env && echo "✓ .env exists" || echo "✗ .env missing"

echo -e "\n=== Container ==="
docker ps | grep dartwing-frappe-dev

echo -e "\n=== Connectivity ==="
docker exec dartwing-frappe-dev ping -c 1 frappe-mariadb | grep "1 received"

echo -e "\n=== Bench ==="
docker exec dartwing-frappe-dev ls /workspace/development/frappe-bench/sites/dartwing.localhost/ | grep "site_config.json"

echo -e "\n=== Setup Complete ==="
docker exec dartwing-frappe-dev test -f /workspace/development/.setup_complete && echo "✓ Complete" || echo "✗ Incomplete"
```

## Troubleshooting

### Infrastructure Issues

**External Network Not Found**

```bash
# Error: network frappe-network declared as external, but could not be found
```

**Solution:**
```bash
# Start Frappe infrastructure
cd /home/brett/projects/workBenches/devBenches/frappeBench
docker compose up -d mariadb redis-cache redis-queue redis-socketio

# Verify network created
docker network ls | grep frappe-network
```

**Container Won't Start**

```bash
# Check prerequisites
docker network ls | grep frappe-network  # Should exist
docker ps | grep frappe-mariadb          # Should be running
docker ps | grep frappe-redis            # Should be running
```

**Infrastructure Services Not Healthy**

```bash
# Check service health
docker inspect frappe-mariadb --format '{{.State.Health.Status}}'
# Should show: healthy

# If unhealthy, check logs
docker logs frappe-mariadb
docker logs frappe-redis-cache
```

### Setup Issues

**.env File Missing**

```bash
# Error: .env file not found
```

**Solution:**
```bash
# Run setup script
cd dartwing-frappe
./scripts/setup.sh

# Or manually
cp .devcontainer/.env.example .devcontainer/.env
```

**Bench Not Initialized**

```bash
# Error: sites/apps.txt not found
```

**Solution:**
```bash
# Remove setup marker and rebuild
docker exec dartwing-frappe-dev rm -f /workspace/development/.setup_complete

# Rebuild container
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

**Setup Script Fails**

Check the terminal output in VSCode for specific errors:

- **Network error:** Verify infrastructure running
- **Permission error:** Check user configuration
- **Git error:** Verify SSH keys and GitHub access

**scripts/init-bench.sh Takes Too Long**

First-time bench initialization takes 5-10 minutes (downloads and installs Frappe framework). This is normal.

To monitor progress:
```bash
# Watch the terminal in VSCode
# Or check from outside container:
docker logs -f dartwing-frappe-dev
```

### Database Issues

**Can't Connect to Database**

```bash
# Error: Can't connect to MySQL server on 'frappe-mariadb'
```

**Solution:**
```bash
# Verify MariaDB is running
docker ps | grep frappe-mariadb

# Test connection from container
docker exec dartwing-frappe-dev ping -c 1 frappe-mariadb

# Check MariaDB logs
docker logs frappe-mariadb

# Restart MariaDB if needed
docker restart frappe-mariadb
```

**Database Doesn't Exist**

```bash
# Error: Unknown database 'dartwing'
```

**Solution:**
- Check `DB_NAME` in `.env` file
- Verify scripts/init-bench.sh completed successfully
- Check setup complete marker exists:
  ```bash
  docker exec dartwing-frappe-dev test -f /workspace/development/.setup_complete
  ```

**Database Connection Timeout**

```bash
# Error: Lost connection to MySQL server during query
```

**Solution:**
```bash
# Check network connectivity
docker exec dartwing-frappe-dev ping frappe-mariadb

# Verify MariaDB is healthy
docker inspect frappe-mariadb --format '{{.State.Health.Status}}'

# Check MariaDB logs for errors
docker logs frappe-mariadb | tail -50
```

### Application Issues

**Port Already in Use**

```bash
# Error: Bind for 0.0.0.0:8081 failed: port is already allocated
```

**Solution:**
```bash
# Change HOST_PORT in .env
sed -i 's/HOST_PORT=8081/HOST_PORT=8082/' .devcontainer/.env

# Rebuild container
```

**App Not Found**

```bash
# Error: App dartwing not found
```

**Solution:**
```bash
# Check if app was cloned
ls -la development/frappe-bench/apps/frappe-app-dartwing

# If missing, clone it
cd development/frappe-bench/apps
git clone git@github.com:opensoft/frappe-app-dartwing.git

# Register with bench (inside container)
cd /workspace/development/frappe-bench
bench get-app ./apps/frappe-app-dartwing
```

**Site Not Accessible**

```bash
# Browser shows: ERR_CONNECTION_REFUSED
```

**Solution:**
```bash
# Verify bench is running
# Inside container:
cd /workspace/development/frappe-bench
bench status

# If not running, start it:
bench start

# Check port mapping
docker port dartwing-frappe-dev
```

**502 Bad Gateway**

```bash
# Nginx error: 502 Bad Gateway
```

**Solution:**
```bash
# bench start is not running
# Inside container:
cd /workspace/development/frappe-bench
bench start
```

### Permission Issues

**Permission Denied**

```bash
# Error: Permission denied: '/workspace/development/frappe-bench'
```

**Solution:**
```bash
# Check user matches host
echo "Host UID: $(id -u)"
docker exec dartwing-frappe-dev id -u
# Should be the same

# If different, rebuild container
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

**Files Owned by Wrong User**

```bash
# ls shows: root:root or frappe:frappe instead of your user
```

**Solution:**
```bash
# Fix ownership (replace 1000:1000 with your UID:GID)
docker exec dartwing-frappe-dev sudo chown -R 1000:1000 /workspace/development/

# Or rebuild container to fix user configuration
```

**Can't Write to Files**

```bash
# Error: Read-only file system
```

**Solution:**
```bash
# Check volume mounts
docker inspect dartwing-frappe-dev | grep Mounts -A 20

# Verify workspace directory is writable on host
ls -la /home/brett/projects/dartwingers/dartwing/dartwing-frappe
```

### VSCode Issues

**Container Doesn't Rebuild**

```bash
# Changes to Dockerfile not applied
```

**Solution:**
```bash
# Rebuild without cache
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

**Extensions Not Loading**

**Solution:**
```bash
# Reload window
# VSCode: Ctrl+Shift+P → "Developer: Reload Window"

# Or reinstall extensions
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

**Terminal Not Working**

**Solution:**
```bash
# Check default shell
echo $SHELL

# Try different shell
bash
zsh

# Rebuild container if needed
```

## Configuration Reference

### Environment Variables

Complete list of variables in `.env`:

#### Instance Configuration
- **CODENAME** - Workspace identifier (default, alpha, bravo, etc.)
- **CONTAINER_NAME** - Docker container name (dartwing-frappe, frappe-alpha, etc.)
- **HOST_PORT** - Port mapping from host to container (8081 default)

#### Site Configuration
- **SITE_NAME** - Frappe site name (dartwing.localhost, site-alpha.local, etc.)
- **ADMIN_PASSWORD** - Site admin password (default: admin)

#### Database Configuration
- **DB_HOST** - Database host (frappe-mariadb)
- **DB_PORT** - Database port (3306)
- **DB_PASSWORD** - Database password (frappe)
- **DB_NAME** - Database name (dartwing, dartwing_alpha, etc.)

#### Redis Configuration
- **REDIS_CACHE** - Redis cache service (frappe-redis-cache:6379)
- **REDIS_QUEUE** - Redis queue service (frappe-redis-queue:6379)
- **REDIS_SOCKETIO** - Redis SocketIO service (frappe-redis-socketio:6379)

#### App Configuration
- **APP_BRANCH** - Git branch for frappe-app-dartwing (default: main)
- **APPS_TO_INSTALL** - Comma-separated list of apps (default: "dartwing")

#### Bench Configuration
- **FRAPPE_BENCH_PATH** - Path to bench in container (/workspace/development/frappe-bench)

#### User Configuration (Auto-detected)
- **USER** - Your username (from host environment)
- **UID** - Your user ID (from host environment)
- **GID** - Your group ID (from host environment)

### Key Files

#### Configuration Files
- `.devcontainer/.env` - Instance configuration (gitignored)
- `.devcontainer/.env.example` - Configuration template (committed)
- `.devcontainer/devcontainer.json` - VSCode devcontainer configuration
- `.devcontainer/docker-compose.yml` - Container service definition
- `.devcontainer/docker-compose.override.yml` - Local overrides (gitignored)
- `.devcontainer/Dockerfile` - Development container image

#### Script Files
- `scripts/setup.sh` - Host-side initial setup script
- `scripts/init-bench.sh` - Container-side bench initialization script
- `scripts/new-branch.sh` - Branch workspace creation script

#### Documentation Files
- `README.md` - Quick start guide
- `docs/ARCHITECTURE.md` - This file (complete documentation)
- `docs/MULTI_BRANCH_ARCHITECTURE.md` - Multi-branch design details
- `.devcontainer/USER_CONFIGURATION.md` - User configuration details
- `.devcontainer/VERIFICATION.md` - Verification checklist

#### Runtime Files
- `development/.setup_complete` - Marker file indicating setup completed
- `development/frappe-bench/` - Frappe bench directory (created by scripts/init-bench.sh)

### Docker Compose Services

#### dartwing-dev Service

```yaml
services:
  dartwing-dev:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        USERNAME: ${USER}
        USER_UID: ${UID}
        USER_GID: ${GID}
    container_name: ${CONTAINER_NAME}
    user: "${UID}:${GID}"
    volumes:
      - ../:/workspace:cached
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - ~/.zshrc:/home/${USER}/.zshrc:ro
      - ~/.gitconfig:/home/${USER}/.gitconfig:ro
      - ~/.ssh:/home/${USER}/.ssh:ro
    command: sleep infinity
    networks:
      - frappe-network
    environment:
      - DB_HOST=frappe-mariadb
      - REDIS_CACHE=frappe-redis-cache:6379
      - REDIS_QUEUE=frappe-redis-queue:6379
      - REDIS_SOCKETIO=frappe-redis-socketio:6379
```

### Port Assignments

| Workspace | Database | Site | Port |
|-----------|----------|------|------|
| dartwing-frappe | dartwing | dartwing.localhost | 8081 |
| alpha-frappe | dartwing_alpha | site-alpha.local | 8082* |
| bravo-frappe | dartwing_bravo | site-bravo.local | 8083* |
| charlie-frappe | dartwing_charlie | site-charlie.local | 8084* |

*Configure in `.env` if running simultaneously

### Git Configuration

**Repositories:**
- **dartwing-frappe**: git@github.com:opensoft/dartwing-frappe.git
- **frappe-app-dartwing**: git@github.com:opensoft/frappe-app-dartwing.git

**SSH Keys:**
- Host SSH keys mounted into container at `~/.ssh/`
- Enables git operations without re-authentication
- Keys remain secure on host machine

## Support and Resources

### Getting Help

1. **Check this documentation** - Comprehensive guide covering most scenarios
2. **Review verification checklist** - Ensure environment is configured correctly
3. **Check troubleshooting section** - Common issues and solutions
4. **Review logs** - Docker and bench logs often reveal issues

### Additional Documentation

- **MULTI_BRANCH_ARCHITECTURE.md** - Deep dive into multi-branch design and rationale
- **USER_CONFIGURATION.md** - Detailed user configuration documentation
- **VERIFICATION.md** - Complete verification checklist

### Useful Commands for Debugging

```bash
# Docker logs
docker logs dartwing-frappe-dev
docker logs frappe-mariadb
docker logs frappe-redis-cache

# Container inspection
docker inspect dartwing-frappe-dev
docker exec dartwing-frappe-dev env  # Check environment variables
docker exec dartwing-frappe-dev ps aux  # Check running processes

# Network debugging
docker network inspect frappe-network
docker exec dartwing-frappe-dev ping frappe-mariadb
docker exec dartwing-frappe-dev nc -zv frappe-mariadb 3306

# File system debugging
docker exec dartwing-frappe-dev ls -la /workspace
docker exec dartwing-frappe-dev df -h
docker exec dartwing-frappe-dev du -sh /workspace/development/frappe-bench

# Bench debugging
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench version"
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench doctor"
```

---

**Last Updated:** December 2025  
**Version:** 2.0 - Isolated Bench Architecture
