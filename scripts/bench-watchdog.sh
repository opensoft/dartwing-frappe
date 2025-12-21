#!/bin/bash
# Bench Watchdog - Monitors bench and restarts it if it stops
# Runs as a daemon in the background

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BENCH_DIR="${FRAPPE_BENCH_PATH:-/workspace/bench}"
BENCH_LOG="/workspace/bench.log"
WATCHDOG_LOG="/workspace/bench-watchdog.log"
CHECK_INTERVAL=10  # Check every 10 seconds

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$WATCHDOG_LOG"
}

# Function to check if bench is running
is_bench_running() {
    # Check for any bench-related processes (web server, socketio, workers)
    pgrep -f "gunicorn.*frappe" > /dev/null 2>&1 || \
    pgrep -f "node.*frappe.*socketio" > /dev/null 2>&1 || \
    pgrep -f "bench start" > /dev/null 2>&1
}

# Function to start bench
start_bench() {
    cd "$BENCH_DIR" || return 1
    log "Starting bench..."
    nohup bench start >> "$BENCH_LOG" 2>&1 &
    sleep 5
    if is_bench_running; then
        log "✓ Bench started successfully"
        return 0
    else
        log "✗ Failed to start bench"
        return 1
    fi
}

# Main watchdog loop
log "=========================================="
log "Bench Watchdog Started"
log "=========================================="
log "Bench directory: $BENCH_DIR"
log "Check interval: ${CHECK_INTERVAL}s"
log "Bench log: $BENCH_LOG"
log ""

# Wait for bench directory to be ready
while [ ! -f "${BENCH_DIR}/.setup_complete" ]; do
    log "Waiting for bench setup to complete..."
    sleep 10
done

log "Bench setup complete. Starting monitoring..."

# Main monitoring loop
while true; do
    if ! is_bench_running; then
        log "⚠ Bench is not running. Attempting to start..."
        if start_bench; then
            log "✓ Bench restarted successfully"
        else
            log "✗ Failed to restart bench. Will retry in ${CHECK_INTERVAL}s"
        fi
    fi
    
    sleep "$CHECK_INTERVAL"
done
