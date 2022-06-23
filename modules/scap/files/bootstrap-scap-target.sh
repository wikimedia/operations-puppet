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
DESTINATION_DIR="$2"

# "scap-install-staging" is an rsync module defined in class scap::master
/usr/bin/rsync --archive \
               --delay-updates --delete --delete-delay \
               --compress --new-compress \
               --exclude=*.swp --exclude=**/__pycache__ \
               "$DEPLOYMENT_SERVER::scap-install-staging/scap/" "$DESTINATION_DIR/scap/"

# Use symlink to make sure interpreter adds libs to sys.path
cd "$DESTINATION_DIR"
PYTHON_VERSION=$(scap/bin/python3 --version | cut -d' ' -f2 | cut -d. -f1-2)
if [ "$(ls -d scap/lib/python*)" != "scap/lib/python$PYTHON_VERSION" ]; then
    ln -s "$DESTINATION_DIR"/scap/lib/python* "scap/lib/python$PYTHON_VERSION"
fi
