#!/bin/bash

#
# Entrypoint for Cloud Workstations custom image.
# Executes all startup scripts and then blocks indefinitely.
#

echo "Starting entrypoint.sh"

# Run all workstation startup scripts
echo "Running /usr/bin/workstation-startup.sh"
/usr/bin/workstation-startup.sh

echo "All startup scripts completed"

# Block indefinitely to keep container running
echo "Blocking indefinitely to keep container alive"
sleep infinity

echo "Exiting entrypoint.sh"
