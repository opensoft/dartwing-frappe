# Dartwing Multi-Branch Container Scripts

## Overview

This directory contains automation scripts for managing multiple parallel Frappe development instances.

## new-dartwing-container.sh

Creates a new isolated Frappe development instance with its own:
- Bench installation
- Database
- Site
- Port
- Git clone of frappe-app-dartwing (on any branch)

### Usage

```bash
# Create instance with default branch (main)
./scripts/new-dartwing-container.sh

# Create instance with specific branch
./scripts/new-dartwing-container.sh feature/new-api

# Create instance with custom codename and branch
./scripts/new-dartwing-container.sh feature/auth-refactor delta
```

### Arguments

1. **Branch name** (optional, default: `main`)
   - The git branch to checkout in frappe-app-dartwing
   - Example: `feature/new-api`, `bugfix/login-issue`, `main`

2. **Codename** (optional, auto-generated)
   - Custom codename for the instance
   - If not provided, uses next available NATO phonetic alphabet name
   - Example: `alpha`, `bravo`, `charlie`

### What It Does

1. **Verifies Infrastructure** - Ensures frappe-network, MariaDB, and Redis are running
2. **Determines Codename** - Auto-generates next available codename (alpha, bravo, charlie...)
3. **Clones dartwing-frappe** - Creates independent clone in `frappe-<codename>` directory
4. **Configures Environment** - Updates .env file with unique settings
5. **Updates Devcontainer** - Modifies devcontainer.json for the instance
6. **Creates Bench Directory** - Prepares frappe-bench structure
7. **Initializes Bench** - Runs `bench init` with shared infrastructure
8. **Clones App** - Clones frappe-app-dartwing and checks out specified branch
9. **Installs App** - Registers app with bench
10. **Creates Site** - Creates new site with unique database
11. **Generates Docs** - Creates INSTANCE_INFO.md with all details

### Output

Creates a new directory structure:
```
/home/brett/projects/dartwingers/dartwing/frappe-<codename>/
├── .devcontainer/
│   ├── .env                    # Configured for this instance
│   ├── devcontainer.json       # Points to correct service
│   └── ...
├── frappe-bench/
│   └── apps/
│       └── frappe-app-dartwing/  # On specified branch
└── INSTANCE_INFO.md            # Instance documentation
```

### Instance Details

Each instance gets:
- **Port**: 8001, 8002, 8003... (auto-incremented)
- **Container**: frappe-alpha, frappe-bravo, frappe-charlie...
- **Database**: dartwing_alpha, dartwing_bravo, dartwing_charlie...
- **Site**: site-alpha.local, site-bravo.local, site-charlie.local...

### Next Steps

After running the script:

```bash
# Navigate to instance
cd frappe-alpha

# Open in VS Code
code .

# Reopen in Container (VS Code will prompt)
# Inside container, start development server:
cd /workspace/frappe-bench
bench start

# Visit http://localhost:8001
```

### Cleanup

To remove an instance:

```bash
# Remove directory
cd /home/brett/projects/dartwingers/dartwing
rm -rf frappe-alpha

# Optionally drop database
docker exec frappe-mariadb mysql -uroot -pfrappe -e "DROP DATABASE dartwing_alpha;"
```

## Examples

### Working on Multiple Features Simultaneously

```bash
# Terminal 1: Create alpha instance for feature A
./scripts/new-dartwing-container.sh feature/user-authentication
cd frappe-alpha
code .
# Inside container: bench start (runs on port 8001)

# Terminal 2: Create bravo instance for feature B  
./scripts/new-dartwing-container.sh feature/payment-gateway
cd frappe-bravo
code .
# Inside container: bench start (runs on port 8002)

# Now you can work on both features in parallel!
```

### Testing Different Branches

```bash
# Test main branch
./scripts/new-dartwing-container.sh main alpha

# Test development branch
./scripts/new-dartwing-container.sh develop bravo

# Test your feature branch
./scripts/new-dartwing-container.sh feature/my-changes charlie
```

## Troubleshooting

### Infrastructure Not Running

If you see "frappe-network not found", the script will automatically start the infrastructure. If it fails, manually start it:

```bash
cd /home/brett/projects/workBenches/devBenches/frappeBench
docker compose up -d mariadb redis-cache redis-queue redis-socketio
```

### Port Already in Use

The script automatically assigns ports sequentially. If you delete an instance and recreate it, it will get a new port number.

### Bench Init Takes Too Long

Bench initialization can take 5-10 minutes as it installs Frappe and all dependencies. This is normal.

### Can't Clone Repository

Ensure you have SSH keys configured for GitHub:
```bash
ssh -T git@github.com
```

## Architecture

See [MULTI_BRANCH_ARCHITECTURE.md](../MULTI_BRANCH_ARCHITECTURE.md) for full architecture details.
