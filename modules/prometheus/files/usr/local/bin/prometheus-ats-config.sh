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

max_connections_in="$(
    traffic_ctl config get proxy.config.net.max_connections_in \
        | awk '{print $2}'
)"

max_requests_in="$(
    traffic_ctl config get proxy.config.net.max_requests_in \
        | awk '{print $2}'
)"

cat <<EOF > "${OUTFILE}.$$"
# HELP ats_proxy_config_net_max_connections_in Total number of client requests that Traffic Server can handle simultaneously
# TYPE ats_proxy_config_net_max_connections_in gauge
ats_proxy_config_net_max_connections_in $max_connections_in
# HELP ats_proxy_config_net_max_requests_in Total number of concurrent requests or active client connections that the Traffic Server can handle simultaneously
# TYPE ats_proxy_config_net_max_requests_in gauge
ats_proxy_config_net_max_requests_in $max_requests_in
EOF
mv "${OUTFILE}.$$" "${OUTFILE}"
