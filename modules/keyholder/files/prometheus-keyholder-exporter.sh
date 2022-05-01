#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Script to generate Prometheus metrics for Keyholder

set -eu

export SSH_AUTH_SOCK="/run/keyholder/proxy.sock"

OUTFILE="${1:-/var/lib/prometheus/node.d/keyholder.prom}"
TMPOUTFILE="${OUTFILE}.$$"

cleanup() {
    rm -f "$TMPOUTFILE"
}
trap cleanup EXIT

fail() {
	echo "Error: $1"
	cat > "$TMPOUTFILE" << EOF
# HELP keyholder_success Whether Keyholder statistics could be scraped or not
# TYPE keyholder_success gauge
keyholder_success 0
EOF

	mv "$TMPOUTFILE" "$OUTFILE"

	exit 1
}

active_keys() {
	# Get a sorted list of all keys currently represented by the agent.
	ssh-add -l 2>/dev/null | cut -d' ' -f 2 | sort
}

[ -S "$SSH_AUTH_SOCK" ] || fail "Cannot connect to keyholder-proxy socket $SSH_AUTH_SOCK."
[ -r /etc/keyholder.d ] || fail "Missing permissions to list /etc/keyholder.d."
[ -w "$SSH_AUTH_SOCK" ] || fail "Missing permissions to communicate with the keyholder socket."

ACTIVE_KEYS=$(active_keys)

cat > "$TMPOUTFILE" << EOF
# HELP keyholder_success Whether Keyholder statistics could be scraped or not
# TYPE keyholder_success gauge
keyholder_success 1
# HELP keyholder_last_scrape Unix timestamp when Keyholder stats were last collected
# TYPE keyholder_last_scrape gauge
keyholder_last_scrape $(date +%s)
# HELP keyholder_armed Whether a particular key has been armed
# TYPE keyholder_armed gauge
EOF

for key in /etc/keyholder.d/*.pub; do
	armed=0

	fingerprint=$(ssh-keygen -l -f "$key" | cut -d' ' -f2 2>/dev/null)
	if [[ $ACTIVE_KEYS == *"$fingerprint"* ]]; then
		armed=1
	fi

	cat >> "$TMPOUTFILE" << EOF
keyholder_armed{key="$key"} $armed
EOF
done

mv "$TMPOUTFILE" "$OUTFILE"
