#!/bin/bash

#
# Startup script to start VS Code Server on port 80.
#

echo "Starting 110_start-code-server.sh"

set -e

echo "Starting code-server on port 80"
# Enable GitHub authentication and profile sync
runuser user -c "code-server \
    --auth=none \
    --port=80 \
    --host=0.0.0.0 \
    --disable-telemetry \
    --disable-update-check \
    --extensions-dir=/home/user/.local/share/code-server/extensions \
    --user-data-dir=/home/user/.local/share/code-server" &

echo "Waiting for code-server to be ready"
timeout=60
elapsed=0
while ! curl -s http://localhost:80 > /dev/null 2>&1; do
    if [ $elapsed -ge $timeout ]; then
        echo "ERROR: code-server failed to start within ${timeout} seconds"
        exit 1
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "code-server is ready on port 80"
echo "Exiting 110_start-code-server.sh"
