# SPDX-License-Identifier: Apache-2.0
# == Define: profile::prometheus::elasticsearch_exporter
#
# Configures a prometheus elasticsearch exporter and sets up appropriate
# firewall rules for collection from the exporter.
#
# == Parameters
#
# [*prometheus_port*]
#   Port used by the exporter for the listen socket
# [*elasticsearch_port*]
#   Port to monitor elasticsearch on
#
define profile::prometheus::elasticsearch_exporter(
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
) {
    prometheus::elasticsearch_exporter { "localhost:${elasticsearch_port}":
        elasticsearch_port => $elasticsearch_port,
        prometheus_port    => $prometheus_port,
    }
}
