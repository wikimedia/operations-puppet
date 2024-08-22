#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -eu
set -o pipefail

outfile="$(realpath "${1:-/var/lib/prometheus/node.d/nft_throttling_denylists.prom}")"
tmpoutfile="${outfile}.$$"
function cleanup {
    rm -f "$tmpoutfile"
}
trap cleanup EXIT

if [ "$(id -u)"  != "0" ] ; then
    echo "root required!" >&2
    exit 1
fi

nftables_throttling_denylist_v4_length=$(nft --json list set inet filter DENYLIST | jq -cr '.nftables[1].set.elem[]?'  | wc -l)
nftables_throttling_denylist_v6_length=$(nft --json list set inet filter DENYLIST_V6 | jq -cr '.nftables[1].set.elem[]?'  | wc -l)

cat <<EOF >"$tmpoutfile"
# HELP nftables_throttling_denylist_v4_length nft throttling denylist IPv4
# TYPE nftables_throttling_denylist_v4_length gauge
nftables_throttling_denylist_v4_length $nftables_throttling_denylist_v4_length
# HELP nftables_throttling_denylist_v6_length nft throttling denylist IPv6
# TYPE nftables_throttling_denylist_v6_length gauge
nftables_throttling_denylist_v6_length nftables_throttling_denylist_v6_length
EOF

mv "$tmpoutfile" "$outfile"
chmod a+r "$outfile"
