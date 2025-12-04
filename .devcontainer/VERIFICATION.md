# Dartwing Frappe Devcontainer Verification

This document provides step-by-step verification that the devcontainer is properly configured to attach to the existing Frappe infrastructure.

## Pre-flight Checks (Before Opening in VSCode)

### 1. Verify Main Frappe Infrastructure is Running

```bash
# Check all required containers are running
docker ps --filter "name=frappe" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Expected Output:**
- `frappe-dev` - Up
- `frappe-mariadb` - Up (healthy)
- `frappe-redis-cache` - Up (healthy)
- `frappe-redis-queue` - Up (healthy)
- `frappe-redis-socketio` - Up (healthy)
- `frappe-nginx` - Up, with port 8081 mapped

### 2. Verify Network Exists

```bash
docker network inspect frappe_frappe-network --format '{{.Name}}: {{len .Containers}} containers'
```

**Expected Output:** Should show 5 containers (frappe-dev + 4 services)

### 3. Verify Volume Exists

```bash
docker volume inspect frappe-bench-data-frappe --format '{{.Name}}'
```

**Expected Output:** `frappe-bench-data-frappe`

### 4. Verify Frappe Bench is Initialized

```bash
docker exec frappe-dev ls -la /workspace/development/frappe-bench/apps/
```

**Expected Output:** Should show at least `frappe` and `erpnext` apps

## Configuration Validation

### 5. Validate Docker Compose Configuration

```bash
cd /home/brett/projects/dartwingers/dartwing/dartwing-frappe/.devcontainer
docker-compose config --quiet
```

**Expected Output:** No errors (exit code 0)

### 6. Check External Resource References

```bash
# Check network reference
docker-compose config | grep -A 1 "frappe_frappe-network"

# Check volume reference
docker-compose config | grep -A 1 "frappe-bench-data-frappe"
```

**Expected Output:** Both should show `external: true`

### 7. Verify Environment File

```bash
cat .devcontainer/.env | grep -E "USER|DB_HOST|REDIS"
```

**Expected Output:**
- `USER=brett`
- `DB_HOST=frappe-mariadb`
- `REDIS_CACHE=frappe-redis-cache:6379`
- `REDIS_QUEUE=frappe-redis-queue:6379`
- `REDIS_SOCKETIO=frappe-redis-socketio:6379`

## Post-Container-Start Checks

After opening the workspace in VSCode and the container starts:

### 8. Verify Container is Running

```bash
docker ps --filter "name=dartwing-frappe-dev"
```

**Expected Output:** Container `dartwing-frappe-dev` should be Up

### 9. Verify Network Connectivity

```bash
# From inside the dartwing-frappe-dev container
docker exec dartwing-frappe-dev ping -c 1 frappe-mariadb
docker exec dartwing-frappe-dev ping -c 1 frappe-redis-cache
```

**Expected Output:** Successful ping responses

### 10. Verify Volume Mount

```bash
# Check that frappe bench is accessible
docker exec dartwing-frappe-dev ls /workspace/development/frappe-bench/
```

**Expected Output:** Should show `apps/`, `sites/`, `config/`, etc.

### 11. Verify Database Connectivity

```bash
# Test database connection
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench --site site1.localhost mariadb --execute 'SELECT 1;'"
```

**Expected Output:** Should connect successfully and return `1`

### 12. Verify User Permissions

```bash
# Check user inside container
docker exec dartwing-frappe-dev whoami
docker exec dartwing-frappe-dev id
```

**Expected Output:**
- Username: `brett`
- UID: `1000`
- GID: `1000`

### 13. Verify Workspace Mount

```bash
# Check this project is mounted
docker exec dartwing-frappe-dev ls /workspace/
```

**Expected Output:** Should show files from this project (`.devcontainer/`, `README.md`, etc.)

## Functional Tests

### 14. Test Bench Commands

```bash
# From inside container
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench version"
```

**Expected Output:** Frappe version information

### 15. Test Site Access

```bash
# From inside container
docker exec dartwing-frappe-dev bash -c "cd /workspace/development/frappe-bench && bench --site site1.localhost list-apps"
```

**Expected Output:** List of installed apps

### 16. Test Web Access

```bash
# From host
curl -s -o /dev/null -w "%{http_code}" http://localhost:8081
```

**Expected Output:** `200` or `302` (OK or redirect to login)

## Troubleshooting Common Issues

### Issue: External network not found

**Solution:**
```bash
cd /home/brett/projects/frappe
# Start the main Frappe devcontainer in VSCode
```

### Issue: External volume not found

**Solution:**
```bash
# Check if volume was created with different name
docker volume ls | grep frappe
# Update docker-compose.yml if necessary
```

### Issue: Permission denied in shared volume

**Solution:**
```bash
# Check user IDs match
docker exec frappe-dev id
docker exec dartwing-frappe-dev id
# Both should be brett/1000/1000
```

### Issue: Cannot connect to database

**Solution:**
```bash
# Verify database container is healthy
docker inspect frappe-mariadb --format '{{.State.Health.Status}}'
# Should be "healthy"

# Test from dartwing container
docker exec dartwing-frappe-dev nc -zv frappe-mariadb 3306
```

## Success Criteria

✓ All pre-flight checks pass  
✓ Docker Compose configuration is valid  
✓ Container starts without errors  
✓ Network connectivity confirmed  
✓ Volume mount accessible  
✓ Database connection works  
✓ Bench commands execute  
✓ Web interface accessible at http://localhost:8081  

## Next Steps

Once all checks pass, you can:

1. Create a new Frappe app for Dartwing
2. Install the app to the site
3. Begin development in `/workspace/development/frappe-bench/apps/dartwing`

See README.md for detailed development workflow.
