#!/bin/bash
#
# Simple script to allow to deploy a Python repository that requires a
# virtualenv in line with https://phabricator.wikimedia.org/T180023 to be used
# on Debian Bullseye that is Python3-only in our installation until Scap is
# ported to Python3.
#
# The workflow would be the same one of scap until the scap run, that is:
# updating the working copy on the deployment server, and then to run a dedicated
# cookbook sre.deploy.python-code that will perform the tasks currently handled
# by scap basically running git update-server-info on the deployment server and
# then running this script for each host in sequence.
# Any pre/post action should be taken care by the cookbook.

set -e

PATH="/usr/bin"
DEPLOYMENT_SERVER="deployment.eqiad.wmnet"
BASE_DIR="/srv/deployment"

if [[ -z "${1}" ]]; then
    echo "Usage: ${0} project-name"
    exit 1
fi

PROJECT="${1}"
PROJECT_DIR="${BASE_DIR}/${PROJECT}"

# Create cache if missing
if [[ ! -d "${PROJECT_DIR}/cache" ]]; then
    git -C "${PROJECT_DIR}" clone --recursive "http://${DEPLOYMENT_SERVER}/${PROJECT}/deploy/.git" cache
fi

# Update cache
git -C "${PROJECT_DIR}/cache" pull --recurse-submodules

# Clone from cache
echo "Deleting directories ${PROJECT_DIR}/new/ ${PROJECT_DIR}/venv-new/"
rm -rf "${PROJECT_DIR}/new/" "${PROJECT_DIR}/venv-new/"
git -C "${PROJECT_DIR}" clone --recursive --reference "${PROJECT_DIR}/cache/" "${PROJECT_DIR}/cache/" "${PROJECT_DIR}/new"

# Run make
echo "Running ${PROJECT}'s Makefile.deploy"
DEPLOY_PATH="${PROJECT_DIR}/new" VENV="${PROJECT_DIR}/venv-new" make -C "${PROJECT_DIR}/new" -f Makefile.deploy deploy

# Convert the venv to be relocatable to a new path
virtualenv --relocatable --python=python3 "${PROJECT_DIR}/venv-new"
# Fix path in activate scripts that are not handled by --relocatable
sed -i 's/venv-new/venv/' "${PROJECT_DIR}/venv-new/bin/activate"*

# Switch new with current
echo "Deleting directories ${PROJECT_DIR}/old/ ${PROJECT_DIR}/venv-old/"
rm -rf "${PROJECT_DIR}/old/" "${PROJECT_DIR}/venv-old/"
if [[ -d "${PROJECT_DIR}/current" ]]; then  # Breaks the symlink from deploy, usually not used
    mv -v "${PROJECT_DIR}/current/" "${PROJECT_DIR}/old/"
fi
if [[ -d "${PROJECT_DIR}/venv" ]]; then
    mv -v "${PROJECT_DIR}/venv/" "${PROJECT_DIR}/venv-old/"
fi
mv -v "${PROJECT_DIR}/new/" "${PROJECT_DIR}/current/"
mv -v "${PROJECT_DIR}/venv-new/" "${PROJECT_DIR}/venv/"
if [[ -L "${PROJECT_DIR}/deploy" ]]; then
    rm "${PROJECT_DIR}/deploy"
fi
ln -sv "${PROJECT_DIR}/current" "${PROJECT_DIR}/deploy"  # Fixes the symlink from deploy

