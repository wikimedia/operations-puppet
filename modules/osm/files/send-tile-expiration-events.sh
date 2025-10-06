#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -xe

osm_dir=$1
expire_dir=$2
minzoom=$3
maxzoom=$4
eventgate_endpoint=$5

# Read last expired tile timestamp
touch "$osm_dir"/last_expiration_event_timestamp
last_run_timestamp=$(cat "$osm_dir"/last_expiration_event_timestamp)

# Filter expired tile directories
expired_tile_dirs=()
for dir_name in "$expire_dir"/*; do
  dir_date=$(date -d "$(basename "$dir_name")" +%s)
  if [[ -z "$last_run_timestamp" ]]; then
    # first run
    expired_tile_dirs+=("$dir_name")
  else
    [[ $last_run_timestamp < $dir_date ]] && expired_tile_dirs+=("$dir_name")
  fi
done

if [ "${#expired_tile_dirs[@]}" -ne 0 ]; then
  DUMPFILE="/srv/tegola/swift_expiration_dump_$(date '+%Y%m%d-%H%M%S')"
  # Dumping millions of tile names from Swift may cause the tool to use a lot of
  # memory, and the is the risk of triggering the OOM.
  swift -A "$ST_AUTH" -U "$ST_USER" -K "$ST_KEY" list "$CACHE_CONTAINER" > "$DUMPFILE"
  # Deduplicate and send tile state change events (100 tiles per event)
  { find "${expired_tile_dirs[@]}" -type f -exec cat {} + |
      maps-deduped-tilelist "$minzoom" "$maxzoom" ;
      cat "$DUMPFILE" | grep -o -E "[0-9]+\/[0-9]+\/[0-9]+" ; } |
    sort | uniq -d |
    xargs --max-lines=100 |
    xargs -I {} jq -c --arg hostname "$(hostname -f)" --arg tiles "{}" \
      '.meta.domain |= $hostname | .changes |= ($tiles | split(" ") | map({"tile": . , "state": "expired"}))' \
      /etc/imposm/event-template.json |
    xargs -I {} -d "\n" curl -X POST -sS -H 'Content-Type: application/json' -d '{}' "$eventgate_endpoint"

  # Store current run timestamp as latest run
  date +%s >"$osm_dir"/last_expiration_event_timestamp
  rm "$DUMPFILE"
fi
