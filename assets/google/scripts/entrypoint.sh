#!/bin/bash

echo "Starting entrypoint.sh"

echo "Running /usr/bin/workstation-startup.sh"
/usr/bin/workstation-startup.sh

echo "Starting VS Code Server in background"
runuser user -c "code-server --auth=none --port=80 --host=0.0.0.0" &

echo "Blocking indefinitely"
runuser user -c "sleep infinity"

echo "Exiting entrypoint.sh"