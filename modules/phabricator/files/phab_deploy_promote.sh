#!/bin/sh
#
# Runs as a scap deploy check following the promote stage.
#

. /etc/phabricator/script-vars

if [ -z "$SCAP_REVS_DIR" ]; then
  echo '$SCAP_REVS_DIR is not defined.'
  echo 'Note: This script is only intended to run as a scap deploy check'
  exit 1
fi

systemctl stop phd
disable-puppet 'phabricator deployment'

# Transfer ownership to the deploy user for all files under the old rev
# directories to allow scap to clean up during the finalize stage.
#
# -type d: directories
# -mindepth 1: avoid including the starting dir
# -maxdepth 1: only top-level directories
# -not -path: exclude this rev path and scap's "current" rev

find "$SCAP_REVS_DIR" \
  -type d -maxdepth 1 -mindepth 1 \
  -not -path "$SCAP_REV_PATH" \
  -not -path "$SCAP_CURRENT_REV_DIR" \
  -exec sudo chown -R "$PHAB_DEPLOY_USER" '{}' \; \
  -exec sudo chmod -R u+w '{}' \;
