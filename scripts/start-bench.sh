#!/bin/bash
# Start bench in the background after setup is complete
# This script is called by postStartCommand in devcontainer.json

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BENCH_DIR="${FRAPPE_BENCH_PATH:-/workspace/bench}"
SETUP_MARKER="${BENCH_DIR}/.setup_complete"
BENCH_LOG="/workspace/bench.log"

echo -e "${BLUE}=========================================="
echo "Bench Auto-Start"
echo -e "==========================================${NC}"
echo ""

# Wait for setup to complete (with timeout)
echo -e "${YELLOW}Waiting for bench setup to complete...${NC}"
MAX_WAIT=600  # 10 minutes
ELAPSED=0
while [ ! -f "$SETUP_MARKER" ] && [ $ELAPSED -lt $MAX_WAIT ]; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $((ELAPSED % 30)) -eq 0 ]; then
        echo -e "${YELLOW}  → Still waiting... (${ELAPSED}s elapsed)${NC}"
    fi
done

if [ ! -f "$SETUP_MARKER" ]; then
    echo -e "${RED}✗ Setup did not complete within ${MAX_WAIT}s${NC}"
    echo -e "${YELLOW}  You can manually run 'bench start' after setup completes${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Setup complete${NC}"
echo ""

# Check if bench is already running
if pgrep -f "bench start" > /dev/null; then
    echo -e "${YELLOW}Bench is already running${NC}"
    exit 0
fi

# Start bench in the background
echo -e "${BLUE}Starting bench server...${NC}"
cd "$BENCH_DIR"

# Start bench with setsid to detach from terminal session and prevent termination
# This ensures the process persists even after the parent shell exits
setsid bash -c "bench start > \"$BENCH_LOG\" 2>&1" &
BENCH_PID=$!

# Disown the process to prevent it from being killed when shell exits
disown $BENCH_PID 2>/dev/null || true

# Wait a few seconds and check if it started successfully
sleep 5
if ps -p $BENCH_PID > /dev/null; then
    echo -e "${GREEN}✓ Bench started successfully (PID: ${BENCH_PID})${NC}"
    echo -e "${BLUE}  → Log file: ${BENCH_LOG}${NC}"
    echo -e "${BLUE}  → To view logs: tail -f ${BENCH_LOG}${NC}"
    echo -e "${BLUE}  → To stop: pkill -f 'bench start'${NC}"
else
    echo -e "${RED}✗ Bench failed to start${NC}"
    echo -e "${YELLOW}  Check ${BENCH_LOG} for errors${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}==========================================="
echo "Bench is running!"
echo -e "==========================================${NC}"
