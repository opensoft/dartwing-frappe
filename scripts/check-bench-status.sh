#!/bin/bash
# Check if bench is running in the workspace

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "Bench Status Check"
echo -e "==========================================${NC}"
echo ""

# Check if bench process is running
if pgrep -f "bench start" > /dev/null; then
    echo -e "${GREEN}✓ Bench is RUNNING${NC}"
    echo ""
    echo -e "${BLUE}Process details:${NC}"
    ps aux | grep "[b]ench start"
    echo ""
    
    # Check if the web server is responding
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Web server is responding on port 8000${NC}"
    else
        echo -e "${YELLOW}⚠ Bench process found but web server not responding yet${NC}"
        echo -e "${YELLOW}  (It may still be starting up)${NC}"
    fi
    
    # Show recent log entries
    if [ -f "/workspace/bench.log" ]; then
        echo ""
        echo -e "${BLUE}Recent log entries:${NC}"
        tail -n 10 /workspace/bench.log
    fi
else
    echo -e "${RED}✗ Bench is NOT running${NC}"
    echo ""
    
    # Check if setup completed
    if [ -f "/workspace/bench/.setup_complete" ]; then
        echo -e "${YELLOW}⚠ Setup completed but bench not started${NC}"
        echo -e "${YELLOW}  You can manually start it with: bench start${NC}"
    else
        echo -e "${YELLOW}⚠ Setup has not completed yet${NC}"
        echo -e "${YELLOW}  Check /workspace/setup.log for progress${NC}"
    fi
fi

echo ""
echo -e "${BLUE}==========================================${NC}"
