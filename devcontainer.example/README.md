# DevContainer Template

This directory contains the template configuration for workspace devcontainers.

## Template Version

**Current Version: 1.0.0**

## Usage

When creating a new workspace, copy the contents of this directory to your workspace's `.devcontainer/` folder:

```bash
cp -r devcontainer.example/ workspaces/<workspace-name>/.devcontainer/
```

## Version Tracking

Each workspace should track which template version it was created from or last updated to. To check if your workspace is using the latest template version, compare the version number in your workspace's `.devcontainer/` directory with the version listed above.

## Files Included

- `Dockerfile` - Container image definition
- `devcontainer.json` - VS Code devcontainer configuration
- `docker-compose.yml` - Main docker compose configuration
- `docker-compose.override.example.yml` - Example override configuration
- `docker-compose.override.yml` - Active override configuration
- `.env.example` - Environment variable template
- `nginx.conf` - Nginx web server configuration

## Updating Workspaces

When the template is updated:

1. Increment the version number in this README
2. Update existing workspaces by copying updated files from this template
3. Review and merge any custom workspace-specific configurations
