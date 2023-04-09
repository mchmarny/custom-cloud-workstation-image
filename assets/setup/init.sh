#!/bin/bash

# Do in here all the steps that are needed to setup 
# the workstation after the initial launch.

set -euo pipefail

# === START CONFIGURATION =============================================
GH_USER="example"
USER_EMAIL="user@domain.com"
# === END CONFIGURATION ===============================================


# === START GIT SETUP =====================================================
git config --global user.name $GH_USER
git config --global user.email $USER_EMAIL
git config --global core.editor nano

# Set up SSH keys
ssh-keygen -t ed25519 -C $USER_EMAIL
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
echo "Copy the key above and add it to your GitHub account"
cat ~/.ssh/id_ed25519.pub
read -p "Press enter to continue"
ssh -T git@github.com
# === END GIT SETUP =======================================================


