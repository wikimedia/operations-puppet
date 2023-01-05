#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# * Lists objects in a swift container
# * Parses the z/x/y tile coords
# * Generates a tile invalidation event
# * Sends the event to eventgate
# 
#
# === Parameters
# swift_container: a warm container (i.e. the active datacentre's)
# eventgate_endpoint: eventgate's endpoint in the datacentre we are running in
# swift_credentials: path where swift's credetials and endpoint are stored
#

set -xe

swift_container=$1
eventgate_endpoint=$2
swift_credentials=$3

source $swift_credentials

swift -A "$ST_AUTH" -U "$ST_USER" -K "$ST_KEY" list "$swift_container" |
  grep -o -E "[0-9]+\/[0-9]+\/[0-9]+" |
  xargs -L 100 |
  xargs -I {} jq -c --arg hostname "$(hostname -f)" --arg tiles "{}" \
    '.meta.domain |= $hostname | .changes |= ($tiles | split(" ") | map({"tile": . , "state": "expired"}))' \
    /etc/imposm/event-template.json |
  xargs -I {} -d "\n" curl -X POST -sS -H 'Content-Type: application/json' -d '{}' "$eventgate_endpoint"
