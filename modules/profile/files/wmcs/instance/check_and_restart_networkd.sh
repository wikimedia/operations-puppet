#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# If networkd is running but the network isn't working, restart networkd.
#
# record a boolean prometheus metric so we can detect when this happens.
#
# Test cribbed from https://github.com/systemd/systemd/issues/25441
#
# Should only be needed on Bookworm; this particular network failure is
#  fixed on Trixie.
PROMFILE="$(realpath "${1:-/var/lib/prometheus/node.d/node_network_last_restart.prom}")"
TMPOUTFILE="${PROMFILE}.tmp"

SUCCESS=$(cat << EOF
# HELP node_network_last_restart
# TYPE node_network_last_restart gauge
node_network_last_restart 0
EOF
)

FAILURE=$(cat << EOF
# HELP node_network_last_restart
# TYPE node_network_last_restart gauge
node_network_last_restart $EPOCHSECONDS
EOF
)

if  systemctl is-active systemd-networkd.service > /dev/null && ! ip route list | grep -q .; then
    logger "$(date) systemd-networkd is running but the routes are broken. Restarting systemd-networkd.service"
    echo "$FAILURE" > $PROMFILE
    systemctl restart systemd-networkd.service
else
    if [ ! -f $PROMFILE ]; then
        echo "$SUCCESS" > $PROMFILE
        chmod a+r "$PROMFILE"
    else
        # Prometheus gets itchy if a metric file is too old
        touch "$PROMFILE"
    fi
fi
