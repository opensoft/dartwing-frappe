# Dynamic User Configuration

## Overview

This devcontainer is configured to **automatically match your host user**, making it work for any engineer on the team without manual configuration.

## How It Works

### 1. Environment Variables

The container reads these values from your shell environment:
- `$USER` - Your username
- `$UID` - Your user ID (typically `id -u`)
- `$GID` - Your group ID (typically `id -g`)

### 2. Build Arguments

In `docker-compose.yml`:
```yaml
args:
  USERNAME: ${USER:-frappe}
  USER_UID: ${UID:-1000}
  USER_GID: ${GID:-1000}
```

These get passed to the Dockerfile which uses them to create your user.

### 3. Dockerfile Processing

The Dockerfile:
1. Receives the build arguments
2. Deletes any existing user with that UID (e.g., default `frappe` user)
3. Creates a new user with YOUR username and UID/GID
4. Sets up proper permissions

### 4. VSCode Integration

In `devcontainer.json`:
```json
"remoteUser": "${localEnv:USER}"
```

This tells VSCode to use your username as the remote user.

## Configuration Files

### `.env.example` (Template)
Contains service configuration but **not** user values:
```bash
# User values come from shell environment automatically
# No need to set USER, UID, GID here

# Database configuration
DB_HOST=frappe-mariadb
DB_PORT=3306
DB_PASSWORD=frappe

# Redis configuration
REDIS_CACHE=frappe-redis-cache:6379
# ... etc
```

### No `.env` File Needed
The `.env` file is **not committed** to git (it's in `.gitignore`). User values are automatically read from your shell environment when you build the container.

## For Team Members

### First Time Setup

When a new engineer clones this repo:

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd dartwing-frappe
   ```

2. **Open in VSCode**
   ```bash
   code .
   ```

3. **Reopen in Container**
   - VSCode will prompt: "Reopen in Container"
   - Click it!
   - The container will automatically build using YOUR username

4. **Verify**
   ```bash
   whoami
   # Should show YOUR username, not "frappe" or "brett"
   
   id
   # Should show YOUR UID and GID
   ```

That's it! No manual configuration needed.

## How This Differs from Traditional Setups

### ❌ Traditional Approach (Hardcoded)
```dockerfile
ARG USERNAME=brett
ARG USER_UID=1000
ARG USER_GID=1000
```
**Problem**: Only works for one engineer (Brett). Other engineers get permission issues.

### ✅ Our Approach (Dynamic)
```dockerfile
ARG USERNAME
ARG USER_UID
ARG USER_GID
```
**Benefit**: Automatically works for everyone on the team!

## Technical Details

### Fallback Values

The docker-compose.yml has fallback values:
```yaml
USERNAME: ${USER:-frappe}
USER_UID: ${UID:-1000}
USER_GID: ${GID:-1000}
```

These are used if:
- Environment variables are not set (rare)
- Building from a context without shell variables

### User ID Conflicts

The Dockerfile handles UID conflicts by:
1. Checking if UID exists
2. Removing the existing user at that UID
3. Creating your user with that UID

This ensures:
- Your user always gets the correct UID
- No conflicts with default users (like `frappe`)
- Permissions work correctly with host files

### Shared Volume Permissions

Since both containers use the same UID (yours), file permissions work seamlessly:
- `frappe-dev`: Uses your user
- `dartwing-frappe-dev`: Uses your user
- Shared volume: Files owned by your UID

No permission denied errors! 🎉

## Debugging

### Check What User Will Be Created

Before building:
```bash
echo "Username: $USER"
echo "UID: $(id -u)"
echo "GID: $(id -g)"
```

### Check Container User After Build

```bash
docker exec dartwing-frappe-dev whoami
docker exec dartwing-frappe-dev id
```

### Check File Ownership in Shared Volume

```bash
docker exec dartwing-frappe-dev ls -la /workspace/development/frappe-bench/
```

All files should show your username and UID.

## Common Issues

### Issue: Container user is "frappe" instead of my username

**Cause**: Built with old configuration or environment variables not passed

**Solution**: Rebuild the container
```bash
# In VSCode
Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### Issue: Permission denied in shared volume

**Cause**: Mismatched UIDs between containers or host

**Solution**: Check UIDs match
```bash
# On host
id -u

# In frappe-dev
docker exec frappe-dev id -u

# In dartwing-frappe-dev
docker exec dartwing-frappe-dev id -u

# All should be the same number (e.g., 1000)
```

### Issue: Shell is bash instead of zsh

**Cause**: Shell not set during build

**Solution**: Rebuild container or manually set shell
```bash
# Inside container
chsh -s /bin/zsh
```

## Best Practices

### 1. Never Commit `.env` Files
The `.env` file is in `.gitignore` for a reason! Each engineer's environment is different.

### 2. Keep `.env.example` Updated
If you add new configuration options, update `.env.example` with:
- Clear comments
- Sensible defaults
- No user-specific values

### 3. Document Special Requirements
If your setup requires specific UID/GID values, document them in the README.

### 4. Test with Different Users
Before pushing changes, test that the setup works for users other than yourself.

## Advantages for the Team

1. **Zero Configuration** - Works out of the box for everyone
2. **No Permission Issues** - Everyone's files have correct ownership
3. **Easy Onboarding** - New engineers just open in VSCode
4. **Consistent Experience** - Same setup across all machines
5. **Git Friendly** - No user-specific files to commit/ignore

## Related Files

- `Dockerfile` - User creation logic
- `docker-compose.yml` - Passes environment variables
- `devcontainer.json` - VSCode configuration
- `.env.example` - Configuration template
- `.gitignore` - Excludes `.env` from git

---

**Summary**: This setup automatically creates a container user matching YOUR host user, ensuring seamless permissions and a consistent experience for all team members.
