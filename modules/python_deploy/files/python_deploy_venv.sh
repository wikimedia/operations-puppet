#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
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
VENV_DIR="${PROJECT_DIR}/venv-$(date "+%s")"
VENV_LINK="${PROJECT_DIR}/venv"
CACHE_DIR="${PROJECT_DIR}/cache/"
NEW_DIR="${PROJECT_DIR}/new"
OLD_DIR="${PROJECT_DIR}/old"
CUR_DIR="${PROJECT_DIR}/current"
DEPLOY_LINK="${PROJECT_DIR}/deploy"

# Create cache if missing
if [[ ! -d "${CACHE_DIR}" ]]; then
    git -C "${PROJECT_DIR}" clone --recursive "http://${DEPLOYMENT_SERVER}/${PROJECT}/deploy/.git" cache
fi

# Update cache
git -C "${CACHE_DIR}" pull --ff-only --recurse-submodules

# Clone from cache
echo "Deleting directory ${NEW_DIR}"
rm -rf "${NEW_DIR}"
git -C "${PROJECT_DIR}" clone --recursive --reference "${CACHE_DIR}" "${CACHE_DIR}" "${NEW_DIR}"

# Run make
echo "Running ${PROJECT}'s Makefile.deploy"
DEPLOY_PATH="${NEW_DIR}" VENV="${VENV_DIR}" make -C "${NEW_DIR}" -f Makefile.deploy deploy

# Switch new with current and link the new virtualenv
echo "Deleting directory ${OLD_DIR}"
rm -rf "${OLD_DIR}"
if [[ -d "${CUR_DIR}" ]]; then  # Breaks the symlink from deploy, usually not used
    mv -v "${CUR_DIR}" "${OLD_DIR}"
fi
if [[ -L "${VENV_LINK}" ]]; then
    OLD_VENV=$(readlink "${VENV_LINK}")
    rm -v "${VENV_LINK}"  # Deletes the symlink to the current virtualenv
fi
ln -s "${VENV_DIR}" "${VENV_LINK}"  # Set the symlink to the new virtualenv
mv -v "${NEW_DIR}" "${CUR_DIR}"
if [[ -L "${DEPLOY_LINK}" ]]; then
    rm -v "${DEPLOY_LINK}"
fi
ln -sv "${CUR_DIR}" "${DEPLOY_LINK}"  # Fixes the symlink from deploy
if [[ -n "${OLD_VENV}" ]]; then
    echo "Deleting directory ${OLD_VENV}"
    rm -rf "${OLD_VENV}"
fi
