#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u

okfile=${1:-}
shift

for url in "$@"; do
  db_status=$(curl --fail --silent --max-time 5 "${url}/status/v1/services/puppetdb-status" || true)
  state=$(echo $db_status | jq -rn 'inputs | .state')
  if [ "$state" == "running" ]; then
    touch $okfile
    exit 0
  fi
done

rm -f $okfile
