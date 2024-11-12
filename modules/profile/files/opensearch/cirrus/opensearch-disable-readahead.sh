#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euxo pipefail

for f in /run/opensearch*/*.pid; do
  /usr/bin/elasticsearch-madvise "$(cat "$f")"
done

echo "Done"
