#!/bin/bash

echo "CWD: Starting entrypoint.sh"

echo "CWD: Running /usr/bin/workstation-startup.sh"
/usr/bin/workstation-startup.sh

echo "CWD: Starting VS Code Server in background"
runuser user -c "code-server --auth=none --port=80 --host=0.0.0.0" &

echo "CWD: Blocking indefinitely"
runuser user -c "sleep infinity"

echo "CWD: Exiting entrypoint.sh"