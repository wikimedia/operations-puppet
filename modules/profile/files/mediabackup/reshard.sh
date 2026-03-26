#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail


dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
    shift
fi

source_host=${1?param missing - source_host}
target_host=${2?param missing - target_host}
wiki=${3?param missing - wiki}
start_shard=${4?param missing - start_shard (e.g. 0a0)}
end_shard=${5?param missing - end_shard (e.g. 1ff)}

# Validate input format (exactly 3 hex chars)
if [[ ! "$start_shard" =~ ^[0-9a-fA-F]{3}$ ]]; then
    echo "Invalid start_shard: $start_shard (must be 3 hex chars)"
    exit 1
fi

if [[ ! "$end_shard" =~ ^[0-9a-fA-F]{3}$ ]]; then
    echo "Invalid end_shard: $end_shard (must be 3 hex chars)"
    exit 1
fi

# Normalize to lowercase
start_shard=$(echo "$start_shard" | tr 'A-F' 'a-f')
end_shard=$(echo "$end_shard" | tr 'A-F' 'a-f')

# Convert hex -> decimal
start_dec=$((16#$start_shard))
end_dec=$((16#$end_shard))

if (( start_dec > end_dec )); then
    echo "start_shard must be <= end_shard"
    exit 1
fi

echo "Copying shards from $start_shard to $end_shard..."

for ((i=start_dec; i<=end_dec; i++)); do
    shard=$(printf "%03x" "$i")

    echo "Attempting to copy $source_host:mediabackups/$wiki/$shard/ into $target_host:mediabackups/$wiki/$shard/ ..."
    cmd=(rclone copy -P \
        "$source_host:mediabackups/$wiki/$shard/" \
        "$target_host:mediabackups/$wiki/$shard/")

    if $dry_run; then
        echo "[DRY-RUN] ${cmd[*]}"
    else
        "${cmd[@]}"
    fi

    echo "Done $shard"
done

echo "All rclone executions ended successfully."
