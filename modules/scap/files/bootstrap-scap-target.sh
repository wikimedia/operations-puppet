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

# "scap-install-staging" is an rsync module defined in class scap::master
/usr/bin/rsync --archive \
               --delay-updates --delete --delete-delay \
               --compress --new-compress \
               --timeout=5 --contimeout=2 \
               "$DEPLOYMENT_SERVER::scap-install-staging/scap-wheels/$(lsb_release -cs)" \
               "$DEPLOYMENT_SERVER::scap-install-staging/scap/bin/install_local_version.sh" \
               "$DESTINATION_DIR"

cd "$DESTINATION_DIR"
./install_local_version.sh -u "$INSTALL_USER"
