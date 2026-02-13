# Dartwing Frappe Development Environment

Development workspace for the Dartwing Frappe application with isolated bench instances for parallel development.

## Architecture

This project leverages the **workBenches layered container architecture** from frappeBench:

- **Layer 0** (`workbench-base:$USER`) - Ubuntu 24.04, git, editors, CLI tools
- **Layer 1a** (`devbench-base:$USER`) - Python, Node.js, AI CLIs (Claude, Copilot, etc.)
- **Layer 2** (`frappe-bench:$USER`) - Frappe-specific tools (MariaDB client, Redis tools, Nginx, frappe-bench)

This means:
- ✅ Faster builds (uses cached layers)
- ✅ Consistent tooling across Frappe projects
- ✅ Automatic updates when frappeBench updates
- ✅ Shared infrastructure (MariaDB, Redis) across workspaces

## Quick Start

### Prerequisites
1. **Docker and Docker Compose**
2. **VSCode with Dev Containers extension**
3. **workBenches frappeBench** (required dependency)

   If not installed:
   ```bash
   cd ~/projects/workBenches
   ./setup.sh
   # Select 'frappeBench' from the devBenches list
   ```

   Or if already installed, ensure the image is built:
   ```bash
   cd ~/projects/workBenches/devBenches/frappeBench
   ./build-layer2.sh --user $USER
   ```

### Setup

1. **Verify frappeBench Image**
   ```bash
   docker image inspect frappe-bench:$USER
   # Should show the image details
   ```

2. **Clone and Setup**
   ```bash
   cd ~/projects/Dartwing
   git clone git@github.com:opensoft/dartwing-frappe.git frappe
   cd frappe
   ./setup.sh
   # The script will check for frappe-bench image and guide you if missing
   ```

3. **Open in VSCode**
   ```bash
   code .
   # Click "Reopen in Container"
   ```

4. **Start Development**
   ```bash
   # Inside container (after auto-setup completes)
   cd /workspace/workspaces/frappe-bench
   bench start
   ```

5. **Access**: http://localhost:8081 (Administrator / admin)

## Key Features

- ✅ **Isolated Benches** - Each workspace has its own Frappe bench
- ✅ **Shared Infrastructure** - All workspaces share MariaDB and Redis
- ✅ **Multi-Branch Support** - Create parallel workspaces for different features
- ✅ **Auto-Setup** - `init-bench.sh` runs automatically in container
- ✅ **Dynamic User Config** - Matches your host user automatically

## Multi-Workspace Development

Create additional workspaces for parallel development:

```bash
./scripts/new-workspace.sh alpha
./scripts/new-workspace.sh bravo
```

Workspaces are created under `workspaces/` directory:
```
workspaces/
├── frappe-bench/           # Default workspace
├── alpha/
│   ├── .env               # Workspace config
│   └── frappe-bench/      # Independent bench
└── bravo/
    ├── .env
    └── frappe-bench/
```

Each workspace gets:
- Independent Frappe bench under `workspaces/<name>/frappe-bench/`
- Own database (dartwing_alpha, dartwing_bravo, etc.)
- Own clone of frappe-app-dartwing
- Workspace-specific configuration in `.env` file

## Scripts

- **`setup.sh`** - Initial setup (creates .env, folders, clones app)
- **`init-bench.sh`** - Bench initialization (auto-runs in container)
- **`new-workspace.sh <name>`** - Create new workspace

## Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Complete guide with all sections:
  - Architecture details
  - Development workflow
  - AI Coding Assistant setup
  - User configuration
  - Verification checklist
  - Troubleshooting

- **[MULTI_BRANCH_ARCHITECTURE.md](docs/MULTI_BRANCH_ARCHITECTURE.md)** - Deep dive into multi-branch design, decisions, and rationale

- **[USER_CONFIGURATION.md](.devcontainer/USER_CONFIGURATION.md)** - Detailed user configuration documentation

- **[VERIFICATION.md](.devcontainer/VERIFICATION.md)** - Complete verification checklist

## Common Commands

```bash
# Inside container
cd /workspace/workspaces/frappe-bench

bench start                              # Start development server
bench --site dartwing.localhost migrate  # Run migrations
bench clear-cache                        # Clear cache
bench --site dartwing.localhost mariadb  # Access database
```

## Troubleshooting

**Missing frappe-bench image?**
```bash
# Install frappeBench from workBenches
cd ~/projects/workBenches
./setup.sh
# Select 'frappeBench' from the devBenches list
```

**Container won't start?**
```bash
# Verify frappe-bench image exists
docker image inspect frappe-bench:$USER

# Verify infrastructure is running
docker ps | grep frappe
docker network ls | grep frappe-network
```

**Setup issues?**
```bash
# Re-run setup
./setup.sh

# Or rebuild container
# VSCode: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

See [ARCHITECTURE.md](docs/ARCHITECTURE.md#troubleshooting) for detailed troubleshooting.

## Support

1. Check [ARCHITECTURE.md](docs/ARCHITECTURE.md) for comprehensive documentation
2. Review [Verification checklist](.devcontainer/VERIFICATION.md)
3. See [Troubleshooting section](docs/ARCHITECTURE.md#troubleshooting)
