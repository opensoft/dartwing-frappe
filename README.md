# Dartwing Frappe Development Environment

Development workspace for the Dartwing Frappe application with isolated bench instances for parallel development.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- VSCode with Dev Containers extension
- Frappe infrastructure (MariaDB, Redis)

### Setup

1. **Start Infrastructure**
   ```bash
   cd /home/brett/projects/workBenches/devBenches/frappeBench
   docker compose up -d mariadb redis-cache redis-queue redis-socketio
   ```

2. **Clone and Setup**
   ```bash
   cd /home/brett/projects/dartwing
   git clone git@github.com:opensoft/dartwing-frappe.git
   cd dartwing-frappe
   ./setup.sh
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

**Container won't start?**
```bash
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
