# GitHub Authentication Setup for Devcontainers

This document explains how GitHub authentication is configured in the Dartwing Frappe devcontainer environment.

## Authentication Methods

We use **both** SSH and PAT (Personal Access Token) authentication:

### SSH Authentication (for Git operations)
- **Purpose**: Used for git clone, push, pull operations
- **Setup**: SSH keys are mounted from host to container (read-only)
- **Location**: `~/.ssh/` directory
- **Keys mounted**:
  - `id_ed25519` (GitHub)
  - `id_rsa_ado` (Azure DevOps)
  - SSH config and known_hosts

### PAT Authentication (for gh CLI)
- **Purpose**: Used for GitHub CLI operations (issues, PRs, etc.)
- **Setup**: Two-tier approach for flexibility
  1. **Primary**: Mount `~/.config/gh/` directory (contains PAT)
  2. **Fallback**: `GH_TOKEN` environment variable

## How It Works

### Mounted Configuration (Recommended)
The devcontainer mounts your host's `~/.config/gh/` directory:
```yaml
- ~/.config/gh:/home/${USER}/.config/gh:ro
```

This gives the container access to your authenticated gh CLI configuration, including your PAT stored in `hosts.yml`.

### Environment Variable Fallback
If you need to override or set a specific token:
```bash
# On host, before starting container
export GH_TOKEN="your_pat_here"
```

The docker-compose configuration forwards this:
```yaml
- GH_TOKEN=${GH_TOKEN:-}
```

## Security Notes

1. **Read-only mounts**: All sensitive files (SSH keys, gh config) are mounted as read-only (`:ro`)
2. **No PAT in code**: Never hardcode PAT tokens in files
3. **Host isolation**: PAT stays on host filesystem, accessed via secure mount
4. **WSL-safe**: Works properly in WSL environment with sync daemon

## Troubleshooting

### gh CLI asking for authentication
If `gh` commands fail with authentication errors:

1. **Check mount exists in container**:
   ```bash
   ls -la ~/.config/gh/
   ```

2. **Verify gh auth status**:
   ```bash
   gh auth status
   ```

3. **If mount is missing**, rebuild container:
   ```bash
   # Ctrl+Shift+P -> Dev Containers: Rebuild Container
   ```

4. **If still failing**, set GH_TOKEN manually:
   ```bash
   export GH_TOKEN=$(cat ~/.config/gh/hosts.yml | grep oauth_token | awk '{print $2}')
   ```

### SSH still working but gh CLI not
This is expected if only the gh config mount is missing. The two authentication methods are independent:
- SSH: for git operations (mounted separately)
- PAT: for gh CLI operations (via config mount or env var)

## Files Modified
- `devcontainer.example/docker-compose.yml` (template)
- `workspaces/hotel/.devcontainer/docker-compose.yml` (current workspace)
- Additional workspaces will need this update applied

## Future Workspace Setup
When creating new workspaces from the template, the gh config mount will automatically be included.
