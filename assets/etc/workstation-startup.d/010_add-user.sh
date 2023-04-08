#!/bin/bash

#
# Startup script to add default user to workstation container.
#

echo "Starting 010_add-user.sh"

set -e

groups=sudo
useradd -m user -G $groups --shell /bin/bash > /dev/null
passwd -d user >/dev/null
echo "%sudo ALL=NOPASSWD: ALL" >> /etc/sudoers

echo "Exiting 010_add-user.sh"