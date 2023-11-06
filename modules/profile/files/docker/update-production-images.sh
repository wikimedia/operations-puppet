#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -e
REPO=/usr/src/imageupdatebot/production-images
# Ensure we're using the correct ssh key for git
export GIT_SSH_COMMAND="ssh -i /usr/src/imageupdatebot/.ssh.key"

function git_update() {
    pushd "$REPO"
    # first ensure that the git repo is set up correctly
    git config --local user.name Imageupdatebot
    git config --local user.email root@wikimedia.org
    git pull --ff-only
    popd
}

git_update
pushd "$REPO"
# Run the weekly update for the main images
for imgdir in images istio cert-manager;
    do
    "${REPO}/weekly-update.sh" "$imgdir"
done
# Now rebuild. Use --info to send logs to stdout to be captured by journald
IMAGE_BASEDIR=$REPO /usr/local/bin/build-production-images --info
popd