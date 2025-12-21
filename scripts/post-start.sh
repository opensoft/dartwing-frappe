#!/bin/bash
# Post-start wrapper for devcontainer
# Runs setup and daemonizes the bench watchdog

set -o pipefail

echo 'Starting Dartwing setup...'

# Run setup and log output
bash /workspace/scripts/setup-workspace.sh 2>&1 | tee /workspace/setup.log
rc=$?

if [ $rc -eq 0 ]; then
    echo 'Setup completed successfully'
    # Daemonize the bench watchdog
    bash /workspace/scripts/daemonize.sh bash /workspace/scripts/bench-watchdog.sh
    echo 'Bench watchdog daemonized'
fi

exit $rc
