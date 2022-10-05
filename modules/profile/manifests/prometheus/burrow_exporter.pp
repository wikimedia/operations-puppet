# SPDX-License-Identifier: Apache-2.0
# Prometheus Burrow (Kafka Consumer lag monitor) metrics exporter.
#
# === Parameters
#
# [*$burrow_addr*]
#  The ip:port combination of the Burrow instance to poll data from.
#
# [*$hostname*]
#  The host to listen on. The host/port combination will also be used to generate Prometheus
#  targets.
#
# [*$port*]
#  The port to listen on.
#
# [*api_version*]
#  Burrow API version to use.
#  Default: 3
#
define profile::prometheus::burrow_exporter(
    $burrow_addr = 'localhost:8000',
    $hostname = '0.0.0.0',
    $port = '9000',
    $api_version = 3,
) {
    prometheus::burrow_exporter { $title:
        burrow_addr  => $burrow_addr,
        metrics_addr => "${hostname}:${port}",
        interval     => 30,
        api_version  => 3,
    }
}
