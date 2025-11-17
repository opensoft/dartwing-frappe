# Dartwing Frappe Devcontainer Changelog

## Version 1.0.0 - 2025-01-16

### Ubuntu 22.04 Rebuild Complete ✅

Successfully rebuilt the Dockerfile from Ubuntu 22.04 base instead of `frappe/bench:latest` (Debian-based).

#### Key Changes

1. **Base Image**: Changed from `frappe/bench:latest` → `ubuntu:22.04`
2. **Full Stack Installation**: Manually installed complete Frappe development stack
   - Python 3.10.12
   - Node.js 20.19.5
   - MariaDB client libraries
   - frappe-bench 5.27.0
   - Build tools and dependencies
3. **Docker CLI Support**: Successfully integrated Docker CLI with socket access
   - Added docker group (GID 1001) matching host
   - User added to docker group for socket permissions
   - Verified `docker exec` commands work from inside container
4. **Dynamic User Configuration**: Maintained host UID/GID matching
   - User: brett (1000:1000)
   - Groups: brett(1000), docker(1001)
   - Full sudo access

#### Technical Details

**System Dependencies Installed**:
- Build essentials (gcc, g++, make, pkg-config)
- Python development (python3-dev, python3-pip, python3.10-venv, libffi-dev, libssl-dev)
- Image processing (libjpeg-dev, zlib1g-dev)
- Database client (libmariadb-dev, mariadb-client)
- PDF generation (wkhtmltopdf, xvfb, libfontconfig1)
- Version control (git)
- Development tools (vim, nano, less, tree, curl, wget, jq)
- Shells (zsh with Oh My Zsh, bash)
- Locales (en_US.UTF-8)

**Python Packages**:
- frappe-bench, redis, mysqlclient, requests, click, aiohttp, gevent, eventlet, PyJWT
- Development tools: black, flake8, isort, pylint, pytest, ipython

**Node.js**:
- Node.js 20.x via NodeSource
- Yarn package manager (global)

**Docker CLI**:
- Installed from Docker's official Ubuntu repository
- User added to docker group for socket access
- Verified working with `docker ps` and `docker exec` commands

#### Verification Results

✅ Container builds successfully from Ubuntu 22.04  
✅ All dependencies installed (Python 3.10, Node 20.x, bench, docker)  
✅ User configuration matches host (UID 1000, GID 1000)  
✅ Docker socket access works (user in docker group GID 1001)  
✅ Docker-in-Docker commands execute successfully  
✅ Setup script runs without errors  
✅ Site and app creation works  
✅ Oh My Zsh installed and configured  

#### Benefits

- **Consistent Base**: Now matches main Frappe project (Ubuntu 22.04)
- **No Docker Socket Issues**: Ubuntu-based Docker CLI works perfectly
- **Full Control**: Complete visibility into all installed components
- **Team Friendly**: Dynamic user configuration works for all engineers
- **Maintainable**: Clear dependency list and installation steps

#### Next Steps

- Test full VSCode devcontainer integration
- Verify postStartCommand runs automatically
- Confirm site and app creation on fresh start
- Document any edge cases or gotchas
