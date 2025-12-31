# Claude JSON Mount Requirement

## Overview
The `~/.claude.json` file contains Claude Code IDE configuration and must be mounted in every devcontainer's `docker-compose.override.yml` file to enable Claude CLI authentication and IDE settings synchronization.

## Requirement
Every devcontainer must include the following mount in its `docker-compose.override.yml`:

```yaml
- ~/.claude.json:/home/${USER:-vscode}/.claude.json:cached
```

## Location
This mount must be added to the `docker-compose.override.yml` file in the `volumes` section under the `dartwing-dev` service, immediately after the `~/.claude` directory mount:

```yaml
volumes:
  # Anthropic Claude Code CLI Authentication
  # Required for: VS Code Claude Code extension, Claude CLI tools
  # Location: ~/.claude/ contains API keys and session data
  - ~/.claude:/home/${USER:-vscode}/.claude:cached
  # Claude Code IDE configuration file
  - ~/.claude.json:/home/${USER:-vscode}/.claude.json:cached
```

## Why This Is Required
1. **Claude CLI Authentication**: The `claude` command-line tool needs access to `~/.claude.json` to authenticate and use cached credentials from `~/.claude`
2. **IDE Configuration Sync**: Claude Code IDE settings stored in `~/.claude.json` need to be available inside the container
3. **Consistent Behavior**: Without this mount, Claude CLI will attempt to re-authenticate via OAuth, which fails in WSL environments

## Template Updates
- `devcontainer.example/docker-compose.override.yml` - Updated ✅
- `devcontainer.example/docker-compose.override.example.yml` - Updated ✅

## Verification
After updating any workspace's `docker-compose.override.yml` with this mount, restart the container:

```bash
docker compose down
docker compose up -d
```

Verify the mount is active:
```bash
docker inspect <container-name> --format '{{json .Mounts}}' | jq '.[] | select(.Destination | contains(".claude.json"))'
```

## Related Files
- See: `.warp/claude-credentials-mount.md` for the `~/.claude` directory mount requirement
