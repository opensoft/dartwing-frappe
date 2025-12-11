#!/bin/bash
set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Workspace Setup Wrapper"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}This script is a wrapper that calls init-bench.sh${NC}"
echo ""

# Determine the location of init-bench.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_BENCH_SCRIPT="${SCRIPT_DIR}/init-bench.sh"

# Check if init-bench.sh exists
if [ ! -f "$INIT_BENCH_SCRIPT" ]; then
    echo -e "${RED}Error: init-bench.sh not found at ${INIT_BENCH_SCRIPT}${NC}"
    exit 1
fi

echo -e "${BLUE}Calling init-bench.sh...${NC}"
echo ""

# Execute init-bench.sh
"$INIT_BENCH_SCRIPT"

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Workspace Setup Complete!"
    echo -e "==========================================${NC}"
else
    echo ""
    echo -e "${RED}=========================================="
    echo "Workspace Setup Failed!"
    echo -e "==========================================${NC}"
    exit 1
fi
