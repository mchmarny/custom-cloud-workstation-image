#!/bin/bash

#
# Single entrypoint to execute all "startup" scripts.
#
# Startup scripts are located under /etc/workstation-startup.d/ and are
# executed in lexographical order. This enables trivially adding / removing /
# modifying startup tasks when extending an image.
#

echo "Starting workstation-startup"

set -e

for task in /etc/workstation-startup.d/*; do
  # If this is an executable shell script, execute it.
  if [[ "${task##*.}" -eq "sh" ]] && [[ -x "${task}" ]]; then
    echo "Running ${task}..."
    "${task}"
  fi
done

echo "Exiting workstation-startup"