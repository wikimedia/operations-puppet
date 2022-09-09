#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Usage: prometheus-ats-config [OUTFILE]
#
# Parse and export select ATS configurations for Prometheus to consume. Useful
# for enabling monitoring to compare current values with maximums.

set -o errexit
set -o nounset
set -o pipefail

OUTFILE="${1:-/var/lib/prometheus/node.d/ats_config.prom}"
# This config option differs between ATS 8 and 9
ats_version="$(traffic_ctl --version | awk -F" - " '{print $3}')"
if [[ ${ats_version:0:1} == "8" ]]; then
    max_requests_name="proxy.config.net.max_connections_active_in"
else
    max_requests_name="proxy.config.net.max_requests_in"
fi

max_connections_in="$(
    traffic_ctl config get proxy.config.net.max_connections_in \
        | awk '{print $2}'
)"

max_requests_in="$(
    traffic_ctl config get $max_requests_name \
        | awk '{print $2}'
)"

cat <<EOF > "${OUTFILE}.$$"
# HELP ats_proxy_config_net_max_connections_in Total number of client requests that Traffic Server can handle simultaneously
# TYPE ats_proxy_config_net_max_connections_in gauge
ats_proxy_config_net_max_connections_in "$max_connections_in"
# HELP $max_requests_name Total number of concurrent requests or active client connections that the Traffic Server can handle simultaneously
# TYPE $max_requests_name gauge
$max_requests_name "$max_requests_in"
EOF
mv "${OUTFILE}.$$" "${OUTFILE}"
