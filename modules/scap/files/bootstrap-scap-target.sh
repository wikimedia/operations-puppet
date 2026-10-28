#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
######################################
# This file is managed by puppet!
#  puppet:///modules/scap/bootstrap-scap-target.sh

# This script primes a host with a scap installation
######################################

set -eu -o pipefail

if (($# < 2)); then
    echo "Usage: $0 deployment_server destination_dir"
    exit 1
fi

DEPLOYMENT_SERVER="$1"
DESTINATION_DIR="${2}/"
INSTALL_USER="${USER:-scap}"
DISTRO=$(lsb_release -cs)

# scap install-world takes the same lock while it installs scap
exec 9>"${DESTINATION_DIR}install.lock"
flock 9
if [ -e "${DESTINATION_DIR}scap/bin/scap" ]; then
    exit 0
fi

# "scap-install-staging" is an rsync module defined in class scap::master
/usr/bin/rsync --archive \
               --delay-updates --delete --delete-delay \
               --compress --new-compress \
               --timeout=5 --contimeout=2 \
               "$DEPLOYMENT_SERVER::scap-install-staging/scap-wheels/$DISTRO" \
               "$DEPLOYMENT_SERVER::scap-install-staging/scap/bin/install_local_version.sh" \
               "$DESTINATION_DIR"

cd "$DESTINATION_DIR"

# Leave only most recent version and set things up for `install_local_version.sh`
LATEST_VERSION=$(find "$DISTRO" -mindepth 1 -maxdepth 1 -type d | sort --version-sort | tail -1)
for VERSION in "$DISTRO"/*; do
  if [ "$VERSION" != "$LATEST_VERSION" ]; then
    rm -rf "$VERSION"
  fi
done
mv "$LATEST_VERSION"/* "$DISTRO"
rmdir "$LATEST_VERSION"

./install_local_version.sh -u "$INSTALL_USER"
