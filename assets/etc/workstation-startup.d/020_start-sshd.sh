#!/bin/bash

#
# Startup script to start OpenSSH Daemon.
#

echo "CWD: Starting 020_start-sshd.sh"

set -e

echo "CWD: Generating host SSH keys"
yes | ssh-keygen -q -f /etc/ssh/ssh_host_rsa_key -t rsa -C 'host' -N '' > /dev/null
yes | ssh-keygen -q -f /etc/ssh/ssh_host_ecdsa_key -t ecdsa -C 'host' -N '' > /dev/null
yes | ssh-keygen -q -f /etc/ssh/ssh_host_ed25519_key -t ed25519 -C 'host' -N '' > /dev/null

echo "CWD: Starting sshd"
mkdir /run/sshd
/usr/sbin/sshd

echo "CWD: Exiting 020_start-sshd.sh"