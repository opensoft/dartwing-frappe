# Container Rebuild Required

## What Changed

The Dockerfile has been updated to properly match the host user setup, just like the main `frappe-dev` container.

### Previous Issue
The original Dockerfile used `frappe/bench:latest` which has a default `frappe` user (UID 1000). The old script only created a user "if it doesn't exist", so it kept using `frappe` instead of your host user `brett`.

### What Was Fixed

1. **User Replacement Logic** - Now properly deletes the existing `frappe` user and replaces it with `brett`
2. **Oh My Zsh** - Added for better terminal experience (matching main container)
3. **Zsh as Default Shell** - Set zsh as the default shell
4. **PATH Configuration** - Added bench to PATH in both bash and zsh
5. **Version Labels** - Added container metadata labels
6. **Workspace Permissions** - Ensures proper ownership of /workspace directory

### Updated Dockerfile Features

```dockerfile
# Removes existing frappe user
# Creates user matching YOUR host user (dynamic)
# Installs Oh My Zsh
# Sets zsh as default shell
# Configures sudo access
# Sets up proper workspace ownership
```

**Important**: The container now automatically uses YOUR username and UID/GID from your shell environment. No hardcoded values!

## Why This Matters

**User Consistency**: Both `frappe-dev` and `dartwing-frappe-dev` now use YOUR host user (automatically detected), which ensures:
- No permission issues when accessing the shared Frappe bench volume
- Consistent file ownership between both containers
- Your git configuration and SSH keys work correctly in both containers

## How to Apply Changes

### Option 1: Rebuild via VSCode (Recommended)

1. Open the dartwing-frappe folder in VSCode
2. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Select: **"Dev Containers: Rebuild Container"**
4. Wait for the rebuild to complete

### Option 2: Rebuild via Command Line

```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe

# Stop and remove the old container
docker stop dartwing-frappe-dev 2>/dev/null || true
docker rm dartwing-frappe-dev 2>/dev/null || true

# Rebuild the image
cd .devcontainer
docker-compose build --no-cache dartwing-dev

# Start the new container
docker-compose up -d dartwing-dev
```

### Option 3: Clean Rebuild (If Issues Persist)

```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe/.devcontainer

# Remove old container and image
docker stop dartwing-frappe-dev 2>/dev/null || true
docker rm dartwing-frappe-dev 2>/dev/null || true
docker rmi devcontainer-dartwing-dev 2>/dev/null || true

# Rebuild from scratch
docker-compose build --no-cache --pull dartwing-dev
```

## Verification After Rebuild

Once the container is rebuilt and running, verify the user is correct:

```bash
# Check user inside new container
docker exec dartwing-frappe-dev id

# Expected output:
# uid=1000(brett) gid=1000(brett) groups=1000(brett)

# Check shell
docker exec dartwing-frappe-dev bash -c 'echo $SHELL'

# Expected output:
# /bin/zsh

# Check workspace ownership
docker exec dartwing-frappe-dev ls -la /workspace/

# Expected: Files owned by brett:brett
```

## Before and After Comparison

### Before (Old Container)
```bash
$ docker exec dartwing-frappe-dev id
uid=1000(frappe) gid=1000(frappe) groups=1000(frappe)
```

### After (New Container)
```bash
$ docker exec dartwing-frappe-dev id
uid=1000(your_username) gid=1000(your_username) groups=1000(your_username)
# Where your_username is YOUR actual host username
```

## Impact on Existing Work

**Good News**: Since the UID remains 1000 in both cases, file permissions in the shared volume should not change. However, file ownership will now correctly show as `brett` instead of `frappe`.

## Next Steps

After rebuilding:

1. **Verify User** - Check that `whoami` returns YOUR username
2. **Test Shared Volume** - Confirm you can access `/workspace/development/frappe-bench`
3. **Check Permissions** - Ensure you can edit files without permission errors
4. **Test Bench Commands** - Run `bench version` to verify Frappe access
5. **Continue Development** - Proceed with creating the Dartwing app

## Notes

- The rebuild will take a few minutes as it downloads Oh My Zsh and sets up the user
- Your workspace files are mounted, not part of the image, so they won't be affected
- The shared Frappe bench volume (`frappe-bench-data-frappe`) is not affected
- Both containers will now have identical user configurations

## Troubleshooting

### "Permission denied" errors after rebuild
```bash
# Reset ownership in shared volume (if needed)
# Replace YOUR_USER with your actual username
docker exec frappe-dev sudo chown -R $USER:$USER /workspace/development/frappe-bench
```

### Old container still showing
```bash
# Force remove old container
docker rm -f dartwing-frappe-dev
```

### Build cache issues
```bash
# Clear Docker build cache
docker builder prune
```

---

**Ready to rebuild?** Use Option 1 (VSCode rebuild) for the easiest experience!
