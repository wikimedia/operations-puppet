#!/usr/bin/env bash
set -euxo pipefail

for f in /var/run/elasticsearch/*.pid; do
  /usr/bin/elasticsearch-madvise "$(cat "$f")"
done

echo "Done"
