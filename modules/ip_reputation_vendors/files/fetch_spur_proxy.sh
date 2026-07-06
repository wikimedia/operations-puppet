#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#

set -euo pipefail

OUTPUT="${1:?Usage: $0 <output_path>}"
TMPFILE="$(mktemp "$(dirname "$OUTPUT")/.spur_proxy.XXXXXX")"

cleanup() {
    rm -f "$TMPFILE"
}
trap cleanup EXIT

curl --get \
     "https://exports.spur.us/v1/feeds/anonymous-residential" \
     --data-urlencode "output=mmdb" \
     --data-urlencode "fields=network,callbackProxy" \
     -H "Token: $SPUR_TOKEN" \
     -f \
     -s \
     --show-error \
     -o "$TMPFILE"

mv -f "$TMPFILE" "$OUTPUT"

