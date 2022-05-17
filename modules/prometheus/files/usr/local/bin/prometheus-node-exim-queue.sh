#!/bin/bash

set -eu
set -o pipefail

outfile="$(realpath "${1:-/var/lib/prometheus/node.d/exim_queue.prom}")"
tmpoutfile="${outfile}.$$"
function cleanup {
    rm -f "$tmpoutfile"
}
trap cleanup EXIT

if [ "$(id -u)"  != "0" ] ; then
    echo "root required!" >&2
    exit 1
fi

# 'grep -c' returns 0 on no matches and exits 1, thus "|| true"
queue_length=$(mailq | grep -c '<' || true)
frozen_length=$(mailq | grep -c '<.* \*\*\* frozen \*\*\*' || true)

cat <<EOF >"$tmpoutfile"
# HELP exim_queue_length Exim queue length
# TYPE exim_queue_length gauge
exim_queue_length $queue_length
# HELP exim_queue_length_frozen Exim queue length for frozen messages
# TYPE exim_queue_length_frozen gauge
exim_queue_length_frozen $frozen_length
EOF

mv "$tmpoutfile" "$outfile"
chmod a+r "$outfile"
