#!/bin/bash
# Double-fork daemonization wrapper
# This ensures the process is fully detached and adopted by init (PID 1)
# Usage: daemonize.sh <command> [args...]

if [ $# -eq 0 ]; then
    echo "Usage: daemonize.sh <command> [args...]"
    exit 1
fi

# Double fork to ensure complete detachment from parent process
(
    # First fork - creates new process group
    # Redirect stdin from /dev/null and stdout/stderr to prevent blocking
    setsid bash -c "
        # Second fork - ensures process is adopted by init
        (
            exec \"$@\" < /dev/null > /dev/null 2>&1
        ) &
    " &
) &

# Parent exits immediately, leaving the double-forked child to be adopted by PID 1
exit 0
